{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "shishoctl";
  version = "0.15.0";

  src = fetchurl {
    url = "https://shisho.dev/releases/${pname}-${version}-aarch64-apple-darwin";
    hash = "sha256-QvYyMADlK5pFP3WmfQmg0wO6+dJuhv1flf9C9spkCa8=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/shishoctl
    chmod +x $out/bin/shishoctl
  '';

  meta = {
    description = "CLI tool for Shisho Cloud security platform";
    homepage = "https://shisho.dev";
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "shishoctl";
  };
}
