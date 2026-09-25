// スレッドの返信を削除する (本文は対象外)。必ず dry run → candidate を提示して了承 → 本実行、の順で使う。
// プレースホルダ (すべて JSON リテラル):
//   __URL_JSON__       = 対象スクラップの URL
//   __THREAD_JSON__    = 返信が属するスレッドの見出し (inspect の heading と完全一致)
//   __MARKER_JSON__    = 削除する返信だけに含まれる一意な文字列
//   __CANDIDATE_JSON__ = dry run では null。本実行では dry run が返した candidate 文字列をそのまま (一致しなければ削除しない)
async (page) => {
  const url = __URL_JSON__;
  const thread = __THREAD_JSON__;
  const marker = __MARKER_JSON__;
  const candidate = __CANDIDATE_JSON__;
  const dry = candidate === null;

  const found = await page.evaluate(({ url, thread, marker, candidate, dry }) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const eds = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    if (!(eds.length === 1 && eds[0] === "スクラップにコメントを追加")) return { error: "editor already open", eds };

    const blockOf = (node) => {
      let el = node, block = null;
      for (let k = 0; k < 20 && el; k++) {
        const n = Array.from(el.querySelectorAll("button")).filter((b) => b.innerText.trim() === "返信を追加").length;
        if (n === 1 && el.querySelectorAll('button[aria-label="コメントを編集する"]').length >= 1) block = el;
        if (n > 1) break;
        el = el.parentElement;
      }
      return block;
    };
    const headingOf = (block) => block.innerText.split("\n").map((s) => s.trim()).filter(Boolean)[2];

    const cands = [];
    for (const m of document.querySelectorAll('button[aria-label="メニューを開く"]')) {
      const block = blockOf(m);
      if (!block || headingOf(block) !== thread) continue; // 所属スレッドを肯定条件で要求
      let el = m;
      for (let k = 0; k < 14 && el; k++) { if (el.innerText && el.innerText.includes(marker)) break; el = el.parentElement; }
      if (!el || !el.innerText.includes(marker)) continue;
      if (el.innerText.includes(thread + "\n")) continue; // 本文側は対象外
      cands.push({ m, len: el.innerText.length, head: el.innerText.slice(0, 60).replace(/\n+/g, " | ") });
    }
    cands.sort((a, b) => a.len - b.len);
    if (!cands.length) return { error: "no candidate (hidden? marker/thread mismatch?)" };
    const c = cands[0];
    if (dry) return { dry: true, candidate: c.head, candidates: cands.length, note: "この candidate をユーザーに提示し、了承後に __CANDIDATE_JSON__ に転記して本実行" };
    if (c.head !== candidate) return { error: "candidate changed since dry run, aborted", now: c.head, expected: candidate };
    c.m.scrollIntoView({ block: "center" });
    c.m.click();
    return { ok: true, candidate: c.head };
  }, { url, thread, marker, candidate, dry });
  if (found.error || found.dry) return found;

  await page.waitForTimeout(700);
  const del = page.locator('[role="menu"] button, [role="menuitem"], button', { hasText: /^削除$/ }).filter({ visible: true }).first();
  if (!(await del.count())) return { error: "delete menu item not found" };
  await del.click();
  await page.waitForTimeout(1200);
  // 確認モーダル内のボタンだけを対象にする (メニュー項目の「削除」と混同しない)
  const confirmBtn = page.locator('[role="dialog"] button, [aria-modal="true"] button', { hasText: /^(削除する|削除|OK)$/ }).filter({ visible: true });
  if (await confirmBtn.count()) { await confirmBtn.first().click(); await page.waitForTimeout(3000); }
  else return { error: "confirm dialog not found (menu opened, nothing deleted?)" };
  return await page.evaluate(({ marker, thread }) => {
    const body = (document.querySelector("main") || document.body).innerText;
    return { ok: !body.includes(marker), threadStillVisible: body.includes(thread + "\n") };
  }, { marker, thread });
}
