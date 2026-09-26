import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["source"];

  async copy(event) {
    const text = this.sourceTarget.textContent.trim();
    // 招待コードを取得

    const button = event.currentTarget;
    // HTML側のbutton要素を取得

    try {
      if (!navigator.clipboard || !window.isSecureContext) {
        throw new Error("この環境ではクリップボードにコピーできません。");
      }

      await navigator.clipboard.writeText(text);
      this.#showCopied(button);
    } catch (error) {
      console.error(error);
      window.prompt("招待コードをコピーしてください", text);
    }
  }

  // ボタンのラベルを一時的に「コピーしました」に差し替える
  #showCopied(button) {
    if (!button) return;

    const original = button.innerHTML;
    button.innerHTML = "Copied!!";
    button.disabled = true;

    setTimeout(() => {
      button.innerHTML = original;
      button.disabled = false;
    }, 1000);
  }
}