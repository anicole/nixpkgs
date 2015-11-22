{ stdenv, lib, keepass, makeWrapper, plugins }:

# KeePass looks for plugins in under directory in which KeePass.exe is
# located. It follows symlinks where looking for that directory, so
# buildEnv is not enough to bring KeePass and plugins together.
#
# This derivation patches KeePass to search for plugins in specified
# plugin derivations in the Nix store and nowhere else.
let
# Create patch inline and make sure CRLF is used. Note: removes
# default behaviour, and no plugins will be loaded unless passed into
# derivation.
lc = builtins.add 8 (builtins.length plugins);
pluginPathsPatch = builtins.replaceStrings ["\n"] ["\r\n"] (lib.concatStrings [
"--- old/KeePass/Forms/MainForm.cs
+++ new/KeePass/Forms/MainForm.cs
@@ -384,9 +384," (builtins.toString lc) " @@ namespace KeePass.Forms
 			m_pluginManager.Initialize(m_pluginDefaultHost);
 " "
 			m_pluginManager.UnloadAllPlugins();
-			if(AppPolicy.Current.Plugins)
-				m_pluginManager.LoadAllPlugins(UrlUtil.GetFileDirectory(
-					WinUtil.GetExecutable(), false, true));
+			if(AppPolicy.Current.Plugins) {"
(lib.concatStrings (map (p:
"
+				m_pluginManager.LoadAllPlugins(\"" + builtins.toString p + "/lib/dotnet/keepass\");"
) plugins))
"
+			}
 " "
 			// Delete old files *after* loading plugins (when timestamps
 			// of loaded plugins have been updated already)
"]);
in
  stdenv.lib.overrideDerivation keepass (x : {
    name = "keepass-with-plugins-" + (builtins.parseDrvName x.name).version;

    buildInputs = x.buildInputs ++ [ makeWrapper ];

    patchFile = pluginPathsPatch;
    passAsFile = [ "patchFile" ];
    postPatch = ''
      patch --binary -p1 < $patchFilePath
    '';

    # plgx plugin like keefox requires mono to compile at runtime
    # after loading. It is brought into plugins bin/ directory using
    # buildEnv in the plugin derivation. Wrapper below makes sure it
    # is found and does not pollute output path.
    binPaths = lib.concatStrings (lib.intersperse ":" (map (x: x + "/bin") plugins));
    postInstall =
      x.postInstall + ''
        wrapProgram $out/bin/keepass --prefix PATH : "$binPaths"
      '';
  })
