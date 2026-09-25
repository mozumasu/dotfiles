// 指定スレッドに返信を投稿する。
// プレースホルダ (すべて JSON 文字列リテラル):
//   __URL_JSON__    = 対象スクラップの URL
//   __THREAD_JSON__ = スレッド見出し (inspect の heading と完全一致)
//   __TEXT_JSON__   = 本文。検証用に「先頭の非見出し行」を使うので、段落から始める
async (page) => {
  const url = __URL_JSON__;
  const thread = __THREAD_JSON__;
  const text = __TEXT_JSON__;

  const opened = await page.evaluate(({ url, thread }) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const before = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    if (!(before.length === 1 && before[0] === "スクラップにコメントを追加")) return { error: "editor already open", eds: before };
    // スレッドブロック = 「返信を追加」をちょうど 1 個含む最小の祖先。見出し = innerText の 3 行目
    const replyBtns = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加");
    const hits = [];
    for (const btn of replyBtns) {
      let el = btn.parentElement, block = null;
      for (let k = 0; k < 20 && el; k++) {
        const n = Array.from(el.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加").length;
        if (n === 1 && el.querySelectorAll('button[aria-label="コメントを編集する"]').length >= 1) block = el;
        if (n > 1) break;
        el = el.parentElement;
      }
      if (!block) continue;
      const lines = block.innerText.split("\n").map((s) => s.trim()).filter(Boolean);
      if (lines[2] === thread) hits.push(btn);
    }
    if (hits.length !== 1) return { error: hits.length ? "thread heading not unique" : "thread not found (hidden? heading mismatch?)", thread, n: hits.length };
    hits[0].scrollIntoView({ block: "center" });
    hits[0].click();
    return { ok: true, before };
  }, { url, thread });
  if (opened.error) return opened;
  await page.waitForTimeout(900);

  // クリック前後の差分で、いま開いた返信フォームだけを対象にする
  const idx = await page.evaluate((before) => {
    const eds = Array.from(document.querySelectorAll(".cm-content"));
    const i = eds.findIndex((e, k) => e.getAttribute("aria-placeholder") === "返信内容を入力" && (k >= before.length || before[k] !== "返信内容を入力"));
    if (i >= 0) { eds[i].scrollIntoView({ block: "center" }); eds[i].focus(); }
    return i;
  }, opened.before);
  if (idx < 0) return { error: "reply editor not found" };

  await page.waitForTimeout(400);
  await page.keyboard.insertText(text);
  await page.waitForTimeout(500);
  const got = await page.evaluate((i) => document.querySelectorAll(".cm-content")[i].innerText.replace(/\s+/g, "").slice(0, 20), idx);
  if (got !== text.replace(/\s+/g, "").slice(0, 20)) return { error: "editor head mismatch", got, note: "フォームは開いたまま。cancel.js で閉じてから再試行" };

  const clicked = await page.evaluate(() => {
    const bs = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信する" && !b.disabled);
    if (bs.length !== 1) return { n: bs.length };
    bs[0].click();
    return { n: 1 };
  });
  if (clicked.n !== 1) return { error: "submit button", clicked };
  await page.waitForTimeout(4000);

  const marker = (text.split("\n").find((l) => l.trim() && !/^(#|```|:::)/.test(l.trim())) || text.slice(0, 30)).trim();
  return await page.evaluate(({ m, thread }) => {
    // 投稿後、そのスレッドブロックの中に marker があるか
    const replyBtns = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加");
    let ok = false;
    for (const btn of replyBtns) {
      let el = btn.parentElement, block = null;
      for (let k = 0; k < 20 && el; k++) {
        const n = Array.from(el.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加").length;
        if (n === 1) block = el;
        if (n > 1) break;
        el = el.parentElement;
      }
      if (!block) continue;
      const lines = block.innerText.split("\n").map((s) => s.trim()).filter(Boolean);
      if (lines[2] === thread && block.innerText.includes(m)) ok = true;
    }
    const eds = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    return { ok, posted_marker: m, editorsOpen: eds, note: ok ? undefined : "ok:false は「反映待ち」か「marker がレンダリングに出ない」。再投稿せず inspect で確認" };
  }, { m: marker, thread });
}
