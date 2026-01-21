{
  lib,
  stdenv,
  fetchurl,
  undmg,
}:

stdenv.mkDerivation rec {
  pname = "kiro-cli";
  version = "1.24.0";

  src = fetchurl {
    url = "https://desktop-release.q.us-east-1.amazonaws.com/latest/Kiro%20CLI.dmg";
    hash = "sha256-V/akA/fcQZFULlBgGNibQRrhiBpGOr2s+jdPrAGOtnY=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    cp "Kiro CLI.app/Contents/MacOS/kiro-cli" $out/bin/kiro-cli
    chmod +x $out/bin/kiro-cli
  '';

  meta = {
    description = "Kiro CLI - Terminal-based AI assistant";
    homepage = "https://kiro.dev";
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
  };
}
