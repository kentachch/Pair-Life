# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Chart.js は `bin/importmap pin chart.js` だと一部のファイルがダウンロードされず動かないため、
# 1ファイルにまとまった UMD 版(dist/chart.umd.js)を vendor/javascript に置いて使う
# 取得元: https://cdn.jsdelivr.net/npm/chart.js@4.5.1/dist/chart.umd.js
pin "chart.js", to: "chart.umd.js" # @4.5.1
