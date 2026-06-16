{ ... }:
{
  # Basic Homebrew settings (packages are defined in hosts/common/homebrew.nix)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      # auto-update は有効のまま、rebuild ログのノイズだけ抑制する。
      # activation は隔離環境で brew を実行するため、shell の環境変数は
      # 継承されない。nix-darwin が `env KEY=VALUE brew bundle` に注入する
      # extraEnv 経由で設定する。
      extraEnv = {
        # `New Formulae` / `New Casks` の大量リスト(約480行)を抑制
        HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
        # analytics / donation などのヒント表示を抑制
        HOMEBREW_NO_ENV_HINTS = "1";
      };
    };

    taps = [
      "arto-app/tap"
      "d12frosted/emacs-plus"
      "felixkratz/formulae"
      "mtgto/macskk"
      "nikitabobko/tap"
      "olets/tap"
      "sh0nk/tap"
      "shu-pf/tap"
      "timac/vpnstatus"
      "xwmx/taps"
    ];
  };
}
