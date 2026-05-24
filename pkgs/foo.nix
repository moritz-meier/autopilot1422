{ stdenv, python3 }:
stdenv.mkDerivation {
  name = "foo";
  version = "0.1.0";

  buildInputs = [
    (python3.withPackages (
      pyPkgs: with pyPkgs; [
        pyelftools
        pefile
        pyyaml
      ]
    ))
  ];

  dontUnpack = true;
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp ${../foo.py} $out/bin/foo
    chmod +x $out/bin/foo

    echo "${stdenv.buildPlatform.system} ${stdenv.hostPlatform.system}" > $out/foo.txt

    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup

    patchShebangs $out/bin


    runHook postFixup
  '';
}
