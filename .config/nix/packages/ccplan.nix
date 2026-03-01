{
  lib,
  writeShellScriptBin,
  nodejs,
}:

writeShellScriptBin "ccplan" ''
  exec ${nodejs}/bin/npx -y ccplan@0.1.3 "$@"
''
// {
  meta = {
    description = "A planning tool for Claude Code";
    homepage = "https://www.npmjs.com/package/ccplan";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "ccplan";
  };
}
