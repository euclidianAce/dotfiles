{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    lua5_3
    lua53Packages.argparse
    lua53Packages.luafilesystem
  ];
  shellHook = ''
    append-to-path () {
      export PATH="$PATH:$1"
    }

    append-to-lua-path () {
      export LUA_PATH="$LUA_PATH;$1/?.lua;$1/?/init.lua"
    }

    append-to-lua-cpath () {
      export LUA_CPATH="$LUA_CPATH;$1/?.so"
    }

    for f in $HOME/dev/teal-types/types/*; do
      append-to-lua-path "$f"
    done

    append-to-path "$HOME/dev/tl"
    append-to-lua-path "$HOME/dev/tl"

    append-to-path "$HOME/dev/cyan/bin"
    append-to-lua-path "$HOME/dev/cyan/build"
    append-to-lua-path "$HOME/dev/cyan/src"
  '';
}
