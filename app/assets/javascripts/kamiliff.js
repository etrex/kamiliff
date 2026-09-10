/* Kamiliff 1.0 has no automatic form interception or route-as-chat execution.
 * Initialize the LIFF SDK in your host page/Stimulus controller. Submit forms
 * through ordinary Rails routes with CSRF and server-side authorization. */
window.Kamiliff = Object.freeze({
  async sendText(text, { close = false } = {}) {
    await window.liff.sendMessages([{ type: "text", text: String(text) }]);
    if (close) window.liff.closeWindow();
  }
});
