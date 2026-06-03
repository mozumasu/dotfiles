{
  lib,
  writeShellScriptBin,
  nodejs,
}:

writeShellScriptBin "playwright-cli" ''
  exec ${nodejs}/bin/npx -y @playwright/cli@0.1.13 "$@"
''
// {
  meta = {
    description = "Playwright CLI for controlling browsers via CDP";
    homepage = "https://playwright.dev";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "playwright-cli";
  };
}
