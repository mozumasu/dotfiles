{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "pup";
  version = "0.25.0";

  src = fetchurl {
    url = "https://github.com/datadog-labs/pup/releases/download/v${version}/pup_${version}_Darwin_arm64.tar.gz";
    hash = "sha256-JISEaZGF/z+6vN2fFBETSutgXu87hwDyyAENdsonax4=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src pup
    cp pup $out/bin/pup
    chmod +x $out/bin/pup
  '';

  meta = {
    description = "CLI tool for Datadog's observability platform with 200+ commands across 33+ products";
    homepage = "https://github.com/datadog-labs/pup";
    license = lib.licenses.asl20;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "pup";
  };
}
