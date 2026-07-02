{
  description = "vert-sh for nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, lib, ... }:

      let
        inherit (lib) getExe;
      in
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ];

        imports = [
          inputs.treefmt-nix.flakeModule
        ];

        flake = {
          nixosConfigurations.vm = withSystem "x86_64-linux" (
            { pkgs, system, ... }:

            inputs.nixpkgs.lib.nixosSystem {
              inherit pkgs system;
              modules = [
                self.nixosModules.default
                ./example.nix
                "${inputs.nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
                {
                  services.getty.autologinUser = "root";
                  virtualisation = {
                    forwardPorts = [
                      {
                        from = "host";
                        host.port = 8080;
                        guest.port = 80;
                      }
                    ];
                  };
                }
              ];
            }
          );

          nixosModules.default = ./module.nix;
          overlays.default =
            _final: prev:
            withSystem prev.stdenv.hostPlatform.system (
              { self', ... }: {
                vert = self'.packages;
              }
            );
        };

        perSystem =
          {
            pkgs,
            system,
            ...
          }:

          let
            docs = pkgs.nixosOptionsDoc {
              options.services.vert =
                (inputs.nixpkgs.lib.nixosSystem {
                  inherit pkgs system;
                  modules = [
                    self.nixosModules.default
                    { system.stateVersion = "26.11"; }
                  ];
                }).options.services.vert;
            };
          in
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.bun2nix.overlays.default
                self.overlays.default
              ];
            };

            apps.run-in-vm = {
              type = "app";
              program = getExe self.nixosConfigurations.vm.config.system.build.vm;
            };

            treefmt = {
              programs.nixfmt.enable = true;
              programs.deadnix = {
                enable = true;
                excludes = [ "**/*/bun.nix" ];
              };
            };

            packages = {
              _docs = pkgs.callPackage ./docs/package.nix { inherit docs; };
              web = pkgs.callPackage ./packages/web/package.nix { };
              vertd = pkgs.callPackage ./packages/vertd/package.nix { };
            };

            checks.module = pkgs.testers.runNixOSTest {
              name = "vertd";

              nodes.machine = {
                imports = [
                  self.nixosModules.default
                  ./example.nix
                ];
              };

              # TODO: test if API works with ffmpeg and such
              testScript = ''
                start_all()
                with subtest("start vertd"):
                  machine.wait_for_unit("vertd.service")
                  machine.wait_for_open_port(24153)
              '';
            };
          };
      }
    );
}
