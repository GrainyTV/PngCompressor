// Includes and imports
// ------------------------------
    const std = @import("std");
// ------------------------------

pub fn ToSentinel(slice: *const []const u8, allocator: *const std.mem.Allocator) ![*:0]const u8
{
    return (try allocator.dupeZ(u8, slice.*)).ptr;
}

pub fn ToSlice(sentinel: *const [*:0]const u8) []const u8
{
    return std.mem.span(sentinel.*);
}