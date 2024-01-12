// Includes and imports
// ------------------------------
    const std = @import("std");
    const convert = @import("convert.zig");
    const maybe = @import("maybe.zig");
    const parser = @import("parser.zig");
// ------------------------------

// Abbreviations
// ------------------------------
    const workingDir = std.fs.cwd();
    const OpenError = std.fs.File.OpenError;
    const Maybe = maybe.Maybe;
    const ParseException = parser.ParseException;
// ------------------------------

pub const PathType = enum
{
    Absolute,
    Relative,
};

pub const RequiredParameters = struct
{
    input: Maybe([][*:0]const u8) = .{},
    output: Maybe([][*:0]const u8) = .{},
    overwrite: bool = false,
    isFile: bool = true,
};

pub fn PngFilesInFolder(path: *const []const u8, allocator: *const std.mem.Allocator) ![][*:0]const u8
{
    var list = std.ArrayList([*:0]const u8).init(allocator.*);
    var folder = workingDir.openIterableDir(path.*, .{ .access_sub_paths = false, .no_follow = true }) catch unreachable;
    defer folder.close();

    var folderIterator = folder.iterate();

    while (folderIterator.next() catch return ParseException.FileInaccessible) |file|
    {
        if (IsPng(&file.name))
        {
            const fileName = try allocator.dupeZ(u8, try std.fs.path.joinZ(allocator.*, &[_][]const u8{ path.*, file.name }));
            try list.append(fileName);
        }
    }

    return list.toOwnedSlice();
}

pub fn GenerateOutputFiles(path: *const []const u8, inputFiles: *const [][*:0]const u8, allocator: *const std.mem.Allocator) ![][*:0]const u8
{
    var list = try std.ArrayList([*:0]const u8).initCapacity(allocator.*, inputFiles.len);

    for (inputFiles.*) |inputFile|
    {
        const rawFileName = std.fs.path.basename(convert.ToSlice(&inputFile));

        if (rawFileName.len + path.len + 1 >= std.fs.MAX_PATH_BYTES)
        {
            return ParseException.TooLongPath;
        }

        const fileName = try allocator.dupeZ(u8, try std.fs.path.joinZ(allocator.*, &[_][]const u8{ path.*, rawFileName }));
        list.appendAssumeCapacity(fileName);
    }

    return list.toOwnedSlice();
}

pub fn IsPng(path: *const []const u8) bool
{
    const fileExtension = std.fs.path.extension(path.*);
    var lowerCopy: [4]u8 = undefined;

    if (fileExtension.len == 4 and std.mem.eql(u8, std.ascii.lowerString(&lowerCopy, fileExtension), ".png"))
    {
        return true;
    }
    else
    {
        return false;
    }
}

pub fn IsFile(path: *const []const u8) Maybe(bool)
{
    var folderOrFile = workingDir.openFile(path.*, .{}) catch return .{};
    defer folderOrFile.close();

    const metadata = folderOrFile.metadata() catch return .{};

    return switch (metadata.kind())
    {
        .directory => .{ .value = false },
        .file => .{ .value = true },
        else => .{},
    };
}

pub fn Exists(path: *const []const u8) bool
{
    var folderOrFile = workingDir.openFile(path.*, .{}) catch return false;
    defer folderOrFile.close();

    return true;
}

pub fn HandleInputPath(path: *const []const u8, imageParams: *RequiredParameters, allocator: *const std.mem.Allocator) !void
{
    const isFile = IsFile(path).value orelse return ParseException.FileInaccessible;

    if (isFile)
    {
        const image = try convert.ToSentinel(path, allocator);
        imageParams.input.value = try allocator.dupe([*:0]const u8, &[1][*:0]const u8{ image });
    }
    else
    {
        imageParams.isFile = false;
        imageParams.input.value = try PngFilesInFolder(path, allocator);
    }
}

pub fn HandleOutputPath(path: *const []const u8, imageParams: *RequiredParameters, allocator: *const std.mem.Allocator) !void
{
    if (imageParams.input.HasValue() == false)
    {
        return ParseException.OutputAdvancesInput;
    }
        
    const isFolder = if (imageParams.input.value.?.len > 1) true else false;

    if (isFolder)
    {
        if (imageParams.isFile)
        {
            return ParseException.MismatchedInputOutput;
        }

        if (Exists(path) == false)
        {
            return ParseException.FileInaccessible;
        }

        const results = try GenerateOutputFiles(path, &imageParams.input.value.?, allocator);
        imageParams.output.value = results;
    }
    else
    {
        if (imageParams.isFile == false)
        {
            return ParseException.MismatchedInputOutput;
        }
        
        const image = try convert.ToSentinel(path, allocator);
        imageParams.output.value = try allocator.dupe([*:0]const u8, &[1][*:0]const u8{ image });
    }
}