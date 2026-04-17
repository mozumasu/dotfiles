{ lib, pkgs, ... }:
let
  # 管理したい gh extension の一覧 (owner/repo 形式)
  extensions = [
    "github/gh-stack"
  ];
in
{
  home.activation.installGhExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    GH=${pkgs.gh}/bin/gh
    installed="$($GH extension list 2>/dev/null || true)"
    ${lib.concatMapStringsSep "\n" (ext: ''
      if ! printf '%s\n' "$installed" | grep -q "${ext}"; then
        echo "Installing gh extension: ${ext}"
        $GH extension install "${ext}" || true
      fi
    '') extensions}
  '';
}
