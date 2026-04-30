{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "gcx";
  version = "0.2.11";

  src = fetchurl {
    url = "https://github.com/grafana/gcx/releases/download/v${version}/gcx_${version}_darwin_arm64.tar.gz";
    hash = "sha256-BfM8r34tpJeuxTrC3Dd/yoR/ZRLusKJVe+lZjZo8jYk=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src gcx
    cp gcx $out/bin/gcx
    chmod +x $out/bin/gcx
  '';

  meta = {
    description = "CLI for managing Grafana Cloud resources, optimized for agentic usage";
    homepage = "https://github.com/grafana/gcx";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "gcx";
  };
}
