{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  vulkan-loader,
  zstd,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vertd";
  version = "1.0";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "VERT-sh";
    repo = "vertd";
    tag = finalAttrs.version;
    hash = "sha256-ECUNUzmrVKbu5+37Wyn2KKqr/0t4serUOTZVPw0orTs=";
  };

  cargoHash = "sha256-jEu3tjo7w/gP1zjNpvfI1W1/wgvjsjzfgqKLzQh2jIo=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    vulkan-loader
    zstd
  ];

  env = {
    ZSTD_SYS_USE_PKG_CONFIG = true;
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "VERT's solution to crappy video conversion services";
    homepage = "https://github.com/VERT-sh/vertd";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    mainProgram = "vertd";
  };
})
