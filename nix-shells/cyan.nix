{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # TODO: make this configurable?
    # lua5_1
    # lua51Packages.luasystem
    # lua51Packages.argparse
    # lua51Packages.luafilesystem
    # lua51Packages.busted
    # lua51Packages.inspect
    # lua51Packages.compat53

    # luajit
    # luajitPackages.luasystem
    # luajitPackages.argparse
    # luajitPackages.luafilesystem
    # luajitPackages.busted
    # luajitPackages.inspect
    # luajitPackages.compat53

    # lua5_2
    # lua52Packages.luasystem
    # lua52Packages.argparse
    # lua52Packages.luafilesystem
    # lua52Packages.busted
    # lua52Packages.compat53
    # lua52Packages.inspect

    # lua5_3
    # lua53Packages.luasystem
    # lua53Packages.luarocks
    # lua53Packages.argparse
    # lua53Packages.luafilesystem
    # lua53Packages.busted
    # lua53Packages.compat53
    # lua53Packages.inspect

    lua5_4
    lua54Packages.luasystem
    lua54Packages.luarocks
    lua54Packages.argparse
    lua54Packages.luafilesystem
    lua54Packages.busted
    lua54Packages.compat53
    lua54Packages.inspect

    gcc
    glibc
    gnumake
    gdb
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
    append-to-lua-path "$HOME/dev/cyan/build"
    append-to-lua-path "$HOME/dev/cyan/src"
    append-to-path "$HOME/dev/cyan/bin"

    append-to-lua-cpath "$HOME/.cache/tree-sitter/lib"

    prepend-to-lua-path "."
  '';
}
