{
  docs,
  stdenv,
  mdbook,
}:

stdenv.mkDerivation {
  pname = "docs";
  version = "unstable";

  src = ./.;

  nativeBuildInputs = [
    mdbook
  ];

  buildPhase = ''
    cp ${docs.optionsCommonMark} src/options.md
    mdbook build
  '';

  installPhase = ''
    cp -r book/ $out
  '';
}
