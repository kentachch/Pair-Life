# myapp

Rails製のオリジナルアプリです。開発環境はDocker上で動作します。

## 動作環境

| 項目 | バージョン |
| --- | --- |
| Ruby | 3.4.10 |
| Rails | 8.1.3.1 |
| PostgreSQL | 17 |

## 事前準備

以下がインストールされていることを確認してください。

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Git

```bash
docker -v
docker compose version
git -v
```

## 環境構築手順

### 1. リポジトリをクローン

```bash
git clone <リポジトリのURL>
cd myapp
```

### 2. Dockerイメージをビルド

```bash
docker compose build
```

### 3. コンテナを起動

```bash
docker compose up -d
```

### 4. データベースを作成

```bash
docker compose exec web bin/rails db:prepare
```

### 5. 動作確認

ブラウザで以下にアクセスし、画面が表示されれば完了です。

http://localhost:3000

## よく使うコマンド

### コンテナ操作

```bash
# 起動
docker compose up -d

# 停止
docker compose down

# 再起動
docker compose restart web

# 起動状態の確認
docker compose ps

# ログの確認
docker compose logs -f web

# コンテナの中に入る
docker compose exec web bash
```

### Rails操作

```bash
# Railsコンソール
docker compose exec web bin/rails console

# マイグレーション実行
docker compose exec web bin/rails db:migrate

# マイグレーションを1つ戻す
docker compose exec web bin/rails db:rollback

# ルーティング確認
docker compose exec web bin/rails routes

# scaffold作成(例)
docker compose exec web bin/rails g scaffold Post title:string body:text
```

### Gemの追加

`Gemfile` を編集した後、以下を実行します。

```bash
docker compose exec web bundle install
docker compose restart web
```

## トラブルシューティング

### ポート3000が使用中と表示される

他のアプリが3000番ポートを使用しています。そのアプリを停止するか、`compose.yaml` の `ports` を `"3001:3000"` に変更し、http://localhost:3001 にアクセスしてください。

### 「A server is already running」と表示される

```bash
rm -f tmp/pids/server.pid
docker compose restart web
```

### データベースに接続できない

`db` コンテナが起動しているか確認してください。

```bash
docker compose ps
```

### 環境を完全にリセットしたい

⚠️ データベースのデータもすべて削除されます。

```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
docker compose exec web bin/rails db:prepare
```

## ファイル構成(Docker関連)

| ファイル | 役割 |
| --- | --- |
| `Dockerfile.dev` | 開発用のDockerイメージ定義 |
| `compose.yaml` | 開発用コンテナ(web / db)の構成 |
| `Dockerfile` | 本番用(Railsが自動生成) |# rails-app
