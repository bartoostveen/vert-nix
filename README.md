# vert-nix

Packages [vert-sh](https://github.com/vert-sh) for Nix(OS).

## Available packages

- [`vertd`](https://github.com/VERT-sh/vertd)
- [`web`](https://github.com/VERT-sh/VERT)

## Usage

```nix
# flake.nix
inputs = {
  vert-nix = {
    url = "git+https://git.bartoostveen.nl/bart/vert-nix.git"; # optionally use `release` branch here
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### NixOS

```nix
{ config, inputs, ... }:

{
  imports = [ inputs.vert-nix.nixosModules.default ];
  services.vert = {
    enable = true;
    hostName = "${config.networking.hostName}.${config.networking.domain}";
    nginx.enable = true;
  };
  networking = {
    hostName = "vert";
    domain = "local";
  };
  system.stateVersion = "26.11";
}
```

## Reference

All docs are available at <https://nix-vert.bartoostveen.nl/> ([unstable](https://test.nix-vert.bartoostveen.nl/)). NixOS options reference is rendered at <https://nix-vert.bartoostveen.nl/options.html> ([unstable](https://test.nix-vert.bartoostveen.nl/options.html)).

## License

This project is licensed under the [unlicense](./LICENSE), go crazy.
