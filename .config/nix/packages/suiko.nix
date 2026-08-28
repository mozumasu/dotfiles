{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchurl,
  unzip,
}:

let
  # build.rs は SudachiDict をこの SHA-256 に固定して埋め込む。
  # sandbox 内ではダウンロードできないため、事前取得した zip を
  # SUIKO_SUDACHI_DICT で渡す。suiko の版を上げるときは build.rs の
  # DICT_ZIP_URL / DICT_ZIP_SHA256 と合わせて更新する。
  sudachiDict = fetchurl {
    url = "https://d2ej7fkh96fzlu.cloudfront.net/sudachidict/sudachi-dictionary-20260723-core.zip";
    hash = "sha256-tug19jRA+XR0wtpF2AlQ9zdG5jLkC7/BaLQEFykTXh8=";
  };
in
rustPlatform.buildRustPackage rec {
  pname = "suiko";
  version = "0.3.3";

  src = fetchFromGitHub {
    owner = "nwiizo";
    repo = "suiko";
    rev = "v${version}";
    hash = "sha256-3x8U21cnstOUM9U5WjPIDmyAH/Lv6SDoBR1Tf2iFrTc=";
  };

  cargoHash = "sha256-4R5F+g89OXDmvWT/0nJdBVyLmmIDJQoTAAYdCmWmDkw=";

  nativeBuildInputs = [ unzip ];

  preBuild = ''
    unzip -j -o ${sudachiDict} '*system_core.dic' -d dict
    export SUIKO_SUDACHI_DICT=$PWD/dict/system_core.dic
  '';

  meta = {
    description = "Deterministic diagnostics for natural and readable Japanese writing";
    homepage = "https://github.com/nwiizo/suiko";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "suiko";
  };
}
