// Includes and imports
// ------------------------------
    const std = @import("std");
    const ParseException = @import("parser.zig").ParseException;
// ------------------------------

pub fn ToSentinel(slice: *const []const u8, allocator: *const std.mem.Allocator) ![*:0]const u8
{
    if (slice.len >= std.fs.MAX_PATH_BYTES)
    {
        return ParseException.TooLongPath;
    }

    const buffer = try allocator.allocSentinel(u8, slice.len, 0);
    @memcpy(buffer, slice.*);
    return buffer;
}

pub fn ToSlice(sentinel: *const [*:0]const u8) []const u8
{
    return std.mem.span(sentinel.*);
}