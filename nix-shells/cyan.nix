let lua_version = "5.4"; in
let lua_version_number = if lua_version == "jit" then "5.1" else lua_version; in
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; (if lua_version == "5.1" then
    [ lua5_1 lua51Packages.luarocks ]
  else if lua_version == "jit" then
    [ luajit luajitPackages.luarocks ]
  else if lua_version == "5.2" then
    [ lua5_2 lua52Packages.luarocks ]
  else if lua_version == "5.3" then
    [ lua5_3 lua53Packages.luarocks ]
  else if lua_version == "5.4" then
    [ lua5_4 lua54Packages.luarocks ]
  else [])
    ++
  [
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

    prepend-to-path () {
      export PATH="$1:$PATH"
    }

    prepend-to-lua-path () {
      export LUA_PATH="$1/?.lua;$1/?/init.lua;$LUA_PATH"
    }

    prepend-to-lua-cpath () {
      export LUA_CPATH="$1/?.so;$LUA_CPATH"
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

    prepend-to-path "$HOME/dev/cyan/lua_modules/bin"

  ''
  + "prepend-to-lua-path \"$HOME/dev/cyan/lua_modules/share/lua/" + lua_version_number + "\"\n"
  + "prepend-to-lua-cpath \"$HOME/dev/cyan/lua_modules/lib/lua/" + lua_version_number + "\"\n"
  ;
}
