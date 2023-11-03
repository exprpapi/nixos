{ config, lib, pkgs, ... }:
let
  mainuser = "u";
  initial_password = "password";
  label_boot = "boot";
  label_root = "root";
  label_luks = "luks";
  state_version = "23.05";
in
{
  imports = [
    (let
      gh = x: "https://github.com/${x}";
      url = gh "nix-community/home-manager/archive/release-23.05.tar.gz";
      home-manager = import "${builtins.fetchTarball url}/nixos";
    in home-manager)
  ];
  
  fileSystems."/boot".device = "/dev/disk/by-label/${label_boot}";
  fileSystems."/".device = "/dev/disk/by-label/${label_root}";
  
  boot = {
    initrd = {
      luks.devices.${label_luks}.device = "/dev/disk/by-label/${label_luks}";
      verbose = false;
      availableKernelModules = [
        "ata_piix"
        "ohci_pci"
        "ehci_pci"
        "ahci"
        "sd_mod"
        "sr_mod"
      ];
    };
  
    plymouth.enable = true;
    consoleLogLevel = 0;
  
    kernelPackages = pkgs.linuxPackages_latest; 

    kernelParams = [
      "quiet"
      "log_level=0"
      "udev.log_level=3"
      "splash"
      "rd.systemd.show_status=false"
    ];
  
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0;
    };
  };
  
  fonts = {
    enableDefaultFonts = true;

    fonts = with pkgs; [
      powerline-fonts
      nerdfonts
      iosevka
      meslo-lgs-nf
    ];
  };
  
  services = {
    logind = {
      killUserProcesses = true;
      lidSwitch = "suspend";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
        IdleAction=lock
      '';
    };
    kmscon = {
      enable = true;
      hwRender = true;
      extraConfig = ''
        font-name=MesloLGS NF
        font-size=14
      '';
    };
  
    xserver = {
      enable = true;
  
      libinput.enable = true;
  
      displayManager = {
        autoLogin = {
          enable = true;
          user = mainuser;
        };
  
        sddm.enable = true;
      };

      # dpi = 150;
      # autorun = true;
      # autoRepeatDelay = TODO;
      # autoRepeatInterval = TODO;

      desktopManager.plasma5.enable = true;
      layout = "us";
      xkbVariant = "altgr-intl";
      xkbOptions = "caps:escape";
    };
  
    picom.enable = true;
  
    printing = {
      enable = true;
      browsing = true;
      stateless = true;
      drivers = with pkgs; [
        cnijfilter2
        cups-bjnp
        gutenprint
        splix
      ];
    };
  
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  
    gnome.gnome-keyring.enable = true;
  
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  
    openssh.enable = false;
    
    blueman.enable = true;

    udev = {
      packages = with pkgs; [
        android-udev-rules
      ];
    };
  };
  
  networking = {
    hostName = mainuser;
    networkmanager.enable = true;
    firewall = {
      enable = false;
      trustedInterfaces = [ "docker0" ];
    };
  };
  
  
  location.provider = "geoclue2";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_DK.UTF-8";
    };
  };
  
  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };
  
  
  users = {
    defaultUserShell = pkgs.zsh;
  
    users = {
      "root".initialPassword = initial_password;
  
      ${mainuser} = {
        initialPassword = initial_password;
        isNormalUser = true;
        description = mainuser;
        extraGroups = [
          "docker"
          "lp"
          "networkmanager"
          "scanner"
          "vboxusers"
          "video"
          "wheel"
        ];
      };
    };
  
    extraGroups = {
      vboxusers.members = [ mainuser ];
      docker.members = [ mainuser ];
    };
  };
  
  virtualisation = {
    virtualbox = {
      host.enable = true;
      # guest.enable = true;
      guest.x11 = true;
    };
  
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
      autoPrune.enable = true;
    };
  };
  
  console = {
    useXkbConfig = true;
    font = "ter-132n";
    packages = with pkgs; [ terminus_font ];
  };
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs = {
    config.allowUnfree = true;
    hostPlatform = lib.mkDefault "x86_64-linux";
  };
  programs = {
    adb.enable = true;
    tmux.enable = true;
    zsh.enable = true;
    dconf.enable = true;
  };
  system.stateVersion = state_version;
  sound.enable = true;
  time.timeZone = "Europe/Berlin";
  
  hardware = {
    pulseaudio.enable = false;
  
    bluetooth = {
      enable = true;
  
      settings = {
        General = {
          Experimental = true;
        };
      };
    };

    trackpoint = {
      enable = true;
      # sensitivity = 255;
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        vulkan-extension-layer
        vulkan-tools
      ];
    };

    sane = {
      enable = true;
      extraBackends = with pkgs; [ sane-airscan ];
    };
  };
  
  powerManagement.cpuFreqGovernor = "powersave";

  documentation = {
    enable = true;
    dev.enable = true;
    doc.enable = true;
    man.enable = true;
    man.generateCaches = true;
    info.enable = true;
    nixos.enable = true;
    nixos.includeAllModules = true;
  };

  # services.getty.greetingLine = "";
  # services.getty.autologinUser = mainuser;
  
  home-manager = {
    users.${mainuser} = { pkgs, ... }: {
      home = {
        stateVersion = state_version;
        username = mainuser;
        homeDirectory = "/home/${mainuser}";
      };
  
      # home.packages = [ pkgs.atool pkgs.httpie ];
      # programs.bash.enable = true;
      programs.zsh.enable = true;
      programs.git = {
        enable = true;
        # signing.signByDefault = true;
        extraConfig = {
          init = {
            defaultBranch = "main";
          };
        
          filter = {
            lfs = {
              smudge = "git-lfs smudge -- %f";
              process = "git-lfs filter-process";
              required = true;
              clean = "git-lfs clean -- %f";
            };
          };
        
          gpg = {
            format = "ssh";
            ssh = {
              allowedSignersFile = "~/.ssh/allowed_signers";
            };
          };
        
          commit = {
            gpgsign = true;
          };
        
          credential = {
            helper = "libsecret";
            # from the wiki:
            # helper = "${pkgs.git.override { withLibsecret = true; }}/bin/git-credential-libsecret";
          };
        
          log = {
            showSignature = true;
            abbrevCommit = "yes";
            date = "iso8601";
          };
        
          core = {
            abbrev = 8;
          };
        
          diff = {
            submodule = "log";
          };
        };
      };
  
      programs.alacritty = {
        enable = true;
        settings = {
          font = let family = "Iosevka Nerd Font"; in {
            normal = {
              family = family;
              style = "Regular";
            };

            bold = {
              family = family;
              style = "Bold";
            };
          
            italic = {
              family = family;
              style = "Italic";
            };
          
            bold_italic = {
              family = family;
              style = "Bold Italic";
            };
          
            size = 12;

            offset = {
              x = 0;
              y = 1;
            };
          };
          
          colors = {
            primary = {
              background = "0xffffff";
              foreground = "0x586069";
            };
          
            normal = {
              black = "0x1d1f21";
              red = "0xd03d3d";
              green = "0x07962a";
              yellow = "0x949800";
              blue = "0x0451a5";
              magenta = "0xbc05bc";
              cyan = "0x0598bc";
              white = "0xffffff";
            };
          
            bright = {
              black = "0x666666";
              red = "0xcd3131";
              green = "0x14ce14";
              yellow = "0xb5ba00";
              blue = "0x0451a5";
              magenta = "0xbc05bc";
              cyan = "0x0598bc";
              white = "0x586069";
            };
          };
          
          window = {
            opacity = 1;
          };
          
          cursor = {
            style = {
              blinking = "Never";
            };
          };
          
          env = {
            TERM = "alacritty";
          };
        };
      };

      programs.fzf = {
         tmux.enableShellIntegration = true;
      };

      programs.tmux = {
        enable = true;
        extraConfig = ''
          set -g prefix M-space

          # allow sending the prefix to other apps (press twice)
          bind M-space send-prefix
          
          set -g mode-keys vi
          set -g mouse on
          set -g escape-time 0
          set -g history-limit 100000
          
          # Rather than constraining window size to the maximum size of any client
          # connected to the *session*, constrain window size to the maximum size of any
          # client connected to *that window*. Much more reasonable.
          # Combined with using
          #    `tmux new-session -t alreadyExistingSessionName -s newSessionName`
          # we can have two views into the same session viewing different windows
          set -g aggressive-resize on
          
          # set -g default-terminal "tmux-256color"
          set -g default-terminal "alacritty"
          # set -g set-titles off
          # set -g set-titles on
          set -g focus-events on
          
          # set -g status-style fg=darkgrey,dim,bg=black
          set -g status-style fg=black,bg=white
          set -g pane-active-border-style fg=darkgrey
          set -g window-status-current-style fg=black,bold,bg=grey
          set -g message-style fg=yellow,blink,bg=black
          
          # set -gw xterm-keys on # for vim
          # set -gw monitor-activity on
          # set -g terminal-overrides 'xterm*:smcup@:rmcup@'
          
          # status configuration
          # set -g status off
          set -g status-justify left
          set -g status-interval 1
          set -g status-left ""
          set -g status-right '#(date +%Y-%m-%d\ %R)'
          set -g visual-activity off
          
          # 1-indexed window/pane indices:
          set -g base-index 1
          set -g pane-base-index 1
          
          set -g automatic-rename
          
          # TODO: pane switcher with fzf
          bind Space list-panes
          bind Enter break-pane
          
          # jump to last window/pane
          bind -n M-s last-pane
          bind -n M-tab last-window
          
          # jump to last pane if there is another pane, else last window
          bind -n M-u \
            if-shell '[[ "$(tmux list-panes | wc -l)" -gt 1 ]]' \
              'last-pane' \
              'last-window'
          
          # window navigation
          bind -n M-h previous-window
          bind -n M-l next-window
          bind -n M-k previous-window
          bind -n M-j next-window
          
          # pane navigation
          bind h select-pane -L
          bind j select-pane -D
          bind k select-pane -U
          bind l select-pane -R
          bind -n M-H select-pane -L
          bind -n M-J select-pane -D
          bind -n M-K select-pane -U
          bind -n M-L select-pane -R
          
          # pane resizing
          bind -r C-h resize-pane -L
          bind -r C-j resize-pane -D
          bind -r C-k resize-pane -U
          bind -r C-l resize-pane -R
          
          bind -n M-n new-window
          bind -n M-c new-window
          bind -n M-C new-window -c "#{pane_current_path}"
          bind -n M-N new-window -c "#{pane_current_path}"
          # bind -n M-\; command-prompt
          bind -n 'M-;' new-window
          
          bind M-r rotate-window
          bind r source-file $TMUXRC
          unbind d
          bind d kill-pane
          
          
          # toggle status
          bind b set status
          
          # bind F new-window \; send-keys -R "C-l" f Enter
          bind R new-window \; send-keys -R "C-l" r Enter
          bind c new-window
          bind C new-window -c "#{pane_current_path}"
          
          # window splitting
          # bind '%' split-window -v -c "#{pane_current_path}"
          # bind '"' split-window -h -c "#{pane_current_path}"
          bind -n 'M-\' split-window -v -c "#{pane_current_path}"
          bind -n 'M-|' split-window -h -c "#{pane_current_path}"
          
          # bind '&' new-window 'tmux capture-pane -t:- -Jp -S- | nvim -c ":normal G" -'
          # bind -n M-v new-window 'nvim -c ":r !tmux capture-pane -t:- -Jp -S-" -c ":normal G"'
          
          # enter copy mode
          bind -n M-[ copy-mode
          bind 'v' copy-mode
          bind -n M-v copy-mode
          
          # don't copy selection and cancel copy mode on drag end event:
          unbind -T copy-mode-vi MouseDragEnd1Pane
          # mouse scrolling scrolled rows per tick from default 5 to 2
          bind -T copy-mode-vi WheelUpPane send -X -N 2 scroll-up
          bind -T copy-mode-vi WheelDownPane send -X -N 2 scroll-down
          bind -T copy-mode-vi v send -X begin-selection
          bind -T copy-mode-vi r send -X rectangle-toggle
          bind -T copy-mode-vi y send -X copy-pipe
          # bind -T copy-mode-vi y send -X copy-selection
          # bind -T copy-mode-vi Escape send -X cancel
          
          # List of plugins
          set -g @plugin 'tmux-plugins/tpm'
          set -g @plugin 'tmux-plugins/tmux-sensible'
          set -g @plugin 'sainnhe/tmux-fzf'
          
          run '$XDG_CONFIG_HOME/tmux/plugins/tpm/tpm'
        '';
      };
    };

    useGlobalPkgs = true;
    useUserPackages = true;
  };
  
  environment = {
    homeBinInPath = true;
  
    systemPackages = with pkgs; [
      age
      alacritty
      android-studio
      anki-bin
      atool
      audacity
      bitwarden
      bitwarden-cli
      bitwig-studio
      blender
      cargo
      cloc
      cryfs
      czkawka
      desmume
      duf
      easyeffects
      electrum
      exfat
      exfatprogs
      fd
      ffmpeg
      file
      findutils
      firefox
      flashfocus
      font-manager
      fuse3
      fzf
      gcc13
      gh
      ghc
      gimp
      git
      gitAndTools.gitFull
      gnome.ghex
      gnome.gnome-disk-utility
      gnome.gnome-keyring
      gnome.seahorse
      gnome.simple-scan
      gnucash
      gnugrep
      gnumake
      gnused
      gocryptfs
      gparted
      gptfdisk
      gtkwave
      gzip
      helix
      helvetica-neue-lt-std
      htop-vim
      imagemagick
      inetutils
      inkscape
      inter
      iosevka
      jetbrains.idea-community
      jq
      kate
      kdeconnect
      kdenlive
      keepassxc
      kotlin
      krita
      kwave
      lapce
      lazygit
      libreoffice-fresh
      logseq
      maim
      man
      man-pages
      man-pages-posix
      materia-theme
      microcodeIntel
      mixxx
      moreutils
      mpv
      mullvad
      mullvad-browser
      mullvad-vpn
      musescore
      ncdu
      neovim
      nix-zsh-completions
      nixos-option
      nodePackages.pnpm
      nodejs
      noto-fonts
      noto-fonts-emoji
      noto-fonts-emoji
      nsxiv
      obs-studio
      obsidian
      okular
      onlyoffice-bin
      openshot-qt
      openssh
      p7zip
      pamixer
      pass
      passExtensions.pass-otp
      pavucontrol
      pcmanfm
      pdfarranger
      perl
      picom
      podman
      poppler
      powerline
      powerline-fonts
      protonmail-bridge
      pulsemixer
      python311Packages.grip
      python311Packages.pynvim
      python312
      qbittorrent
      qrencode
      ranger
      redshift
      ripgrep-all
      rmlint
      rustc
      shotcut
      signal-desktop
      slack
      spotify
      sshfs
      swift
      sxiv
      syncthing
      syncthingtray
      tectonic
      thunderbird
      tldr
      tmux
      tor-browser-bundle-bin
      trash-cli
      udiskie
      udisks
      unclutter
      unzip
      usbutils
      virtualbox
      vscodium
      wget
      which
      wireplumber
      xclip
      xournalpp
      yt-dlp
      zathura
      ungoogled-chromium
      zip
      zsh
      zsh-completions
      zsh-fzf-tab
      zsh-syntax-highlighting
    ];
  };
}
