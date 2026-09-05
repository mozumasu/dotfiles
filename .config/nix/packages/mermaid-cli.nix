{
  lib,
  symlinkJoin,
  makeWrapper,
  mermaid-cli,
}:

# nixpkgs の mermaid-cli は darwin では chromium を同梱しないため、同梱 puppeteer が
# ~/.cache/puppeteer を探して失敗する。GUI アプリ (Raycast 等) は環境変数を渡さないので
# ラッパー側で実行ファイルを固定する。
# mmdc.mjs は `node <path>` の形で mmdc を起動する呼び出し元向け。bin/mmdc は bash
# ラッパーなので node に直接食わせると SyntaxError になる。
symlinkJoin {
  name = "mermaid-cli-wrapped-${mermaid-cli.version}";
  paths = [ mermaid-cli ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    chrome='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    wrapProgram $out/bin/mmdc --set-default PUPPETEER_EXECUTABLE_PATH "$chrome"
    cat > $out/bin/mmdc.mjs <<EOS
    process.env.PUPPETEER_EXECUTABLE_PATH ??= "$chrome";
    await import("${mermaid-cli}/lib/node_modules/@mermaid-js/mermaid-cli/src/cli.js");
    EOS
    chmod +x $out/bin/mmdc.mjs
  '';
  meta = mermaid-cli.meta // {
    mainProgram = "mmdc";
    platforms = lib.platforms.darwin;
  };
}
