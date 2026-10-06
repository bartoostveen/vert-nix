{
  bun2nix,
  lib,
  makeWrapper,
  nix-update-script,
  fetchFromGitHub,
  writeText,
  env ? { },
  ...
}:

let
  inherit (lib)
    mapAttrsToList
    recursiveUpdate
    concatStringsSep
    pipe
    ;

  finalEnv = recursiveUpdate {
    HOSTNAME = "localhost";
    PLAUSIBLE_URL = "";
    ENV = "production";
    VERTD_URL = "https://vertd.vert.sh";
    DISABLE_ALL_EXTERNAL_REQUESTS = "false";
    DISABLE_FAILURE_BLOCKS = "false";
    DONATION_URL = "https://donations.vert.sh";
    STRIPE_KEY = "pk_live_51TlrPaFTPjkhEGBSu5Kwy5jJQYxcX5yUUHXiH5g7Xzvb0NKzDqbooc126HjlW35uUkfAgQN2ruEoCuyQynoxpKaA00ojFgQ116";
  } env;

  envFile = pipe finalEnv [
    (mapAttrsToList (k: v: "PUB_${k}=${v}"))
    (concatStringsSep "\n")
    (writeText "vert.env")
  ];
in
bun2nix.mkDerivation (finalAttrs: {
  pname = "vert";
  version = "0-unstable-2026-10-06";

  src = fetchFromGitHub {
    owner = "VERT-sh";
    repo = "VERT";
    rev = "07a3c67445fdf134f0a575fda518d4ec67186506";
    hash = "sha256-aFW4HdCooG7hGUMWv6Wj/zv4KLkSzzk8jxb7evTsijg=";
  };

  patches = [ ./bun.lock.patch ];

  packageJson = "${finalAttrs.src}/package.json";

  __structuredAttrs = true;
  strictDeps = true;

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
    useFakeNode = false;
  };

  prePatch = ''
    cp ${envFile} .env
  '';

  nativeBuildInputs = [
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r build $out/
    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script { extraArgs = [ "--version=branch=main" ]; };
    inherit envFile;
  };

  meta = {
    description = "The next-generation file converter. Open source, fully local* and free forever";
    homepage = "https://github.com/VERT-sh/VERT";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ bartoostveen ];
    platforms = lib.platforms.all;
  };
})
