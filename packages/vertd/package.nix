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
  version = "nightly-e50ad616c122b4f2bac7ea813677b56f4670fb06-unstable-2026-10-04";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "VERT-sh";
    repo = "vertd";
    rev = "e50ad616c122b4f2bac7ea813677b56f4670fb06";
    hash = "sha256-ssQQCNRRo3qZSPXVCMV7OGhRNOSr7jlqNMophVDF5M0=";
  };

  cargoHash = "sha256-SQswnq35oChsFvUNaovmKq0QDlnh7RCsGge/4EKdBoY=";

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
