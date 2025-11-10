{ pkgs ? import <nixpkgs> { } }:

let lua = pkgs.luajit.withPackages (p: [ p.busted p.penlight ]);
in pkgs.mkShell {
  buildInputs = [ pkgs.curl pkgs.libuv lua ];

  # Optional: Set up environment variables for Lua
  # LUA_PATH = "${lua}/share/lua/${pkgs.lib.getVersion lua}/?.lua;;";
  # LUA_CPATH = "${lua}/lib/lua/${pkgs.lib.getVersion lua}/?.so;;";

  shellHook = ''
    echo "LuaJIT version: $(luajit -v)"
  '';
}
