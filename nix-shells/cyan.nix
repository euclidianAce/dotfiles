{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # TODO: make this configurable?
    # lua5_1
    # lua51Packages.argparse
    # lua51Packages.luafilesystem
    # lua51Packages.busted
    # lua51Packages.inspect
    # lua51Packages.compat53

    lua5_3
    lua53Packages.argparse
    lua53Packages.luafilesystem
    lua53Packages.busted
    lua53Packages.compat53
    lua53Packages.inspect

    tree-sitter
  ];
  shellHook = ''
    append-to-path () {
      export PATH="$PATH:$1"
    }

    prepend-to-lua-path () {
      export LUA_PATH="$1/?.lua;$1/?/init.lua;$LUA_PATH"
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

    append-to-lua-path "$HOME/dev/ltreesitter"
    append-to-lua-cpath "$HOME/dev/ltreesitter"
    append-to-lua-cpath "$HOME/dev/tree-sitter-teal"
    append-to-path "$HOME/dev/cyan/bin"
    append-to-lua-path "$HOME/dev/cyan/build"
    append-to-lua-path "$HOME/dev/cyan/src"

    prepend-to-lua-path "./"
  '';
}
