{ pkgs ? import <nixpkgs> { } }:

let
  json-lua = pkgs.luajit.pkgs.buildLuaPackage {
    pname = "json-lua";
    version = "0.1.2";
    src = pkgs.fetchFromGitHub {
      owner = "rxi";
      repo = "json.lua";
      rev = "v0.1.2";
      hash = "sha256-JSKMxF5NSHW3QaELFPWm1sx7kHmOXEPsUkM3i/px7Gk=";
    };
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 json.lua $out/share/lua/${pkgs.luajit.luaversion}/json.lua
      runHook postInstall
    '';
  };

  lua = pkgs.luajit.withPackages (p: [ p.busted p.penlight json-lua ]);
in pkgs.mkShell {
  buildInputs = [ pkgs.curl pkgs.libuv lua pkgs.lua-language-server ];

  # Optional: Set up environment variables for Lua
  # LUA_PATH = "${lua}/share/lua/${pkgs.lib.getVersion lua}/?.lua;;";
  # LUA_CPATH = "${lua}/lib/lua/${pkgs.lib.getVersion lua}/?.so;;";

  shellHook = ''
    export DYLD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.curl
      pkgs.libuv
    ]}:$DYLD_LIBRARY_PATH"
    echo "Using LuaJIT version: $(luajit -v) with lib path: $DYLD_LIBRARY_PATH"
  '';
}
