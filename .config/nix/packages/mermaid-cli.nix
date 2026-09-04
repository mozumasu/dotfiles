{
  lib,
  symlinkJoin,
  makeWrapper,
  mermaid-cli,
}:

# nixpkgs の mermaid-cli は darwin では chromium を同梱しないため、同梱 puppeteer が
# ~/.cache/puppeteer を探して失敗する。GUI アプリ (Raycast 等) は環境変数を渡さないので
# ラッパー側で実行ファイルを固定する。
symlinkJoin {
  name = "mermaid-cli-wrapped-${mermaid-cli.version}";
  paths = [ mermaid-cli ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/mmdc \
      --set-default PUPPETEER_EXECUTABLE_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  '';
  meta = mermaid-cli.meta // {
    mainProgram = "mmdc";
    platforms = lib.platforms.darwin;
  };
}
