{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "gogcli";
  version = "0.11.0";

  src = fetchurl {
    url = "https://github.com/steipete/gogcli/releases/download/v${version}/gogcli_${version}_darwin_arm64.tar.gz";
    hash = "sha256-ESaGjD+TmhSqlld9Vlj1/vHhU58zJzC/NaBudBYsnmE=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src gog
    cp gog $out/bin/gog
    chmod +x $out/bin/gog
  '';

  meta = {
    description = "Fast, script-friendly CLI for Gmail, Calendar, Drive, and other Google Workspace services";
    homepage = "https://github.com/steipete/gogcli";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
  };
}
