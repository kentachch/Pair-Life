#!/usr/bin/env bash
# Render でデプロイするときに実行するビルドの手順(render.yaml の buildCommand から呼ばれる)
# 途中のコマンドが1つでも失敗したら、そこで止める(失敗したままデプロイされないようにする)
set -o errexit

# Gem をインストールする
bundle install

# CSS(Tailwind)や JavaScript を本番用にまとめる
bin/rails assets:precompile
bin/rails assets:clean

# DB のテーブルを最新の状態にする
# 無料プランでは「デプロイ前に実行するコマンド」が使えないため、ビルドの中で実行する
bin/rails db:migrate
