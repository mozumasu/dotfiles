{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "safe-chain";
  version = "1.4.2";

  src = fetchurl {
    url = "https://github.com/AikidoSec/safe-chain/releases/download/${version}/safe-chain-macos-arm64";
    hash = "sha256-Q2AMev3+0QVuC3l4fPo8/K59nuxXGFUEujW9zyc+paY=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/safe-chain
    chmod +x $out/bin/safe-chain
  '';

  meta = {
    description = "Block malicious code installed via npm, yarn, pip, etc.";
    homepage = "https://github.com/AikidoSec/safe-chain";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
  };
}
