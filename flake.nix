{
  description = "C/C++ Environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.devshell.url = "github:numtide/devshell";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    devshell,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # For clion
        overlays = [devshell.overlays.default];
      };

      # NOTE: Usual 64 bit compilers that don't collide
      bintools = pkgs.wrapBintoolsWith {
        bintools = pkgs.bintools.bintools;
        libc = pkgs.glibc;
      };
      gcc13 = pkgs.hiPrio (pkgs.wrapCCWith {
        cc = pkgs.gcc13.cc;
        libc = pkgs.glibc;
        bintools = bintools;
      });
      clang16 = pkgs.wrapCCWith {
        cc = pkgs.clang_16.cc;
        libc = pkgs.glibc;
        bintools = bintools;
      };

      # NOTE: Multilib compilers that don't collide
      bintools_multi = pkgs.wrapBintoolsWith {
        bintools = pkgs.bintools.bintools; # Get the unwrapped bintools from the wrapper
        libc = pkgs.glibc_multi;
      };
      gcc13_multi = pkgs.hiPrio (pkgs.wrapCCWith {
        cc = pkgs.gcc13.cc; # Get the unwrapped gcc from the wrapper
        libc = pkgs.glibc_multi;
        bintools = bintools_multi;
      });
      clang16_multi = pkgs.wrapCCWith {
        cc = pkgs.clang_16.cc;
        libc = pkgs.glibc_multi;
        bintools = bintools_multi;
      };
    in {
      # devShell = pkgs.devshell.mkShell ...
      devShell = pkgs.devshell.mkShell {
        name = "C/C++ Environment";

        packages = with pkgs; [
          # Compilers
          bintools
          gcc13
          clang16
          # bintools_multi
          # gcc13_multi
          # clang15_multi

          # Native buildinputs
          gnumake
          cmake
          # nasm

          # Development
          # bear # To generate compilation database
          gdb
          cling # To try out my bullshit implementations
          clang-tools_18
          # doxygen # Generate docs + graphs
        ];

        commands = [
          # {
          #   name = "ide";
          #   help = "Run clion for project";
          #   command = "clion &>/dev/null ./ &";
          # }
        ];
      };
    });
}
