{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  nodejs,
  prefetch-yarn-deps,
  yarn,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "lxd-ui";
  version = "0.8";

  src = fetchFromGitHub {
    owner = "canonical";
    repo = "lxd-ui";
    rev = "refs/tags/${version}";
    hash = "sha256-oD/GPm84oFXHcZ8vTUzNgQinrHwNuvpeVjsrp8ibIZY=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    hash = "sha256-hRZ0vbksxnUv4XMrbhP2PI94UYYzwrydJHSx+uf+MbI=";
  };

  nativeBuildInputs = [
    nodejs
    prefetch-yarn-deps
    yarn
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    yarn config --offline set yarn-offline-mirror "$offlineCache"
    fixup-yarn-lock yarn.lock
    yarn --offline --frozen-lockfile --ignore-platform --ignore-scripts --no-progress --non-interactive install
    patchShebangs node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    yarn --offline build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    cp -r build/ui/ $out

    runHook postInstall
  '';

  passthru.tests.default = nixosTests.lxd.ui;

  meta = {
    description = "Web user interface for LXD";
    homepage = "https://github.com/canonical/lxd-ui";
    license = lib.licenses.gpl3;
    maintainers = lib.teams.lxc.members;
    platforms = lib.platforms.linux;
  };
}
