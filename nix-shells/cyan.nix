{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    # TODO: make this configurable?
    # lua5_1
    # lua51Packages.luarocks

    # luajit
    # luajitPackages.luarocks

    # lua5_2
    # lua52Packages.luarocks

    # lua5_3
    # lua53Packages.luarocks

    lua5_4
    lua54Packages.luarocks

    gcc
    glibc
    gnumake
    gdb
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
    append-to-lua-path "$HOME/dev/cyan/build"
    append-to-lua-path "$HOME/dev/cyan/src"
    append-to-path "$HOME/dev/cyan/bin"

    prepend-to-path "$HOME/dev/cyan/lua_modules/bin"
    prepend-to-lua-path "$HOME/dev/cyan/lua_modules/share/lua/5.4"
    prepend-to-lua-cpath "$HOME/dev/cyan/lua_modules/lib/lua/5.4"

    append-to-lua-cpath "$HOME/.cache/tree-sitter/lib"
  '';
}
