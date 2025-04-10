// take arguments and print them in boxes

// example
//
// input:
//    ./prompt foo bar
//
// output:
//       ┌───┬───┐
//    ┌──┤foo│bar├─ ... ──┤
//    │  └───┴───┘
//    └┤$
//

//
// ```bash
// export PS2=" \[\e[90m\]│\[\e[0m\]  "
// update_ps1 () {
//         local last_exit_code="$?"
//         local working_directory="$PWD"
//         if [[ "$working_directory" =~ ^$HOME(.*) ]]; then
//                 working_directory="~${BASH_REMATCH[1]}"
//         fi
//         PS1=$($DOTFILE_DIR/prompt \
//                 $([[ $last_exit_code == '0' ]] || echo "attr=red $last_exit_code") \
//                 attr=gray "$(date '+%I:%M:%S %p')" \
//                 attr=red "$USER@$(hostname)" \
//                 attr=blue $working_directory \
//                 attr=bright_green "$(git branch --show-current 2>/dev/null)")
// }
// update_ps1
// PROMPT_COMMAND=update_ps1
// ```
//

const attribute_marker = "attr=";
const pad_marker = "pad=";
const line_color_marker = "line_color=";
const prompt_marker = "prompt=";
const prompt_color_marker = "prompt_color=";

var line_color = Attribute.cyan;
var prompt_str: []const u8 = "$ ";
var prompt_color = Attribute.magenta;

var stdout: std.fs.File.Writer = undefined;
pub fn main() void {
    stdout = std.io.getStdOut().writer();
    parseArguments() catch return;
    stdout.writeAll(begin_synchronized_update) catch {};
    defer stdout.writeAll(end_synchronized_update) catch {};
    printComponents() catch return;
}

// returns the rest
inline fn startsWith(haystack: []const u8, needle: []const u8) ?[]const u8 {
    return if (std.mem.startsWith(u8, haystack, needle))
        haystack[needle.len..]
    else
        null;
}

fn parseArguments() !void {
    var it = try std.process.ArgIterator.initWithAllocator(std.heap.page_allocator);
    // @Leak: defer it.deinit();
    //    this is the only "allocation" (read: Windows is annoying) we do, and we just dump some stuff to stdout
    //    who cares?

    if (!it.skip())
        return;

    var attr: Attribute = .none;
    var pad: usize = 0;

    while (it.next()) |arg| {
        if (startsWith(arg, attribute_marker)) |a| attr: {
            attr = Attribute.parse(a) orelse break :attr;
            continue;
        }
        if (startsWith(arg, pad_marker)) |int| pad: {
            pad = std.fmt.parseInt(usize, int, 10) catch break :pad;
            continue;
        }
        if (startsWith(arg, line_color_marker)) |a| attr: {
            line_color = Attribute.parse(a) orelse break :attr;
            continue;
        }
        if (startsWith(arg, prompt_color_marker)) |a| attr: {
            prompt_color = Attribute.parse(a) orelse break :attr;
            continue;
        }
        if (startsWith(arg, prompt_marker)) |a| {
            prompt_str = a;
            continue;
        }

        try static.newComponent(arg, attr, pad);
        attr = .none;
        pad = 0;
    }
}

fn printPrompt(writer: anytype) !void {
    try prompt_color.write(writer);
    try writer.writeAll(prompt_str);
    try Attribute.none.write(writer);
}

fn getTerminalWidth() ?usize {
    var winsize: std.posix.winsize = undefined;
    const err = std.posix.system.ioctl(std.posix.STDIN_FILENO, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
    return if (std.posix.errno(err) == .SUCCESS)
        winsize.col
    else
        null;
}

// Terminal synchronized output
// https://gist.github.com/christianparpart/d8a62cc1ab659194337d73e399004036
// TODO: is it worth testing for support?
const begin_synchronized_update = "\x1b[?2026h";
const end_synchronized_update = "\x1b[?2026l";

fn printComponents() !void {
    const components = static.components.slice();

    if (components.len == 0) {
        try printPrompt(stdout);
        return;
    }

    // top line
    try stdout.writeAll("   ");
    try line_color.write(stdout);
    try stdout.writeAll(box.top_left);
    for (components, 0..) |component, i| {
        if (i > 0) try stdout.writeAll(box.down);
        try stdout.writeBytesNTimes(box.horizontal, component.width());
    }
    try stdout.writeAll(box.top_right ++ "\n");

    // middle, component contents
    {
        const terminal_width = getTerminalWidth() orelse 0;
        var remaining_width: usize = terminal_width;

        try stdout.writeAll(box.top_left ++ box.horizontal ** 2 ++ box.left);
        remaining_width -|= 4;

        const padding = 3;

        for (components, 0..) |component, i| {
            const width = component.width();
            if (remaining_width -| width < padding)
                break;
            if (i > 0) {
                try line_color.write(stdout);
                try stdout.writeAll(box.vertical);
                remaining_width -|= 1;
            }
            try component.write(stdout);
            remaining_width -|= width;
        }
        try line_color.write(stdout);

        if (remaining_width >= padding) {
            try stdout.writeAll(box.right);
            try stdout.writeBytesNTimes(box.horizontal, remaining_width - padding);
            try stdout.writeAll(box.left ++ "\n");
        } else {
            try stdout.writeAll(box.vertical ++ "\n");
        }
    }

    // bottom line
    try stdout.writeAll(box.vertical ++ "  " ++ box.bottom_left);
    for (components, 0..) |component, i| {
        if (i > 0) {
            try line_color.write(stdout);
            try stdout.writeAll(box.up);
        }
        try stdout.writeBytesNTimes(box.horizontal, component.width());
    }
    try stdout.writeAll(box.bottom_right ++ "\n");

    try stdout.writeAll(box.bottom_left ++ box.left);
    try printPrompt(stdout);
}

const Component = struct {
    attribute: Attribute,
    padding: usize,
    contents: []const u8,

    pub fn width(self: @This()) usize {
        const content_width = wcwidth.utf8Width(self.contents);
        return if (content_width < self.padding)
            self.padding
        else
            content_width;
    }

    fn neededSpaces(self: @This()) usize {
        const content_width = wcwidth.utf8Width(self.contents);
        return if (content_width < self.padding)
            self.padding - content_width
        else
            0;
    }

    pub fn write(self: @This(), writer: anytype) !void {
        try self.attribute.write(writer);
        try writer.writeAll(self.contents);
        try writer.writeByteNTimes(' ', self.neededSpaces());
    }
};

const max_components = 16;
const max_component_length = 64;

const static = struct {
    var components = std.BoundedArray(Component, max_components){};
    var bytes = std.BoundedArray(u8, max_components * max_component_length){};

    pub fn copyBytes(source: []const u8) Oom![]u8 {
        const dest = try allocBytes(source.len);
        @memcpy(dest, source);
        return dest;
    }

    pub fn allocBytes(n: usize) Oom![]u8 {
        var slice = bytes.unusedCapacitySlice();
        if (slice.len < n)
            return oom;
        bytes.len += @truncate(n);
        return slice[0..n];
    }

    pub fn newComponent(contents: []const u8, attribute: Attribute, padding: usize) Oom!void {
        if (contents.len == 0)
            return;
        const component = components.addOne() catch return oom;
        component.* = .{
            .contents = try copyBytes(contents),
            .padding = padding,
            .attribute = attribute,
        };
    }
};

const Oom = std.mem.Allocator.Error;
const oom = Oom.OutOfMemory;

const Attribute = enum(u8) {
    none = 0,
    bold = 1,

    red = 31,
    green = 32,
    yellow = 33,
    blue = 34,
    magenta = 35,
    cyan = 36,
    gray = 37,

    bright_red = 91,
    bright_green = 92,
    bright_yellow = 93,
    bright_blue = 94,
    bright_magenta = 95,
    bright_cyan = 96,
    bright_gray = 97,

    pub inline fn write(self: @This(), writer: anytype) !void {
        try writer.print("\x1b[{}m", .{@intFromEnum(self)});
    }

    pub fn parse(str: []const u8) ?@This() {
        return std.meta.stringToEnum(Attribute, str);
    }
};

const box = struct {
    pub const horizontal = "─";
    pub const vertical = "│";
    pub const top_left = "┌";
    pub const top_right = "┐";
    pub const bottom_left = "└";
    pub const bottom_right = "┘";
    pub const up = "┴";
    pub const down = "┬";
    pub const left = "┤";
    pub const right = "├";
};

const std = @import("std");
const builtin = @import("builtin");

const wcwidth = struct {
    // Ported from Markus Kuhn's wcwidth.c
    // which can be found here: http://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c

    const Codepoint = u32;
    const Interval = struct { Codepoint, Codepoint };

    fn find(ucs: Codepoint, table: []const Interval) bool {
        var max: usize = table.len - 1;
        var min: usize = 0;
        var mid: usize = 0;

        if (ucs < table[0][0] or ucs > table[max][1])
            return false;
        while (max >= min) {
            mid = (min + max) / 2;
            if (ucs > table[mid][1]) {
                min = mid + 1;
            } else if (ucs < table[mid][0]) {
                max = mid - 1;
            } else {
                return true;
            }
        }

        return false;
    }

    // sorted list of non-overlapping intervals of non-spacing characters
    // generated by "uniset +cat=Me +cat=Mn +cat=Cf -00AD +1160-11FF +200B c"
    const combining = [_]Interval{
        .{ 0x0300, 0x036F },   .{ 0x0483, 0x0486 },   .{ 0x0488, 0x0489 },
        .{ 0x0591, 0x05BD },   .{ 0x05BF, 0x05BF },   .{ 0x05C1, 0x05C2 },
        .{ 0x05C4, 0x05C5 },   .{ 0x05C7, 0x05C7 },   .{ 0x0600, 0x0603 },
        .{ 0x0610, 0x0615 },   .{ 0x064B, 0x065E },   .{ 0x0670, 0x0670 },
        .{ 0x06D6, 0x06E4 },   .{ 0x06E7, 0x06E8 },   .{ 0x06EA, 0x06ED },
        .{ 0x070F, 0x070F },   .{ 0x0711, 0x0711 },   .{ 0x0730, 0x074A },
        .{ 0x07A6, 0x07B0 },   .{ 0x07EB, 0x07F3 },   .{ 0x0901, 0x0902 },
        .{ 0x093C, 0x093C },   .{ 0x0941, 0x0948 },   .{ 0x094D, 0x094D },
        .{ 0x0951, 0x0954 },   .{ 0x0962, 0x0963 },   .{ 0x0981, 0x0981 },
        .{ 0x09BC, 0x09BC },   .{ 0x09C1, 0x09C4 },   .{ 0x09CD, 0x09CD },
        .{ 0x09E2, 0x09E3 },   .{ 0x0A01, 0x0A02 },   .{ 0x0A3C, 0x0A3C },
        .{ 0x0A41, 0x0A42 },   .{ 0x0A47, 0x0A48 },   .{ 0x0A4B, 0x0A4D },
        .{ 0x0A70, 0x0A71 },   .{ 0x0A81, 0x0A82 },   .{ 0x0ABC, 0x0ABC },
        .{ 0x0AC1, 0x0AC5 },   .{ 0x0AC7, 0x0AC8 },   .{ 0x0ACD, 0x0ACD },
        .{ 0x0AE2, 0x0AE3 },   .{ 0x0B01, 0x0B01 },   .{ 0x0B3C, 0x0B3C },
        .{ 0x0B3F, 0x0B3F },   .{ 0x0B41, 0x0B43 },   .{ 0x0B4D, 0x0B4D },
        .{ 0x0B56, 0x0B56 },   .{ 0x0B82, 0x0B82 },   .{ 0x0BC0, 0x0BC0 },
        .{ 0x0BCD, 0x0BCD },   .{ 0x0C3E, 0x0C40 },   .{ 0x0C46, 0x0C48 },
        .{ 0x0C4A, 0x0C4D },   .{ 0x0C55, 0x0C56 },   .{ 0x0CBC, 0x0CBC },
        .{ 0x0CBF, 0x0CBF },   .{ 0x0CC6, 0x0CC6 },   .{ 0x0CCC, 0x0CCD },
        .{ 0x0CE2, 0x0CE3 },   .{ 0x0D41, 0x0D43 },   .{ 0x0D4D, 0x0D4D },
        .{ 0x0DCA, 0x0DCA },   .{ 0x0DD2, 0x0DD4 },   .{ 0x0DD6, 0x0DD6 },
        .{ 0x0E31, 0x0E31 },   .{ 0x0E34, 0x0E3A },   .{ 0x0E47, 0x0E4E },
        .{ 0x0EB1, 0x0EB1 },   .{ 0x0EB4, 0x0EB9 },   .{ 0x0EBB, 0x0EBC },
        .{ 0x0EC8, 0x0ECD },   .{ 0x0F18, 0x0F19 },   .{ 0x0F35, 0x0F35 },
        .{ 0x0F37, 0x0F37 },   .{ 0x0F39, 0x0F39 },   .{ 0x0F71, 0x0F7E },
        .{ 0x0F80, 0x0F84 },   .{ 0x0F86, 0x0F87 },   .{ 0x0F90, 0x0F97 },
        .{ 0x0F99, 0x0FBC },   .{ 0x0FC6, 0x0FC6 },   .{ 0x102D, 0x1030 },
        .{ 0x1032, 0x1032 },   .{ 0x1036, 0x1037 },   .{ 0x1039, 0x1039 },
        .{ 0x1058, 0x1059 },   .{ 0x1160, 0x11FF },   .{ 0x135F, 0x135F },
        .{ 0x1712, 0x1714 },   .{ 0x1732, 0x1734 },   .{ 0x1752, 0x1753 },
        .{ 0x1772, 0x1773 },   .{ 0x17B4, 0x17B5 },   .{ 0x17B7, 0x17BD },
        .{ 0x17C6, 0x17C6 },   .{ 0x17C9, 0x17D3 },   .{ 0x17DD, 0x17DD },
        .{ 0x180B, 0x180D },   .{ 0x18A9, 0x18A9 },   .{ 0x1920, 0x1922 },
        .{ 0x1927, 0x1928 },   .{ 0x1932, 0x1932 },   .{ 0x1939, 0x193B },
        .{ 0x1A17, 0x1A18 },   .{ 0x1B00, 0x1B03 },   .{ 0x1B34, 0x1B34 },
        .{ 0x1B36, 0x1B3A },   .{ 0x1B3C, 0x1B3C },   .{ 0x1B42, 0x1B42 },
        .{ 0x1B6B, 0x1B73 },   .{ 0x1DC0, 0x1DCA },   .{ 0x1DFE, 0x1DFF },
        .{ 0x200B, 0x200F },   .{ 0x202A, 0x202E },   .{ 0x2060, 0x2063 },
        .{ 0x206A, 0x206F },   .{ 0x20D0, 0x20EF },   .{ 0x302A, 0x302F },
        .{ 0x3099, 0x309A },   .{ 0xA806, 0xA806 },   .{ 0xA80B, 0xA80B },
        .{ 0xA825, 0xA826 },   .{ 0xFB1E, 0xFB1E },   .{ 0xFE00, 0xFE0F },
        .{ 0xFE20, 0xFE23 },   .{ 0xFEFF, 0xFEFF },   .{ 0xFFF9, 0xFFFB },
        .{ 0x10A01, 0x10A03 }, .{ 0x10A05, 0x10A06 }, .{ 0x10A0C, 0x10A0F },
        .{ 0x10A38, 0x10A3A }, .{ 0x10A3F, 0x10A3F }, .{ 0x1D167, 0x1D169 },
        .{ 0x1D173, 0x1D182 }, .{ 0x1D185, 0x1D18B }, .{ 0x1D1AA, 0x1D1AD },
        .{ 0x1D242, 0x1D244 }, .{ 0xE0001, 0xE0001 }, .{ 0xE0020, 0xE007F },
        .{ 0xE0100, 0xE01EF },
    };

    // The following two functions define the column width of an ISO 10646
    // character as follows:
    //
    //    - The null character (U+0000) has a column width of 0.
    //
    //    - Other C0/C1 control characters and DEL will lead to a return
    //      value of null
    //
    //    - Non-spacing and enclosing combining characters (general
    //      category code Mn or Me in the Unicode database) have a
    //      column width of 0.
    //
    //    - SOFT HYPHEN (U+00AD) has a column width of 1.
    //
    //    - Other format characters (general category code Cf in the Unicode
    //      database) and ZERO WIDTH SPACE (U+200B) have a column width of 0.
    //
    //    - Hangul Jamo medial vowels and final consonants (U+1160-U+11FF)
    //      have a column width of 0.
    //
    //    - Spacing characters in the East Asian Wide (W) or East Asian
    //      Full-width (F) category as defined in Unicode Technical
    //      Report #11 have a column width of 2.
    //
    //    - All remaining characters (including all printable
    //      ISO 8859-1 and WGL4 characters, Unicode control characters,
    //      etc.) have a column width of 1.

    pub fn width(ucs: Codepoint) ?u8 {
        // test for 8-bit control characters
        if (ucs == 0)
            return 0;
        if (ucs < 32 or (ucs >= 0x7f and ucs < 0xa0))
            return null;

        // search in table of non-spacing characters
        if (find(ucs, &combining))
            return 0;

        // if we arrive here, ucs is not a combining or C0/C1 control character
        return 1 + @as(u8, @intFromBool((ucs >= 0x1100 and
            (ucs <= 0x115f or // Hangul Jamo init. consonants
                ucs == 0x2329 or ucs == 0x232a or
                (ucs >= 0x2e80 and ucs <= 0xa4cf and ucs != 0x303f) or // CJK ... Yi
                (ucs >= 0xac00 and ucs <= 0xd7a3) or // Hangul Syllables
                (ucs >= 0xf900 and ucs <= 0xfaff) or // CJK Compatibility Ideographs
                (ucs >= 0xfe10 and ucs <= 0xfe19) or // Vertical forms
                (ucs >= 0xfe30 and ucs <= 0xfe6f) or // CJK Compatibility Forms
                (ucs >= 0xff00 and ucs <= 0xff60) or // Fullwidth Forms
                (ucs >= 0xffe0 and ucs <= 0xffe6) or
                (ucs >= 0x20000 and ucs <= 0x2fffd) or
                (ucs >= 0x30000 and ucs <= 0x3fffd)))));
    }

    pub fn utf8Width(str: []const u8) usize {
        var len: usize = 0;
        var it = MaybeUtf8Iterator{ .bytes = str };
        while (it.next()) |item| switch (item) {
            .invalid_utf8 => len += 1,
            .codepoint => |cp| len += width(cp) orelse 0,
        };
        return len;
    }
};

const MaybeUtf8Iterator = struct {
    bytes: []const u8,
    index: usize = 0,

    pub const Item = union(enum) {
        invalid_utf8: []const u8,
        codepoint: u21,
    };

    pub fn next(it: *@This()) ?Item {
        if (it.index >= it.bytes.len)
            return null;

        const codepoint_len = std.unicode.utf8ByteSequenceLength(it.bytes[it.index]) catch {
            const slice = it.bytes[it.index..][0..1];
            it.index += slice.len;
            return .{ .invalid_utf8 = slice };
        };
        if (codepoint_len > it.bytes[it.index..].len) {
            const slice = it.bytes[it.index..];
            it.index += slice.len;
            return .{ .invalid_utf8 = slice };
        }
        const slice = it.bytes[it.index..][0..codepoint_len];
        it.index += slice.len;
        const codepoint = std.unicode.utf8Decode(slice) catch return .{ .invalid_utf8 = slice };
        return .{ .codepoint = codepoint };
    }
};
