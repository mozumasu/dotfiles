{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "skanehira-ghost";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "skanehira";
    repo = "ghost";
    rev = "v${version}";
    hash = "sha256-PhHC1FOcUBS1ZK97hjJ7zJOsJql2JkSJHkZNZqRRAVc=";
  };

  cargoHash = "sha256-R+k9YrZMBxZQXonWNNCj2Dm56lMU1okHPVe3E6jhTRM=";

  # Tests require lsof and multi-process operations that don't work in Nix sandbox
  doCheck = false;

  meta = {
    description = "A simple background process manager for Unix systems";
    homepage = "https://github.com/skanehira/ghost";
    license = lib.licenses.mit;
    maintainers = [ ];
    mainProgram = "ghost";
    platforms = lib.platforms.unix;
  };
}
