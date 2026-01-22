{
  lib,
  writeShellScriptBin,
  nodejs,
}:

writeShellScriptBin "czg" ''
  exec ${nodejs}/bin/npx -y czg@1.12.0 "$@"
''
// {
  meta = {
    description = "Interactive Commitizen CLI that generate standardized git commit messages";
    homepage = "https://cz-git.qbb.sh/cli/";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
    mainProgram = "czg";
  };
}
