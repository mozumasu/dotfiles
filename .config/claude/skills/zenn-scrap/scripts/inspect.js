// zenn スクラップの現在の状態を返す。操作前・操作後に実行する。
// プレースホルダ: __URL_JSON__ = 対象スクラップの URL (JSON 文字列。例: "https://zenn.dev/user/scraps/xxxx")
async (page) => {
  const url = __URL_JSON__;
  return await page.evaluate((url) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const body = (document.querySelector("main") || document.body).innerText;
    // スレッドブロック = 「返信を追加」ボタンをちょうど 1 個含む最小の祖先。
    // innerText は「ユーザー名 / 日時 / 本文 1 行目 / …」の順なので lines[2] が見出し (レンダリング後のテキスト)
    const replyBtns = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加");
    const threads = [];
    for (const btn of replyBtns) {
      let el = btn.parentElement, block = null;
      for (let k = 0; k < 20 && el; k++) {
        const n = Array.from(el.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加").length;
        const edits = el.querySelectorAll('button[aria-label="コメントを編集する"]').length;
        if (n === 1 && edits >= 1) { block = el; }
        if (n > 1) break;
        el = el.parentElement;
      }
      if (!block) continue;
      const lines = block.innerText.split("\n").map((s) => s.trim()).filter(Boolean);
      const edits = block.querySelectorAll('button[aria-label="コメントを編集する"]').length;
      threads.push({ heading: lines[2] || "(本文なし)", replies: Math.max(0, edits - 1), chars: block.innerText.length });
    }
    const editorsOpen = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    return {
      ok: true,
      url: location.href,
      hidden: (body.match(/Hidden comment/g) || []).length,
      threads,
      editorsOpen,
      // 末尾の新規スレッド用エディタ以外が開いていたら、先に閉じてから操作する
      clean: editorsOpen.length === 1 && editorsOpen[0] === "スクラップにコメントを追加",
    };
  }, url);
}
