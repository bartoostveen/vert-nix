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
  version = "nightly-352463e1ae65a5afd87e250309656f4f2062d76a-unstable-2026-09-11";

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "VERT-sh";
    repo = "vertd";
    rev = "e94eca2b47237d4e1d698b3bd1162111edcd45c6";
    hash = "sha256-/ksPeJ5ZdPBVTvxgK0B9aEPmHkBDbyCSn1Zjc8uUq/0=";
  };

  cargoHash = "sha256-QTZDoOiRBYfhqvU2/U730kRq2O8DNhjA+qlcbqWITZU=";

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
