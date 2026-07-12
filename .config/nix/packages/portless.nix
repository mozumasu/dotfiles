{
  lib,
  writeShellScriptBin,
  nodejs,
}:

writeShellScriptBin "portless" ''
  exec ${nodejs}/bin/npx -y portless@0.15.1 "$@"
''
// {
  meta = {
    description = "Automatic port allocation and stable *.localhost URLs for local dev servers";
    homepage = "https://github.com/vercel-labs/portless";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "portless";
  };
}
