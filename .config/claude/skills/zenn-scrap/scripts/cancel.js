// 開きっぱなしの編集/返信フォームをすべてキャンセルする (途中失敗からの復帰用)。
// プレースホルダ: __URL_JSON__
async (page) => {
  const url = __URL_JSON__;
  // 本文入力済みのフォームをキャンセルすると confirm「変更が保存されていません。内容を破棄しますか？」が出る。
  // ネイティブダイアログが残ると CDP が固まるので、先に自動で受諾する
  page.once("dialog", (d) => d.accept());
  const r = await page.evaluate((url) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const btns = Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "キャンセル" && b.offsetParent !== null);
    btns.forEach((b) => b.click());
    return { clicked: btns.length };
  }, url);
  if (r.error) return r;
  await page.waitForTimeout(800);
  return await page.evaluate((clicked) => {
    const editorsOpen = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    return { ok: editorsOpen.length === 1 && editorsOpen[0] === "スクラップにコメントを追加", clicked, editorsOpen };
  }, r.clicked);
}
