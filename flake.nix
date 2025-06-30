rec {
  description = "C++ Brainfuck Interpreter";

  inputs = {
    nixpkgs.url = "nixpkgs"; # Use nixpkgs from system registry
    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
  # Create a shell (and possibly package) for each possible system, not only x86_64-linux
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          rust-overlay.overlays.default
        ];
      };
      inherit (pkgs) lib stdenv;

      # ===========================================================================================
      # Define custom dependencies
      # ===========================================================================================

      python = pkgs.python313.withPackages (p:
        with p; [
          pyside6
          ffmpeg-python
          matplotlib
          numpy
        ]);

      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = ["rust-src"]; # Include the Rust stdlib source (for IntelliJ)
      };

      # 64 bit C/C++ compilers that don't collide (use the same libc)
      bintools = pkgs.wrapBintoolsWith {
        bintools = pkgs.bintools.bintools; # Unwrapped bintools
        libc = pkgs.glibc;
      };
      gcc = pkgs.hiPrio (pkgs.wrapCCWith {
        cc = pkgs.gcc.cc; # Unwrapped gcc
        libc = pkgs.glibc;
        bintools = bintools;
      });
      clang = pkgs.wrapCCWith {
        cc = pkgs.clang.cc; # Unwrapped clang
        libc = pkgs.glibc;
        bintools = bintools;
      };

      # Multilib C/C++ compilers that don't collide (use the same libc)
      bintools_multilib = pkgs.wrapBintoolsWith {
        bintools = pkgs.bintools.bintools; # Unwrapped bintools
        libc = pkgs.glibc_multi;
      };
      gcc_multilib = pkgs.hiPrio (pkgs.wrapCCWith {
        cc = pkgs.gcc.cc; # Unwrapped gcc
        libc = pkgs.glibc_multi;
        bintools = bintools_multilib;
      });
      clang_multilib = pkgs.wrapCCWith {
        cc = pkgs.clang.cc; # Unwrapped clang
        libc = pkgs.glibc_multi;
        bintools = bintools_multilib;
      };

      # ===========================================================================================
      # Specify dependencies
      # https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-dependencies-overview
      # Just for a "nix develop" shell, buildInputs can be used for everything.
      # ===========================================================================================

      # Add dependencies to nativeBuildInputs if they are executed during the build:
      # - Those which are needed on $PATH during the build, for example cmake and pkg-config
      # - Setup hooks, for example makeWrapper
      # - Interpreters needed by patchShebangs for build scripts (with the --build flag), which can be the case for e.g. perl
      nativeBuildInputs = with pkgs; [
        # Languages:
        # python
        # rust
        bintools
        gcc
        clang
        # bintools_multilib
        # gcc_multilib
        # clang_multilib

        # C/C++:
        gdb
        valgrind
        gnumake
        cmake
        # pkg-config

        # Qt:
        # qt6.wrapQtAppsHook # For the shellHook
      ];

      # Add dependencies to buildInputs if they will end up copied or linked into the final output or otherwise used at runtime:
      # - Libraries used by compilers, for example zlib
      # - Interpreters needed by patchShebangs for scripts which are installed, which can be the case for e.g. perl
      buildInputs = with pkgs; [
        # C/C++:
        # boost
        # sfml

        # Qt:
        # qt6.qtbase
        # qt6.full
      ];

      # ===========================================================================================
      # Define buildable + installable packages
      # ===========================================================================================

      package = stdenv.mkDerivation {
        inherit nativeBuildInputs buildInputs;
        pname = "bfuck";
        version = "1.0.0";
        src = ./.;

        installPhase = ''
          mkdir -p $out/bin
          mv ./bfuck $out/bin
        '';
      };
    in rec {
      # Provide package for "nix build"
      defaultPackage = package;
      defaultApp = flake-utils.lib.mkApp {
        drv = defaultPackage;
      };

      # Provide environment for "nix develop"
      devShell = pkgs.mkShell {
        inherit nativeBuildInputs buildInputs;
        name = description;

        # =========================================================================================
        # Define environment variables
        # =========================================================================================

        # Rust stdlib source:
        # RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";

        # Custom dynamic libraries:
        # LD_LIBRARY_PATH = builtins.concatStringsSep ":" [
        #   # Rust Bevy GUI app
        #   "${pkgs.xorg.libX11}/lib"
        #   "${pkgs.xorg.libXcursor}/lib"
        #   "${pkgs.xorg.libXrandr}/lib"
        #   "${pkgs.xorg.libXi}/lib"
        #   "${pkgs.libGL}/lib"
        # ];

        # Dynamic libraries from buildinputs:
        # LD_LIBRARY_PATH = nixpkgs.lib.makeLibraryPath buildInputs;

        # =========================================================================================
        # Define shell environment
        # =========================================================================================

        # Setup the shell when entering the "nix develop" environment (bash script).
        shellHook = let
          mkCmakeScript = type: let
            typeLower = lib.toLower type;
          in
            pkgs.writers.writeFish "cmake-${typeLower}.fish" ''
              cd $FLAKE_PROJECT_ROOT

              echo "Removing build directory ./cmake-build-${typeLower}/"
              rm -rf ./cmake-build-${typeLower}

              echo "Creating build directory"
              mkdir cmake-build-${typeLower}
              cd cmake-build-${typeLower}

              echo "Running cmake"
              cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE="${type}" -DCMAKE_EXPORT_COMPILE_COMMANDS="On" ..

              echo "Linking compile_commands.json"
              cd ..
              ln -sf ./cmake-build-${typeLower}/compile_commands.json ./compile_commands.json
            '';

          cmakeDebug = mkCmakeScript "Debug";
          cmakeRelease = mkCmakeScript "Release";

          mkBuildScript = type: let
            typeLower = lib.toLower type;
          in
            pkgs.writers.writeFish "cmake-build.fish" ''
              cd $FLAKE_PROJECT_ROOT/cmake-build-${typeLower}

              echo "Running cmake"
              cmake --build .
            '';

          buildDebug = mkBuildScript "Debug";
          buildRelease = mkBuildScript "Release";

          # Use this to specify commands that should be ran after entering fish shell
          initProjectShell = pkgs.writers.writeFish "init-shell.fish" ''
            echo "Entering \"${description}\" environment..."

            # Determine the project root, used e.g. in cmake scripts
            set -g -x FLAKE_PROJECT_ROOT (git rev-parse --show-toplevel)

            # Build the provided NixOS package
            abbr -a build "nix build -L"

            # Rust Bevy:
            # abbr -a build-release-windows "CARGO_FEATURE_PURE=1 cargo xwin build --release --target x86_64-pc-windows-msvc"

            # C/C++:
            abbr -a cmake-debug "${cmakeDebug}"
            abbr -a cmake-release "${cmakeRelease}"
            abbr -a build-debug "${buildDebug}"
            abbr -a build-release "${buildRelease}"
          '';
        in
          builtins.concatStringsSep "\n" [
            # Launch into pure fish shell
            ''
              exec "$(type -p fish)" -C "source ${initProjectShell} && abbr -a menu '${pkgs.bat}/bin/bat "${initProjectShell}"'"
            ''

            # Qt: Launch into wrapped fish shell
            # ''
            #   fishdir=$(mktemp -d)
            #   makeWrapper "$(type -p fish)" "$fishdir/fish" "''${qtWrapperArgs[@]}"
            #   exec "$fishdir/fish" -C "source ${initProjectShell} && abbr -a menu '${pkgs.bat}/bin/bat "${initProjectShell}"'"
            # ''
          ];
      };
    });
}
