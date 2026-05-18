{
  lib,
  stdenv,
  fetchurl,
  installShellFiles,
}:

let
  version = "0.13.2";

  sources = {
    "aarch64-darwin" = {
      arch = "aarch64-apple-darwin";
      hash = "sha256-QM5e10kPk3G8UqKJGHI/XCAQv32benswJz2LY7MNUFQ=";
    };
    "x86_64-darwin" = {
      arch = "x86_64-apple-darwin";
      hash = "sha256-GN1vbCidJPbvYJFgkj1MoC9m6kaRC0X+rkSgKAltclQ=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "ntn: unsupported platform ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "ntn";
  inherit version;

  src = fetchurl {
    url = "https://ntn.dev/releases/v${version}/ntn-${source.arch}.tar.gz";
    inherit (source) hash;
  };

  nativeBuildInputs = [ installShellFiles ];

  sourceRoot = "ntn-${source.arch}";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -m755 ntn $out/bin/ntn

    installShellCompletion --cmd ntn \
      --bash <($out/bin/ntn completions bash) \
      --fish <($out/bin/ntn completions fish) \
      --zsh  <($out/bin/ntn completions zsh)
    runHook postInstall
  '';

  meta = {
    description = "Official Notion CLI";
    homepage = "https://developers.notion.com/cli";
    license = lib.licenses.unfree;
    mainProgram = "ntn";
    maintainers = [ ];
    platforms = lib.attrNames sources;
  };
}
