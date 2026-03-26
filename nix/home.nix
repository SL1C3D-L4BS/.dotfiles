{ pkgs, ... }:

{
  home.username       = "the_architect";
  home.homeDirectory  = "/home/the_architect";
  home.stateVersion   = "24.11";

  # ── Allow nix to manage itself ────────────────────────────────
  programs.home-manager.enable = true;

  # ── Nix settings ──────────────────────────────────────────────
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      keep-outputs          = true;
      keep-derivations      = true;
    };
  };

  # ── Core toolchain ────────────────────────────────────────────
  home.packages = with pkgs; [
    # Shell & terminal
    zsh
    starship
    atuin
    zoxide
    fzf
    direnv

    # File system
    eza           # ls replacement
    bat           # cat replacement
    fd            # find replacement
    ripgrep       # grep replacement
    delta         # git diff pager
    duf           # df replacement
    dust          # du replacement
    broot         # tree/file navigator

    # Git
    lazygit
    gh            # GitHub CLI

    # Monitoring
    btop
    procs         # ps replacement
    bandwhich     # network monitor

    # Data tools (agentic core)
    jq
    yq-go
    miller        # csv/json/tsv swiss army knife
    duckdb        # local SQL engine for parquet/csv

    # Editors
    neovim

    # Build tools
    gnumake
    gcc
    cmake
    ninja
    meson

    # Formatters & Linters (global)
    stylua
    shfmt
    shellcheck
    nixfmt-rfc-style
    nodePackages.prettier
    hadolint

    # Infra & Cloud
    terraform
    kubectl
    k9s
    dive          # docker image explorer

    # Secrets
    age
    sops

    # Dotfile management
    chezmoi

    # HTTP & API
    httpie
    xh            # fast HTTP client

    # Utilities
    wget
    curl
    rsync
    unzip
    p7zip
    tree
    watch
    tmux
    mosh
    xclip
    xdotool
    maim          # screenshot
    numlockx
    just          # command runner (modern make)
    hyperfine     # benchmarking
    tokei         # code stats
    sd            # sed replacement
    choose        # cut replacement
    gping         # ping with graph
  ];

  # ── Direnv integration ────────────────────────────────────────
  programs.direnv = {
    enable               = true;
    nix-direnv.enable    = true;
    enableZshIntegration = true;
  };

  # ── Atuin shell history ────────────────────────────────────────
  programs.atuin = {
    enable               = true;
    enableZshIntegration = true;
    settings = {
      style             = "compact";
      inline_height     = 20;
      ctrl_n_shortcuts  = true;
      filter_mode_shell_up_key_binding = "session";
      enter_accept      = true;
    };
  };

  # ── Zoxide smart cd ───────────────────────────────────────────
  programs.zoxide = {
    enable               = true;
    enableZshIntegration = true;
    options              = [ "--cmd cd" ];
  };

  # ── Starship prompt ───────────────────────────────────────────
  programs.starship = {
    enable               = true;
    enableZshIntegration = true;
    configPath           = "/home/the_architect/.config/shell/starship.toml";
  };

  # ── Git config ────────────────────────────────────────────────
  programs.git = {
    enable    = true;
    settings = {
      user = {
        name  = "SL1C3D-L4BS";
        email = "slicedlabs.founder@proton.me";
      };
      core.editor          = "nvim";
      pull.rebase          = true;
      push.autoSetupRemote = true;
      init.defaultBranch   = "main";
      diff.colorMoved      = "plain";
      diff.algorithm       = "histogram";
      diff.mnemonicPrefix  = true;
      commit.verbose       = true;
      branch.sort          = "-committerdate";
      tag.sort             = "-version:refname";
      rerere.enabled       = true;
      rerere.autoupdate    = true;
    };
  };

  programs.delta = {
    enable                = true;
    enableGitIntegration  = true;
    options = {
      navigate          = true;
      line-numbers      = true;
      side-by-side      = false;
      syntax-theme      = "gruvbox-dark";
      features          = "decorations";
    };
  };

  # ── ZSH ───────────────────────────────────────────────────────
  programs.zsh = {
    enable         = true;
    dotDir         = "/home/the_architect/.config/shell";
    initContent    = builtins.readFile ../home/.config/shell/zshrc;
    envExtra       = ''
      export STARSHIP_CONFIG="$HOME/.config/shell/starship.toml"
    '';
  };

  # ── Bat (cat replacement) ─────────────────────────────────────
  programs.bat = {
    enable = true;
    config = {
      theme  = "gruvbox-dark";
      pager  = "less -FR";
      style  = "plain";
    };
  };

  # ── Lazygit ───────────────────────────────────────────────────
  programs.lazygit = {
    enable   = true;
    settings = {
      gui.theme = {
        activeBorderColor   = [ "#2D6A4F" "bold" ];
        inactiveBorderColor = [ "#6B6B7B" ];
        optionsTextColor    = [ "#9B59B6" ];
        selectedLineBgColor = [ "#1A472A" ];
      };
      git.paging.colorArg = "always";
      git.paging.pager    = "delta --color-only";
    };
  };

  # ── XDG dirs ──────────────────────────────────────────────────
  xdg.enable = true;
  xdg.userDirs = {
    enable            = true;
    createDirectories = true;
    desktop           = "$HOME/Desktop";
    documents         = "$HOME/Documents";
    download          = "$HOME/Downloads";
    music             = "$HOME/Music";
    pictures          = "$HOME/Pictures";
    videos            = "$HOME/Videos";
  };
}
