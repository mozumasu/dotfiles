{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "slack-cli";
  version = "4.1.0";

  src = fetchurl {
    url = "https://downloads.slack-edge.com/slack-cli/slack_cli_${version}_macOS_arm64.tar.gz";
    hash = "sha256-L9BqRKbkR4OvAv8qODYO+ov/TGFN0x9zhLny9auoTCk=";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xzf $src -C $out
    chmod +x $out/bin/slack
  '';

  meta = {
    description = "Official Slack platform CLI for building and managing Slack apps";
    homepage = "https://docs.slack.dev/tools/slack-cli";
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "aarch64-darwin" ];
    mainProgram = "slack";
  };
}
