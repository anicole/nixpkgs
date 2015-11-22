{ stdenv, buildEnv, fetchurl, mono, unzip }:

let
  version = "1.5.4b1";
  drv = stdenv.mkDerivation {
    name = "keefox-${version}";
    src = fetchurl {
      url    = "https://github.com/luckyrat/KeeFox/releases/download/${version}/${version}.xpi";
      sha256 = "b93f1e5c4ad303e65be7054c89d8e10a4e89a3afb97df1d8c3dc1cc573d94dbe";
    };

    meta = {
      description = "Keepass plugin for keefox Firefox add-on";
      homepage = http://keefox.org;
    };

    buildInputs = [ unzip ];

    pluginFilename = "KeePassRPC.plgx";

    unpackCmd = "unzip $src deps/$pluginFilename ";
    sourceRoot = "deps";

    installPhase = ''
      mkdir -p $out/lib/dotnet/keepass/
      cp $pluginFilename $out/lib/dotnet/keepass/$pluginFilename
    '';
  };
in
  # Mono is required to compile plugin at runtime, after loading.
  buildEnv { name = drv.name; paths = [ mono drv ]; }
