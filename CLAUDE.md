# CLAUDE.md

このファイルは Claude Code がこのリポジトリで作業する際の前提を記載したものです。

## プロジェクト概要

2人暮らし向けの家計管理アプリ「共同家計管理アプリ」です。支出を登録すると月ごとに自動集計し、負担割合(初期値 50-50)に応じて「誰が誰にいくら支払うか」を計算します。

詳細な仕様は以下を参照してください。

- `docs/app_overview.md` … アプリ概要・テーブル設計・確定仕様
- `docs/post_mvp_plan.md` … MVP後の開発計画

## 開発環境

| 項目 | バージョン |
| --- | --- |
| Ruby | 3.4.10 |
| Rails | 8.1.3.1 |
| PostgreSQL | 17 |
| 認証 | Devise |

開発環境は Docker で構築しています。**ホスト側に Ruby / Rails はインストールされていません。**

### コマンド実行のルール

Rails 関連のコマンドは必ず `docker compose exec web` を付けて実行してください。

```bash
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails test
docker compose exec web bundle install
```

ホスト側で `bin/rails` や `bundle` を直接実行しないでください。

### 主なファイル

- `Dockerfile.dev` … 開発用のイメージ定義
- `compose.yaml` … 開発用コンテナ(web / db)の構成
- `Dockerfile` … 本番用(Rails が自動生成したもの)

## 認証について

**認証には Devise を使用します。** Rails 8 標準の認証ジェネレータ(`bin/rails g authentication`)は使用しません。

既に Rails 8 標準認証のコード(`sessions` テーブル、`Current.user`、`Authentication` concern など)が生成されている場合は、削除して Devise の構成に置き換えてください。置き換える前に、削除対象のファイルを一覧にして確認を取ってください。

### 導入手順

```bash
docker compose exec web bundle add devise
docker compose exec web bin/rails g devise:install
docker compose exec web bin/rails g devise User
docker compose exec web bin/rails db:migrate
```

- `bin/rails g devise User` で生成されたマイグレーションに、`db:migrate` の前に `t.string :name, null: false` を追加する
- `config/environments/development.rb` に `config.action_mailer.default_url_options = { host: "localhost", port: 3000 }` を設定する
- 画面をカスタマイズする場合は `bin/rails g devise:views` でビューを生成する

### MVP で有効にするモジュール

`database_authenticatable`、`registerable`、`recoverable`、`rememberable`、`validatable`

- メール確認(`confirmable`)などは MVP では使用しない
- 将来の Google / LINE ログインは `omniauthable` と `omniauth` 系の Gem で追加する予定

### 実装上のルール

- ログイン必須の画面は、コントローラで `before_action :authenticate_user!` を使う
- ログイン中のユーザーは `current_user` で取得する(`Current.user` は使わない)
- 新規登録時に `name` を受け取るため、`ApplicationController` の `configure_permitted_parameters` で `name` を許可する
- users テーブルのメールアドレスのカラム名は `email`(`email_address` ではない)

## ドメインルール(重要)

実装時は以下のルールを必ず守ってください。仕様の背景は `docs/app_overview.md` にあります。

### 世帯(Household)

- 1つの世帯に所属できるメンバーは **最大2人**
- 1人のユーザーが所属できる世帯は **1つのみ**(`household_members.user_id` はユニーク)
- 2人目は、世帯作成時に発行される招待コードを入力して参加する
- 招待コードは2人そろった時点で無効になる
- パートナーの参加前(1人の状態)でも支出は登録できる。精算画面は2人そろってから表示する
- 世帯からの退出・アカウント削除は MVP では実装しない(Devise の登録削除機能も画面に出さない)

### 支出(Expense)

- `payer_id` は「誰が払ったか」を示し、`users` テーブルを参照する(`belongs_to :payer, class_name: "User"`)
- 同じ世帯のメンバーであれば、相手が登録した支出も編集・削除できる
- 折半対象の支出のみを扱う(個人的な支出の概念は持たない)
- **精算済みの月の支出は、追加・編集・削除のいずれも不可**

### カテゴリ(Category)

- 世帯ごとに管理する
- 世帯作成時に「家賃 / 食費 / 日用品 / 光熱費 / その他」を自動作成する
- 初期カテゴリも含め、追加・名前の変更・削除ができる
- 支出が登録されているカテゴリは削除できない(`dependent: :restrict_with_error`)

### 精算(Settlement)

- 集計はカレンダー通りの月単位(1日〜月末)
- **対象月が終わってから**精算できる(当月の精算は不可)
- **端数は切り捨て**
- 精算額が 0 円の月も記録できるよう、`from_user` / `to_user` は `optional: true`
- 精算はどちらのメンバーでも取り消せる。取り消すとその月の支出が再び編集可能になる
- 精算済みかどうかの判定は「その月の `settlements` レコードが存在するか」で行う
- `settlements` は `household_id` と `target_month` の組み合わせにユニークインデックスを付ける(1世帯1か月につき1件)
- `target_month` には対象月の1日(例: 2026-09-01)を保存する

### 負担割合

- `household_members.burden_ratio` で保持(初期値 50)
- MVP では 50-50 固定だが、精算ロジックは割合に対応した実装にしておく
- 割合の計算では小数の誤差を避けるため有理数(`100r`)を使う

## 実装の進め方

以下の順に、1段階ずつ動作確認しながら進めます。

1. 認証(Devise の導入、`name` を含む新規登録・ログイン・ログアウト)
2. 世帯の作成と招待コードによる参加
3. カテゴリの管理
4. 支出の登録・一覧・編集・削除
5. 月別集計
6. 精算と取り消し

## コーディング方針

- モデルにビジネスロジックを置き、コントローラは薄く保つ
- 金額は整数(円)で扱う。小数は使わない
- 権限チェックは「操作対象が自分の世帯のものか」を基準に行う
- 初学者が読んで理解できるコードを優先する。過度な抽象化は避ける
- 実装の意図がわかりにくい箇所には、日本語でコメントを添える
- 大きな変更を加える前に、方針を説明して確認を取る