import { Controller } from "@hotwired/stimulus"
import "chart.js"

export default class extends Controller {
  static values = { url: String }
  static targets = ["canvas", "empty"]

  async connect() {
    // connect：そのコントローラがHTMLに接続されたときに自動的に実行される。
    const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
    // this.urlValueで、data-category-chart-url-valueの値を取得。
    if (!response.ok) return

    const data = await response.json()

    // 支出がない月は、グラフの代わりにメッセージを表示する
    if (data.categories.length === 0) {
      this.emptyTarget.hidden = false
      this.canvasTarget.hidden = true
      return
    }

    // ③ JSON を Chart.js の形(ラベルの配列と数値の配列)に変換してグラフを描く
    this.chart = new window.Chart(this.canvasTarget, {
      type: "pie", // 円グラフ
      data: {
        labels: data.categories.map((category) => category.name),
        datasets: [{ data: data.categories.map((category) => category.amount) }]
      },
      options: {
        plugins: {
          legend: { position: "bottom" },
          tooltip: {
            callbacks: {
              // ツールチップを「食費: ¥45,800」の形にする
              label: (context) => `${context.label}: ¥${context.parsed.toLocaleString()}`
            }
          }
        }
      }
    })
  }

  // 画面を離れるときに呼ばれる。グラフを片付けて、戻ったときに二重に描かれるのを防ぐ
  disconnect() {
    this.chart?.destroy()
  }
}
