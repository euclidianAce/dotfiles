
local snippet = require("euclidian.lib.snippet")
local a = vim.api

local function getCommentFstring(buf)
   local commentString = a.nvim_buf_get_option(buf, "commentstring")
   local fstring = commentString .. "\n" .. commentString



   local parts = vim.split(commentString, "%s", true)
   local trail = (not parts[2] or #parts[2] == 0) and "" or " "

   return fstring, trail
end
snippet.create("todo", function(buf)
   local fstring, trail = getCommentFstring(buf)
   return fstring:format(
" TODO: " .. vim.fn.strftime("%b %d %H:%M %Y") .. trail,
"       %1" .. trail)

end)
snippet.create("fix", function(buf)
   local fstring, trail = getCommentFstring(buf)
   return fstring:format(
" FIXME: " .. vim.fn.strftime("%b %d %H:%M %Y") .. trail,
"        %1" .. trail)

end)

local snip = snippet.ftCreate
local lua_teal = { "lua", "teal" }

snip(lua_teal, "for", 'for %1 = %2, %3 do\n\nend', { "i", "1", "10" })
snip(lua_teal, "pairs", 'for %1, %2 in pairs(%3) do\n\nend', { "k", "v", "{}" })
snip(lua_teal, "ipairs", 'for %1, %2 in ipairs(%3) do\n\nend', { "i", "v", "{}" })


snip(lua_teal, "it", 'it("%1", function()\n\nend)')
snip(lua_teal, "desc", 'describe("%1", function()\n\nend)')
snip(lua_teal, "pend", 'pending("%1", function()\n\nend)')


snip("lua", "req,", 'local %1 = require("%1")')
snip("lua", "req.", 'local %1 = require("%2")')
snip("lua", "module", 'local %1 = {}\n\nreturn %1')
snip("lua", "func", 'function %1(%2)\n\nend')
snip("lua", "lfunc", 'local function %1(%2)\n\nend')

snip("teal", "req,", 'local %1 <const> = require("%1")')
snip("teal", "req.", 'local %1 <const> = require("%2")')
snip("teal", "module", 'local %1 <const> = {}\n\nreturn %1')
snip("teal", "func", 'function %1(%2): %3\n\nend')
snip("teal", "lfunc", 'local function %1(%2)%3\n\nend')
snip("teal", "gfunc", 'global function %1(%2)%3\n\nend')
snip("teal", "const", 'local %1 <const> = %2')
snip("teal", "tconst", 'local %1 <const>: %2 = %3')

snip("c", "inc", '#include <%1>')
snip("c", "linc", '#include "%1"')
snip("c", "main", 'int main(void) {\nreturn 0;\n}')
snip("c", "fmain", 'int main(int argc, char **argv) {\n\treturn 0;\n}')
snip("c", "func", '%1 %2(%3) {\n\n}')
