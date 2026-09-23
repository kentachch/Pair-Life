import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["source"];

  async copy(event) {
    const text = this.sourceTarget.textContent.trim();
    // 中に入っている文字列を取得

    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text);
        // クリップボードにコピーできる
      } else {
        this.#copyByExecCommand(text);
      }
      this.#showCopied(event.currentTarget);
    } catch (error) {
      console.error(error);
      // コピーできなかったときは手動で選択してもらう
      window.prompt("招待コードをコピーしてください", text);
    }
  }

  // 画面外に置いた textarea を選択してコピーする古い方式
  #copyByExecCommand(text) {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    document.body.removeChild(textarea);
    if (!copied) throw new Error("execCommand によるコピーに失敗しました");
  }

  // ボタンのラベルを一時的に「コピーしました」に差し替える
  #showCopied(button) {
    if (!button) return;

    const original = button.innerHTML;
    button.innerHTML = "コピーしました";
    button.disabled = true;

    setTimeout(() => {
      button.innerHTML = original;
      button.disabled = false;
    }, 1000);
  }
}
