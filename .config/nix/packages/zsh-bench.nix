{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  zsh,
}:

stdenvNoCC.mkDerivation {
  pname = "zsh-bench";
  version = "0-unstable-2024-03-01";

  src = fetchFromGitHub {
    owner = "romkatv";
    repo = "zsh-bench";
    rev = "28b1b1bc888159f0a2cf50f9d29381758341aba1";
    hash = "sha256-dsHGpDTweDqJdLhO/9th2kDt56crfjqkTKBilEi9RaY=";
  };

  # スクリプトは ${ZSH_SCRIPT:A:h} で自身の隣にある internal/ configs/ を探す
  # (:A はシンボリックリンクを解決するので bin/ からのリンクで良い)
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zsh-bench $out/bin
    cp -r zsh-bench human-bench zsh-playground internal configs $out/share/zsh-bench/
    patchShebangs $out/share/zsh-bench
    for f in zsh-bench human-bench zsh-playground; do
      ln -s $out/share/zsh-bench/$f $out/bin/$f
    done
    runHook postInstall
  '';

  buildInputs = [ zsh ];

  meta = {
    description = "Benchmark for interactive zsh";
    homepage = "https://github.com/romkatv/zsh-bench";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
    mainProgram = "zsh-bench";
  };
}
