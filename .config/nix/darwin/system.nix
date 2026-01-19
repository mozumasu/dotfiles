{ lib, config, ... }:
{
  system.stateVersion = 5;
  programs.zsh = {
    enable = true;
    # /etc/zshrc で compinit を無効化 (ユーザー .zshrc で一度だけ実行)
    enableCompletion = false;
    enableBashCompletion = false;
    # promptinit も無効化 (starship を使用)
    promptInit = "";
    # brew shellenv を無効化 (ユーザー .zshrc でキャッシュ経由で実行)
    interactiveShellInit = lib.mkForce "";
  };
  security.pam.services.sudo_local.touchIdAuth = true;

  # ============================================================================
  # システム設定 (System Preferences)
  # ============================================================================
  system.defaults = {
    # --------------------------------------------------------------------------
    # Dock
    # --------------------------------------------------------------------------
    dock = {
      # Dockのサイズ
      tilesize = 34;
      # 拡大機能
      magnification = true;
      largesize = 65;
      # Dockの位置 ("left", "bottom", "right")
      orientation = "bottom";
      # 自動的に非表示
      autohide = true;
      # 非表示/表示のアニメーション時間 (0で即時)
      # autohide-time-modifier = 0.2;
      # 非表示になるまでの遅延
      # autohide-delay = 0.0;
      # 起動中のアプリにインジケータを表示
      show-process-indicators = true;
      # 最近使ったアプリを表示
      show-recents = true;
      # ウィンドウをアプリアイコンにしまう
      minimize-to-application = false;
      # しまうときのエフェクト ("genie", "scale")
      mineffect = "genie";
      # スタックにマウスオーバーでハイライト
      mouse-over-hilite-stack = true;
      # 静的なアプリのみ表示 (実行中のアプリを非表示)
      static-only = false;
    };

    # --------------------------------------------------------------------------
    # Finder
    # --------------------------------------------------------------------------
    finder = {
      # 拡張子を常に表示
      AppleShowAllExtensions = true;
      # 隠しファイルを表示
      AppleShowAllFiles = false;
      # ステータスバーを表示
      ShowStatusBar = true;
      # パスバーを表示
      ShowPathbar = true;
      # デスクトップにハードディスクを表示
      ShowHardDrivesOnDesktop = false;
      # デスクトップに外部ドライブを表示
      ShowExternalHardDrivesOnDesktop = false;
      # デスクトップにリムーバブルメディアを表示
      ShowRemovableMediaOnDesktop = true;
      # デスクトップにマウントされたサーバーを表示
      ShowMountedServersOnDesktop = false;
      # デフォルトの表示形式 ("Nlsv"=リスト, "icnv"=アイコン, "clmv"=カラム, "Flwv"=ギャラリー)
      FXPreferredViewStyle = "Nlsv";
      # フォルダを常に先頭に表示
      _FXSortFoldersFirst = false;
      # 検索時のデフォルトスコープ ("SCcf"=現在のフォルダ, "SCsp"=前回のスコープ, "SCev"=Mac全体)
      FXDefaultSearchScope = "SCev";
      # 拡張子変更時の警告
      FXEnableExtensionChangeWarning = true;
      # タイトルバーにフルパスを表示
      _FXShowPosixPathInTitle = false;
      # 新規ウィンドウのデフォルトパス
      NewWindowTarget = "Home";
    };

    # --------------------------------------------------------------------------
    # グローバル設定 (NSGlobalDomain)
    # --------------------------------------------------------------------------
    NSGlobalDomain = {
      # ダークモード
      AppleInterfaceStyle = "Dark";

      # キーボード
      # キーリピート速度 (小さいほど速い, 最速は1)
      KeyRepeat = 1;
      # キーリピート開始までの時間 (小さいほど速い, 最速は10)
      InitialKeyRepeat = 12;

      # 自動補正 (現在有効)
      NSAutomaticSpellingCorrectionEnabled = true;
      NSAutomaticCapitalizationEnabled = true;
      NSAutomaticDashSubstitutionEnabled = true;
      NSAutomaticPeriodSubstitutionEnabled = true;
      NSAutomaticQuoteSubstitutionEnabled = true;

      # スクロール
      # ナチュラルスクロール
      "com.apple.swipescrolldirection" = true;
      # スクロールバー表示 ("WhenScrolling", "Automatic", "Always")
      AppleShowScrollBars = "Automatic";
      # スクロールバークリック時の動作 (true=その位置にジャンプ, false=次のページ)
      AppleScrollerPagingBehavior = false;

      # ウィンドウ
      # ウィンドウの開閉アニメーション
      NSAutomaticWindowAnimationsEnabled = true;

      # 外観
      # メニューバーを自動的に非表示
      _HIHideMenuBar = false;
      # 24時間表示
      AppleICUForce24HourTime = false;
      # 測定単位
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      # 保存ダイアログを展開
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
      # 印刷ダイアログを展開
      PMPrintingExpandedStateForPrint = true;
      PMPrintingExpandedStateForPrint2 = true;
      # iCloudに保存しない
      NSDocumentSaveNewDocumentsToCloud = false;
      # スクロールアニメーション
      NSScrollAnimationEnabled = true;
      # フォーカスリングアニメーション
      NSUseAnimatedFocusRing = true;
      # サイドバーのアイコンサイズ (1=小, 2=中, 3=大)
      NSTableViewDefaultSizeMode = 2;
    };

    # --------------------------------------------------------------------------
    # トラックパッド
    # --------------------------------------------------------------------------
    trackpad = {
      # タップでクリック
      Clicking = true;
      # 右クリック (二本指タップ)
      TrackpadRightClick = true;
      # 3本指ドラッグ
      TrackpadThreeFingerDrag = true;
      # 静音クリック (0=静音, 1=通常)
      ActuationStrength = 0;
    };

    # --------------------------------------------------------------------------
    # スクリーンキャプチャ
    # --------------------------------------------------------------------------
    screencapture = {
      # 保存先
      location = "~/Pictures/Screenshots";
      # ファイル形式 ("png", "jpg", "pdf", "psd", "gif", "tga", "tiff", "bmp")
      type = "png";
      # 影を含めない
      disable-shadow = false;
      # サムネイルを表示
      show-thumbnail = true;
    };

    # --------------------------------------------------------------------------
    # スクリーンセーバー
    # --------------------------------------------------------------------------
    screensaver = {
      # スクリーンセーバー解除時にパスワードを要求
      askForPassword = false;
      # パスワード要求までの遅延 (秒)
      askForPasswordDelay = 0;
    };

    # --------------------------------------------------------------------------
    # ログインウィンドウ
    # --------------------------------------------------------------------------
    loginwindow = {
      # ゲストアカウントを無効化
      GuestEnabled = false;
    };

    # --------------------------------------------------------------------------
    # メニューバーの時計
    # --------------------------------------------------------------------------
    menuExtraClock = {
      # 日付を表示 (0=非表示, 1=アイコン付き, 2=日付のみ)
      ShowDate = 0;
      # 曜日を表示
      ShowDayOfWeek = true;
      # 秒を表示
      ShowSeconds = false;
      # 24時間表示
      Show24Hour = false;
      # AM/PMを表示 (12時間表示の場合)
      ShowAMPM = true;
      # アナログ表示
      IsAnalog = false;
    };

    # --------------------------------------------------------------------------
    # Universal Access (アクセシビリティ)
    # --------------------------------------------------------------------------
    # NOTE: universalaccess settings require special permissions and may fail on first setup
    # Configure manually in System Preferences > Accessibility if needed

    # --------------------------------------------------------------------------
    # スペース (Mission Control)
    # --------------------------------------------------------------------------
    spaces = {
      # ディスプレイごとに個別のスペース (true = ディスプレイをまたぐ)
      spans-displays = true;
    };

    # --------------------------------------------------------------------------
    # WindowManager
    # --------------------------------------------------------------------------
    WindowManager = {
      # Stage Manager
      GloballyEnabled = false;
    };

    # --------------------------------------------------------------------------
    # Launch Services
    # --------------------------------------------------------------------------
    LaunchServices = {
      # 未確認アプリの警告を無効化
      LSQuarantine = false;
    };

    # --------------------------------------------------------------------------
    # Software Update
    # --------------------------------------------------------------------------
    SoftwareUpdate = {
      # 自動でアップデートをチェック
      AutomaticallyInstallMacOSUpdates = false;
    };

    # --------------------------------------------------------------------------
    # カスタム設定
    # --------------------------------------------------------------------------
    CustomUserPreferences = {
      # Bluetoothオーディオの品質を向上
      "com.apple.BluetoothAudioAgent" = {
        "Apple Bitpool Min (editable)" = 40;
      };
      # クラッシュレポートを無効化
      "com.apple.CrashReporter" = {
        DialogType = "none";
      };
      # ヘルプビューアをフローティングにしない
      "com.apple.helpviewer" = {
        DevMode = true;
      };
    };

    # --------------------------------------------------------------------------
    # マウス設定
    # --------------------------------------------------------------------------
    ".GlobalPreferences" = {
      # マウスの速度 (-1 から 3)
      "com.apple.mouse.scaling" = 3.0;
    };
  };

  # ============================================================================
  # キーボード設定
  # ============================================================================
  system.keyboard = {
    # キーボードナビゲーションを有効化
    enableKeyMapping = true;
    # Caps LockをControlに
    remapCapsLockToControl = true;
  };

  # ============================================================================
  # Activation Scripts
  # ============================================================================

  system.activationScripts.extraActivation.text = ''
    echo "=== extraActivation: Starting ==="

    # Homebrew ディレクトリの作成とパーミッション修正
    # ユーザー名をNix設定から直接取得（SUDO_USERはnix run経由では空になるため）
    BREW_USER="${config.hostSpec.username}"
    echo "BREW_USER=$BREW_USER"

    if [[ -n "$BREW_USER" ]]; then
      # ARM Homebrew
      if [[ ! -d "/opt/homebrew" ]]; then
        echo "Creating Homebrew directory for $BREW_USER..."
        /bin/mkdir -p /opt/homebrew
      fi
      echo "Fixing Homebrew directory permissions for $BREW_USER..."
      /usr/sbin/chown -R "$BREW_USER":admin /opt/homebrew

      # Intel Homebrew (Rosetta)
      if [[ -d "/usr/local/Homebrew" ]]; then
        echo "Fixing Intel Homebrew directory permissions for $BREW_USER..."
        /usr/sbin/chown -R "$BREW_USER":admin /usr/local/Homebrew
        /usr/sbin/chown -R "$BREW_USER":admin /usr/local/bin 2>/dev/null || true
      fi
    else
      echo "WARNING: BREW_USER is not set (config.hostSpec.username is empty)"
    fi

    # Xcode Command Line Tools のチェックとインストール
    if ! /usr/bin/xcrun -f clang >/dev/null 2>&1; then
      echo "Installing Xcode Command Line Tools..."
      touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
      PROD=$(/usr/sbin/softwareupdate -l | grep "\*.*Command Line" | tail -n 1 | sed 's/^[^C]* //')
      /usr/sbin/softwareupdate -i "$PROD" --verbose
      rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    fi

    # Rosetta 2 のインストール (Apple Silicon)
    if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q oahd; then
      echo "Installing Rosetta 2..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    echo "=== extraActivation: Done ==="
  '';
}
