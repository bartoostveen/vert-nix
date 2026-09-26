{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  vulkan-loader,
  zstd,
  nix-update-script,
}:

rustPlatform.buildRustPackage {
  pname = "vertd";
  version = "nightly-352463e1ae65a5afd87e250309656f4f2062d76a-unstable-2026-09-25";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "VERT-sh";
    repo = "vertd";
    rev = "24bff68d59c03e24914624ad78f7cc125b4870db";
    hash = "sha256-wXKN22QLH21YGcYGCQ5S9IHW5RvrhZMrnRLVW1pZUf0=";
  };

  cargoHash = "sha256-mcKh+95FYWR6HNAV76j928KHemfsPNMPeQLYB27c4xE=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
    vulkan-loader
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  passthru.updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };

  meta = {
    description = "VERT's solution to crappy video conversion services";
    homepage = "https://github.com/VERT-sh/vertd";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "vertd";
  };
}
