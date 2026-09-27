# 買い物リスト機能 実装指示書

この文書は、買い物リスト機能を実装するための指示書です。仕様はユーザーと相談して確定済みです。
**CLAUDE.md のルール(Docker でのコマンド実行、Devise、コーディング方針)に従って実装してください。**

## 目的

「買う物を忘れないためのリスト」を、世帯の2人で共有する。

## 確定した仕様

| 項目 | 内容 |
| --- | --- |
| リストの数 | 1世帯に1つ |
| アイテムの項目 | 商品名・個数・メモ・カテゴリ・必須/任意・追加した人・チェック(購入済み) |
| 追加した人 | 表示する(「○○さんが追加」)。編集しても最初に追加した人のまま |
| 買う人 | 指定しない |
| 必須/任意 | 初期値は **必須** |
| 個数 | **整数**(1以上、初期値1)。「2パック」「500g」などの単位はメモに書く |
| チェック | 買った物にチェックを入れる。チェックしても消えず、**取り消し線 + グレー**で表示する。チェックは外せる |
| まとめて削除 | 「チェック済みを削除」ボタンで、チェック済みの物をまとめて削除する。**履歴は残さない** |
| 個別の削除 | 編集画面の「削除」ボタンで削除する(登録ミス用) |
| 重複 | 同じリストに同じ商品名は登録できない。前後の空白を取り除いて**完全一致**で判定する(全角/半角、ひらがな/カタカナはそろえない) |
| 重複時のメッセージ | 未チェックの物と重複 →「はすでにリストにあります」<br>チェック済みの物と重複 →「「牛乳」はチェック済みです。チェックを外してください」 |
| カテゴリ | 定数で固定(画面から追加・変更はできない)。家計の `categories` テーブルとは**連携しない** |
| 家計との関係 | 支出とは連携しない |
| 他のメンバーの操作の反映 | ページを再読み込みしたときに反映する(Turbo Stream などは使わない) |
| 1人の世帯 | パートナーの参加前でも使える |

### カテゴリ(この順番で見出しを並べる)

スーパーの売り場を回る順番に合わせている。

1. 野菜・果物
2. 肉・魚
3. 乳製品・卵
4. 米・パン
5. 調味料
6. 日用品
7. その他

### 並び順

- カテゴリの見出しは上の定数の順番。**アイテムが0件のカテゴリは見出しを出さない**
- 同じカテゴリの中では、次の順に並べる
  1. 未チェック → チェック済み(チェック済みはカテゴリ内の一番下に移る)
  2. 必須 → 任意
  3. 追加が古い順

## データベース

### shopping_lists

| カラム | 型 | 制約 |
| --- | --- | --- |
| household_id | references | null: false、外部キー、**ユニークインデックス** |

### shopping_list_items

| カラム | 型 | 制約 |
| --- | --- | --- |
| shopping_list_id | references | null: false、外部キー |
| added_by_id | references(users) | null: false、外部キー(`foreign_key: { to_table: :users }`) |
| name | string | null: false |
| quantity | integer | null: false、default: 1 |
| memo | string | |
| category | string | null: false |
| is_essential | boolean | null: false、default: true |
| purchased | boolean | null: false、default: false |

- `[:shopping_list_id, :name]` にユニークインデックス

## モデル

### Household(既存)

- `has_one :shopping_list, dependent: :destroy` を追加
- 既存の世帯にはリストがないため、**初めて使うときに作る**メソッドを追加する(rake タスクやデータ移行は不要)
  - 例: `def shopping_list! = shopping_list || create_shopping_list!`
  - 2人が同時に初めて開いた場合はユニークインデックス違反(`ActiveRecord::RecordNotUnique`)になりうるので、rescue して `reload_shopping_list` で取り直す

### ShoppingList(新規)

- `belongs_to :household`
- `has_many :items, class_name: "ShoppingListItem", dependent: :destroy`
- `clear_purchased!` … チェック済みのアイテムをまとめて削除する

### ShoppingListItem(新規)

- `CATEGORIES` 定数(上の7個、順番どおり)
- `belongs_to :shopping_list`
- `belongs_to :added_by, class_name: "User"`
- バリデーション
  - name: 必須、最大30文字
  - quantity: 必須、整数、1以上
  - memo: 最大100文字
  - category: 必須、`CATEGORIES` に含まれる
  - is_essential / purchased: true か false(`inclusion: { in: [ true, false ] }`)
  - 重複: 同じリストに同じ名前がないか、自作のバリデーションで確認する。相手がチェック済みなら「チェックを外してください」のメッセージにする(上の表を参照)
  - added_by: 世帯のメンバーであること(`Expense#payer_must_be_household_member` と同じ書き方)
- name は保存前に前後の空白を取り除く(`normalizes :name, with: ->(name) { name.strip }`)
- `toggle_purchased!` … チェックを入れる・外す
- 並び順のスコープ(例: `scope :ordered, -> { order(:purchased, is_essential: :desc, created_at: :asc) }`)

## ルーティング

```ruby
resources :shopping_list_items, only: [ :index, :create, :edit, :update, :destroy ] do
  member     { patch  :toggle_purchased } # チェックを入れる・外す
  collection { delete :clear_purchased }  # チェック済みをまとめて削除
end
```

## コントローラ(ShoppingListItemsController)

- `before_action :require_household`(既存の ApplicationController のメソッド)
- リストは `current_user.household.shopping_list!` で取得する
- アイテムは `@shopping_list.items.find(params[:id])` で探す(他の世帯のアイテムは 404 になる)
- `create` … `added_by: current_user` を付けて作る。失敗したら一覧(index)を 422 で再表示する
- `update` … 変更できるのは name / quantity / memo / category / is_essential(purchased と added_by は変更させない)
- `toggle_purchased` / `clear_purchased` / `destroy` … 一覧へ `status: :see_other` でリダイレクトする
- ロジックはモデルに置き、コントローラは薄く保つ

## 画面

### 一覧(index)

- 上部: 追加フォーム(商品名・個数・カテゴリ・必須/任意・メモ)
- 下部: カテゴリごとの見出しと、アイテムの一覧
- 各アイテムに表示するもの
  - チェックボックス(押すと `toggle_purchased`)。JavaScript なしで動くよう、`button_to` をチェックボックス風の見た目にする
  - 商品名、個数(例: ×2)、メモ
  - 「必須」「任意」のラベル(色を変える)
  - 「○○さんが追加」
  - 編集へのリンク
  - チェック済みは取り消し線 + グレーで表示する
- 「チェック済みを削除」ボタン … チェック済みが1件以上あるときだけ表示する。`turbo_confirm` で確認ダイアログを出す
- アイテムが0件のときは「買う物はありません」と表示する

### 編集(edit)

- 追加フォームと同じ項目(フォームはパーシャルにして共用する)
- 「削除」ボタン(`turbo_confirm` で確認する)

### ナビゲーション

- **スマホの下部タブバー**(`app/views/shared/_bottom_nav.html.erb`): 「カテゴリ」を「買い物」(アイコン `shopping-cart`、`shopping_list_items_path`)に置き換える
- **スマホのヘッダーメニュー**(`app/views/shared/_header.erb` の `<details>` 内): 「カテゴリ」へのリンク(アイコン `tags`)を追加する
- **PC のヘッダー**: 「買い物」へのリンクを追加する
- 既存のテスト `test/controllers/home_controller_test.rb`(下部タブバー・ヘッダーのテスト)を上の変更に合わせて修正する

### 日本語化

- `config/locales/ja.yml` に `shopping_list_item` の属性名(商品名・個数・メモ・カテゴリ・必須/任意)を追加する
- 必要なエラーメッセージ(`greater_than`、`too_long`、`inclusion`、`taken` など)が ja.yml にない場合は追加する

## テスト

既存のテスト(`test/models/category_test.rb`、`test/controllers/categories_controller_test.rb`)の書き方に合わせる。

- フィクスチャ: `shopping_lists.yml`(households(:one) と (:two) に1つずつ)、`shopping_list_items.yml`
- モデルテスト
  - 正しい値なら有効 / 各バリデーション
  - 同じ名前は登録できない(前後に空白があっても重複になる)
  - チェック済みの物と重複したときのメッセージ
  - 別のリストなら同じ名前を登録できる
  - `toggle_purchased!`、`clear_purchased!`(未チェックの物は残る)
  - `Household#shopping_list!` がリストを作る / 2回呼んでも1つのまま
- コントローラテスト
  - 一覧の表示、カテゴリの見出し、必須/任意のラベル、追加した人の名前
  - 追加(`added_by` が自分になる)、追加の失敗(422)
  - 編集、削除、チェックの切り替え、チェック済みをまとめて削除
  - 他の世帯のアイテムは編集・変更・削除・チェックできない(404)
  - 世帯に未所属なら世帯作成画面へ、未ログインならログイン画面へ移動する

```bash
docker compose exec web bin/rails test
docker compose exec web bin/rubocop
```

## ドキュメントの更新

- `docs/app_overview.md` … 機能一覧・仕様の詳細・テーブル設計に買い物リストを追記する
- `CLAUDE.md` の「ドメインルール」… 買い物リストの節を追加する
- `docs/post_mvp_plan.md` … 今後の拡張として、次の3つを追記する
  - リアルタイム更新(Turbo Streams / Action Cable)
  - 通知(パートナーがアイテムを追加したとき など)
  - 支出登録との連携(`clear_purchased` のときに支出を登録する形を想定)

## 実装の進め方

1段階ずつ、テストが通ることを確認しながら進める。

1. マイグレーションとモデル(+ モデルテスト)
2. ルーティング・コントローラ・一覧/追加(+ コントローラテスト)
3. 編集・削除
4. チェックの切り替えと、チェック済みをまとめて削除
5. ナビゲーションの変更(+ home_controller_test の修正)
6. ドキュメントの更新

## やらないこと(今回の範囲外)

- 買う人の指定
- 購入履歴
- 支出・家計カテゴリとの連携
- リアルタイム更新、通知
- 画面からのカテゴリの追加・変更
