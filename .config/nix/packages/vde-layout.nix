{
  lib,
  writeShellScriptBin,
  nodejs,
}:

writeShellScriptBin "vde-layout" ''
  exec ${nodejs}/bin/npx -y vde-layout@1.1.1 "$@"
''
// {
  meta = {
    description = "A command-line tool for managing terminal layouts across tmux and WezTerm";
    homepage = "https://github.com/yuki-yano/vde-layout";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "vde-layout";
  };
}
