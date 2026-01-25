{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Karabinerのmanipulatorを生成するヘルパー関数
  mkManipulator =
    {
      from,
      to,
      conditions ? [ ],
    }:
    {
      inherit from to;
      type = "basic";
      conditions = if conditions == [ ] then null else conditions;
    };

  # 共通のルール定義（両プロファイルで使用）
  commonRules = [
    # Alt+¥ を ¥ に変換
    {
      description = "Change Alt+¥ to ¥";
      manipulators = [
        {
          from = {
            key_code = "international3";
            modifiers.mandatory = [ "option" ];
          };
          to = [ { key_code = "international3"; } ];
          type = "basic";
        }
      ];
    }

    # ¥ を Alt+¥ に変換
    {
      description = "Change ¥ to Alt+¥";
      manipulators = [
        {
          from = {
            key_code = "international3";
          };
          to = [
            {
              key_code = "international3";
              modifiers = [ "option" ];
            }
          ];
          type = "basic";
        }
      ];
    }

    # Ctrl+H → Backspace
    {
      description = "^h to delete";
      manipulators = [
        {
          from = {
            key_code = "h";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "delete_or_backspace"; } ];
          type = "basic";
        }
      ];
    }

    # Ctrl+F/B → 左右矢印キー
    {
      description = "Left ctrl + f/b to arrow keys";
      manipulators = [
        {
          from = {
            key_code = "f";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "right_arrow"; } ];
          type = "basic";
        }
        {
          from = {
            key_code = "b";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "left_arrow"; } ];
          type = "basic";
        }
        # Ctrl+N/P → 上下矢印キー（wezterm以外）
        {
          conditions = [
            {
              bundle_identifiers = [ "com.github.wez.wezterm" ];
              type = "frontmost_application_unless";
            }
          ];
          from = {
            key_code = "n";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "down_arrow"; } ];
          type = "basic";
        }
        {
          conditions = [
            {
              bundle_identifiers = [ "com.github.wez.wezterm" ];
              type = "frontmost_application_unless";
            }
          ];
          from = {
            key_code = "p";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "up_arrow"; } ];
          type = "basic";
        }
      ];
    }

    # Ctrl+M → Enter
    {
      description = "^M to Enter";
      manipulators = [
        {
          from = {
            key_code = "m";
            modifiers = {
              mandatory = [ "left_control" ];
              optional = [ "any" ];
            };
          };
          to = [ { key_code = "return_or_enter"; } ];
          type = "basic";
        }
      ];
    }

    # Ctrl+Shift+I → 現在行をコピー
    {
      description = "Copy Current Line with control + shift + i";
      title = "Control+Shift+I to copy the current line";
      manipulators = [
        {
          from = {
            key_code = "i";
            modifiers = {
              mandatory = [
                "control"
                "shift"
              ];
              optional = [ "any" ];
            };
          };
          to = [
            {
              key_code = "left_arrow";
              modifiers = [ "left_command" ];
              repeat = false;
            }
            {
              key_code = "right_arrow";
              modifiers = [
                "left_command"
                "left_shift"
              ];
              repeat = false;
            }
            {
              key_code = "c";
              modifiers = [ "left_command" ];
              repeat = false;
            }
          ];
          type = "basic";
        }
      ];
    }
  ];

  # US配列用のルール（Ctrl+[を処理）
  usRules = commonRules ++ [
    {
      description = "Ctrl+[を押したときに、escキーと英数キーを送信する";
      manipulators = [
        {
          conditions = [
            {
              keyboard_types = [
                "ansi"
                "iso"
              ];
              type = "keyboard_type_if";
            }
          ];
          from = {
            key_code = "open_bracket";
            modifiers.mandatory = [ "control" ];
          };
          to = [
            { key_code = "escape"; }
            { key_code = "japanese_eisuu"; }
          ];
          type = "basic";
        }
      ];
    }
    {
      description = "Ctrl+[を押したときに、英数キーも送信する（vim用） (rev 2)";
      manipulators = [
        {
          conditions = [
            {
              keyboard_types = [
                "ansi"
                "iso"
              ];
              type = "keyboard_type_if";
            }
          ];
          from = {
            key_code = "open_bracket";
            modifiers.mandatory = [ "control" ];
          };
          to = [
            {
              key_code = "open_bracket";
              modifiers = [ "control" ];
            }
            { key_code = "japanese_eisuu"; }
          ];
          type = "basic";
        }
      ];
    }
  ];

  # JIS配列用のルール（Ctrl+]を処理）
  jisRules = commonRules ++ [
    {
      description = "Ctrl+[を押したときに、escキーと英数キーを送信する";
      manipulators = [
        {
          conditions = [
            {
              keyboard_types = [ "jis" ];
              type = "keyboard_type_if";
            }
          ];
          from = {
            key_code = "close_bracket";
            modifiers.mandatory = [ "control" ];
          };
          to = [
            { key_code = "escape"; }
            { key_code = "japanese_eisuu"; }
          ];
          type = "basic";
        }
      ];
    }
    {
      description = "Ctrl+[を押したときに、英数キーも送信する（vim用） (rev 2)";
      manipulators = [
        {
          conditions = [
            {
              keyboard_types = [ "jis" ];
              type = "keyboard_type_if";
            }
          ];
          from = {
            key_code = "close_bracket";
            modifiers.mandatory = [ "control" ];
          };
          to = [
            {
              key_code = "close_bracket";
              modifiers = [ "control" ];
            }
            { key_code = "japanese_eisuu"; }
          ];
          type = "basic";
        }
      ];
    }
  ];

  # 外部キーボードのデバイス情報
  externalKeyboardDevice = {
    identifiers = {
      is_keyboard = true;
      is_pointing_device = true;
      product_id = 24926;
      vendor_id = 7504;
    };
    ignore = false;
  };

  # プロファイル生成関数
  mkProfile =
    {
      name,
      selected,
      keyboardType,
      rules,
    }:
    {
      inherit name selected;
      complex_modifications = { inherit rules; };
      devices = [ externalKeyboardDevice ];
      virtual_hid_keyboard = {
        keyboard_type_v2 = keyboardType;
      };
    };

  # Karabinerの設定JSON
  karabinerConfig = {
    global = {
      show_in_menu_bar = false;
    };
    profiles = [
      # Mac内蔵キーボード用（US配列）
      (mkProfile {
        name = "Mac Built-in (US)";
        selected = false;
        keyboardType = "ansi";
        rules = usRules;
      })
      # 外部キーボード用（JIS配列）
      (mkProfile {
        name = "External Keyboard (JIS)";
        selected = true;
        keyboardType = "jis";
        rules = jisRules;
      })
    ];
  };

in
{
  # Karabinerの設定ファイルを生成
  xdg.configFile."karabiner/karabiner.json" = {
    text = builtins.toJSON karabinerConfig;
  };

  # 既存のカスタム complex_modifications をシンボリックリンク
  xdg.configFile."karabiner/assets/complex_modifications" = {
    source = ../../karabiner/assets/complex_modifications;
    recursive = true;
  };

  # プロファイル自動切り替えスクリプトをシンボリックリンク
  xdg.configFile."karabiner/scripts/auto-switch-profile.sh" = {
    source = ../../karabiner/scripts/auto-switch-profile.sh;
    executable = true;
  };

  # launchdエージェント - プロファイル自動切り替え
  launchd.agents.karabiner-auto-switch-profile = {
    enable = true;
    config = {
      ProgramArguments = [
        "${config.home.homeDirectory}/dotfiles/.config/karabiner/scripts/auto-switch-profile.sh"
      ];
      RunAtLoad = true;
      StartInterval = 5;
      StandardOutPath = "${config.home.homeDirectory}/.config/karabiner/scripts/auto-switch-profile.log";
      StandardErrorPath = "${config.home.homeDirectory}/.config/karabiner/scripts/auto-switch-profile.error.log";
    };
  };
}
