// スレッド本文または返信を丸ごと差し替える。
// プレースホルダ (すべて JSON 文字列リテラル):
//   __URL_JSON__    = 対象スクラップの URL
//   __TARGET_JSON__ = "head" (スレッド本文) | "reply" (返信)
//   __THREAD_JSON__ = スレッド見出し (inspect の heading と完全一致)
//   __MARKER_JSON__ = 対象コメントだけに含まれる一意な文字列 (レンダリング後のテキスト。markdown 記号は含めない)
//   __EXPECT_JSON__ = 差し替え前の本文 (markdown 原文) の先頭 10〜15 文字を空白抜きで。例: "##Nixのインストール"
//                     heading (レンダリング後) とは違い、## などの記号を含める。取り違え防止の照合に使う
//   __TEXT_JSON__   = 新しい本文
async (page) => {
  const url = __URL_JSON__;
  const target = __TARGET_JSON__;
  const thread = __THREAD_JSON__;
  const marker = __MARKER_JSON__;
  const expect = __EXPECT_JSON__.replace(/\s+/g, "");
  const text = __TEXT_JSON__;

  const cancelOpen = async () => page.evaluate(() => {
    Array.from(document.querySelectorAll("button")).filter((b) => b.innerText.trim() === "キャンセル" && b.offsetParent !== null).forEach((b) => b.click());
  });

  const opened = await page.evaluate(({ url, target, thread, marker }) => {
    if (!location.href.startsWith(url)) return { error: "wrong page", href: location.href, expected: url };
    const before = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    if (!(before.length === 1 && before[0] === "スクラップにコメントを追加")) return { error: "editor already open", eds: before };

    // スレッドブロック (「返信を追加」をちょうど 1 個含む最小の祖先) を見出しで特定する
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
    for (const b of document.querySelectorAll('button[aria-label="コメントを編集する"]')) {
      const block = blockOf(b);
      if (!block || headingOf(block) !== thread) continue; // 所属スレッドを肯定条件で要求する
      // marker を含む最小祖先。本文側はスレッド見出し行を含み、返信側は含まない
      let el = b;
      for (let k = 0; k < 14 && el; k++) { if (el.innerText && el.innerText.includes(marker)) break; el = el.parentElement; }
      if (!el || !el.innerText.includes(marker)) continue;
      const isHead = el.innerText.includes(thread + "\n");
      if ((target === "head") === isHead) cands.push({ b, len: el.innerText.length });
    }
    if (!cands.length) return { error: "no candidate (hidden? marker/thread mismatch?)", target, thread, marker };
    cands.sort((a, b) => a.len - b.len); // 返信が複数でも最小の祖先を持つものが対象
    cands[0].b.scrollIntoView({ block: "center" });
    cands[0].b.click();
    return { ok: true, before, candidates: cands.length };
  }, { url, target, thread, marker });
  if (opened.error) return opened;
  await page.waitForTimeout(1000);

  // クリック前後の差分で、いま開いた編集フォームだけを対象にする
  const idx = await page.evaluate((before) => {
    const eds = Array.from(document.querySelectorAll(".cm-content"));
    const i = eds.findIndex((e, k) => e.getAttribute("aria-placeholder") === "内容を編集" && (k >= before.length || before[k] !== "内容を編集"));
    if (i >= 0) { eds[i].scrollIntoView({ block: "center" }); eds[i].focus(); }
    return i;
  }, opened.before);
  if (idx < 0) return { error: "editor not open" };
  await page.waitForTimeout(300);
  await page.keyboard.press("Meta+ArrowUp");
  await page.waitForTimeout(300);

  // 取り違え防止: 開いたエディタの先頭 (markdown 原文) が期待どおりでなければキャンセルして中断。再実行しないこと
  const before = await page.evaluate((i) => document.querySelectorAll(".cm-content")[i].innerText.replace(/\s+/g, "").slice(0, 40), idx);
  if (!before.startsWith(expect)) {
    await cancelOpen();
    return { error: "unexpected editor content, cancelled", before, expect, note: "TARGET / EXPECT を見直す。再実行しない" };
  }

  await page.keyboard.press("Meta+a");
  await page.waitForTimeout(200);
  await page.keyboard.insertText(text);
  await page.waitForTimeout(500);
  await page.keyboard.press("Meta+ArrowUp");
  await page.waitForTimeout(400);
  const head = await page.evaluate((i) => document.querySelectorAll(".cm-content")[i].innerText.replace(/\s+/g, "").slice(0, 20), idx);
  if (head !== text.replace(/\s+/g, "").slice(0, 20)) {
    await cancelOpen();
    return { error: "editor head mismatch after insert, cancelled", head };
  }

  await page.evaluate(() => { const b = Array.from(document.querySelectorAll("button")).find((b) => b.innerText.trim() === "更新する" && !b.disabled); b.click(); });
  await page.waitForTimeout(3500);
  return await page.evaluate((thread) => {
    const eds = Array.from(document.querySelectorAll(".cm-content")).map((e) => e.getAttribute("aria-placeholder"));
    return { ok: !eds.includes("内容を編集"), editorsOpen: eds, threadStillVisible: (document.querySelector("main") || document.body).innerText.includes(thread + "\n") };
  }, thread);
}
