{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "yaskkserv2";
  version = "0.1.7";

  src = fetchFromGitHub {
    owner = "wachikun";
    repo = "yaskkserv2";
    rev = version;
    hash = "sha256-bF8OHP6nvGhxXNvvnVCuOVFarK/n7WhGRktRN4X5ZjE=";
  };

  cargoHash = "sha256-cycs8Zism228rjMaBpNYa4K1Ll760UhLKkoTX6VJRU0=";

  # Tests require network and file system access that don't work in Nix sandbox
  doCheck = false;

  meta = {
    description = "Yet another SKK server";
    homepage = "https://github.com/wachikun/yaskkserv2";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
}
