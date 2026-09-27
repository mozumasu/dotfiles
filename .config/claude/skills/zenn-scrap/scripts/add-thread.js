// スクラップ末尾に新しいスレッドを投稿する。
// プレースホルダ (すべて JSON 文字列リテラル):
//   __URL_JSON__  = 対象スクラップの URL
//   __TEXT_JSON__ = 本文 (例: "## 見出し\n\n本文")。検証用に「先頭の非見出し行」を使うので、本文はコードフェンスや ::: ではなく段落から始める
async (page) => {
  const url = __URL_JSON__;
  const text = __TEXT_JSON__;
  if (text.length > 20000) return { error: "text too long", length: text.length, note: "zenn のコメント本文は 20,000 文字まで。分割するかリンクにする" };

  const pre = await page.evaluate((url) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const eds = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    if (!(eds.length === 1 && eds[0] === "スクラップにコメントを追加")) return { error: "editor already open", eds };
    const e = document.querySelector(".cm-content");
    if (e.innerText.trim() && e.innerText.trim() !== "スクラップにコメントを追加") return { error: "bottom editor not empty", head: e.innerText.slice(0, 60) };
    e.scrollIntoView({ block: "center" });
    e.focus();
    return { ok: true };
  }, url);
  if (pre.error) return pre;

  await page.waitForTimeout(400);
  await page.keyboard.insertText(text);
  await page.waitForTimeout(500);
  const got = await page.evaluate(() => document.querySelector(".cm-content").innerText.replace(/\s+/g, "").slice(0, 20));
  if (got !== text.replace(/\s+/g, "").slice(0, 20)) return { error: "editor head mismatch", got, note: "フォームは開いたまま。cancel.js で閉じてから再試行" };

  const clicked = await page.evaluate(() => {
    // ヘッダにも「投稿する」があるので、フォーム側 (Button-module) だけを対象にする
    const bs = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "投稿する" && !b.disabled && b.className.includes("Button-module"));
    if (bs.length !== 1) return { n: bs.length };
    bs[0].click();
    return { n: 1 };
  });
  if (clicked.n !== 1) return { error: "submit button", clicked };
  await page.waitForTimeout(4000);

  const marker = (text.split("\n").find((l) => l.trim() && !/^(#|```|:::)/.test(l.trim())) || text.slice(0, 30)).trim();
  return await page.evaluate((m) => {
    const body = (document.querySelector("main") || document.body).innerText;
    const eds = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    return { ok: body.includes(m), posted_marker: m, editorsOpen: eds, note: "ok:false は「反映待ち」か「marker がレンダリングに出ない」。再投稿せず inspect で確認" };
  }, marker);
}
