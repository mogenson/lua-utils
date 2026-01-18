{ pkgs ? import <nixpkgs> { } }:

let
  pl-definitions = pkgs.fetchFromGitHub {
    owner = "goldenstein64";
    repo = "pl-definitions";
    rev = "bb653648e5f15eb5a69587ecacb8e7b671e0d258";
    sha256 = "0nwsy2a4vfh3159klr645f0dn7pvbh4xs5dzy8v2ac9zhl3s2vlh";
  };

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

    ln -sf ${pl-definitions}/library/pl definitions/

    echo "Using LuaJIT version: $(luajit -v) with lib path: $DYLD_LIBRARY_PATH"
  '';
}
