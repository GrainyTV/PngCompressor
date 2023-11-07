// Includes and imports
// ------------------------------
    const std = @import("std");
    const clap = @import("clap.zig");
    const dir = @import("directory.zig");
// ------------------------------

// Abbreviations
// ------------------------------
    const RequiredParameters = dir.RequiredParameters;
// ------------------------------

const params = [_]clap.Param(u8)
{
    .{
        .id = 'i',
        .names = .{ .short = 'i', .long = "input" },
        .takes_value = .one,
    },
    
    .{
        .id = 'o',
        .names = .{ .short = 'o', .long = "output" },
        .takes_value = .one,
    },
    
    .{
        .id = 'f',
        .names = .{ .short = 'f', .long = "force" },
        .takes_value = .none,
    },
};

pub fn HandleArguments(allocator: *const std.mem.Allocator) !RequiredParameters
{
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator.*);
    defer argsIterator.deinit();

    _ = argsIterator.next();

    var parser = clap.streaming.Clap(u8, std.process.ArgIterator)
    {
        .params = &params,
        .iter = &argsIterator,
        .diagnostic = undefined,
    };

    var imageParams = RequiredParameters{ .input = null, .output = null, .isFile = true };

    while (parser.next() catch default:
    { 
        std.debug.print("Format exception in your provided command.\n", .{});
        std.debug.print("Use -h, --help or check the documentation for the different available options.\n", .{});
        imageParams.areValid = false;
        break :default null;

    }) |arg| 
    {
        switch (arg.param.id)
        {
            'i' => try HandleInputOutput(&arg.value.?, &imageParams, 'i', allocator),
            'o' => try HandleInputOutput(&arg.value.?, &imageParams, 'o', allocator),
            'f' => imageParams.overwrite = true,
            else => unreachable,
        }
    }

    return imageParams;
}

pub fn HandleInputOutput(param: *const []const u8, imageParams: *RequiredParameters, io: u8, allocator: *const std.mem.Allocator) !void
{
    if (std.fs.path.isAbsolute(param.*))
    {
        try dir.HandlePath(param, dir.PathType.Absolute, imageParams, io, allocator);
    }
    else
    {
        try dir.HandlePath(param, dir.PathType.Relative, imageParams, io, allocator);
    }
}