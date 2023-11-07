// Includes and imports
// ------------------------------
    const std = @import("std");
    const convert = @import("convert.zig");
// ------------------------------

// Abbreviations
// ------------------------------
    const workingDir = std.fs.cwd();
    const OpenError = std.fs.File.OpenError;
// ------------------------------

pub const PathType = enum
{
    Absolute,
    Relative,
};

pub const RequiredParameters = struct
{
    input: ?[][*:0]const u8,
    output: ?[][*:0]const u8,
    overwrite: bool = false,
    areValid: bool = true,
    isFile: bool,
};

pub fn FilesInFolder(path: *const []const u8, allocator: *const std.mem.Allocator) ![][*:0]const u8
{
    var list = std.ArrayList([*:0]const u8).init(allocator.*);
    var folder = try workingDir.openIterableDir(path.*, .{ .access_sub_paths = false, .no_follow = true });
    defer folder.close();

    var folderIterator = folder.iterate();

    while (try folderIterator.next()) |file|
    {
        const fileName = try allocator.dupeZ(u8, try std.fs.path.joinZ(allocator.*, &[_][]const u8{ path.*, file.name }));
        try list.append(fileName);
    }

    return list.toOwnedSlice();
}

pub fn GenerateOutputFiles(path: *const []const u8, inputFiles: *const [][*:0]const u8, allocator: *const std.mem.Allocator) ![][*:0]const u8
{
    var list = std.ArrayList([*:0]const u8).init(allocator.*);

    for (inputFiles.*) |inputFile|
    {
        const rawFileName = std.fs.path.basename(convert.ToSlice(&inputFile));
        const fileName = try allocator.dupeZ(u8, try std.fs.path.joinZ(allocator.*, &[_][]const u8{ path.*, rawFileName }));
        try list.append(fileName);
    }

    return list.toOwnedSlice();
}

pub fn IsPng(path: *const []const u8, allocator: *const std.mem.Allocator) !bool
{
    if (std.mem.eql(u8, try std.ascii.allocLowerString(allocator.*, std.fs.path.extension(path.*)), ".png"))
    {
        return true;
    }
    else
    {
        return false;
    }
}

pub fn HandlePath(path: *const []const u8, pathVariant: PathType, imageParams: *RequiredParameters, io: u8, allocator: *const std.mem.Allocator) !void
{
    if (try IsPng(path, allocator))
    {
        if (io == 'i')
        {
            var inputFile = (if (pathVariant == PathType.Absolute) std.fs.openFileAbsolute(path.*, .{}) 
                             else workingDir.openFile(path.*, .{}))
                             catch |exception| default:
            {
                if (exception == OpenError.FileNotFound)
                {
                    std.debug.print("Provided {s} file does not exist.\n", .{if (io == 'i') "input" else "output"});
                }

                imageParams.areValid = false;
                break :default null;
            };

            if (inputFile) |file|
            {
                file.close();
                var memory = try allocator.alloc([*:0]const u8, 1);
                memory[0] = try convert.ToSentinel(path, allocator);
                imageParams.isFile = true;
                imageParams.input = memory;
            }
        }
        else
        {
            if (imageParams.input == null)
            {
                std.debug.print("Please provide input in advance of the output.\n", .{});
                imageParams.areValid = false;
                return;
            }
            else if (imageParams.isFile == false)
            {
                std.debug.print("An explicit output location is only allowed with singular image files as input.\n", .{});
                imageParams.areValid = false;
                return;
            }
            else if (std.mem.eql(u8, convert.ToSlice(&imageParams.input.?[0]), path.*))
            {
                std.debug.print("Using the same input and output is only allowed with the force flag (-f, --force). In that case, specifying output is unnecessary.\n", .{});
                std.debug.print("Otherwise, choose two distinct entries.\n", .{});
                imageParams.areValid = false;
                return;
            }
            
            var memory = try allocator.alloc([*:0]const u8, 1);
            memory[0] = try convert.ToSentinel(path, allocator);
            imageParams.output = memory;
        }
    }
    else
    {
        var inputDir = (if (pathVariant == PathType.Absolute) std.fs.openDirAbsolute(path.*, .{ .access_sub_paths = false, .no_follow = true })
                        else workingDir.openDir(path.*, .{ .access_sub_paths = false, .no_follow = true }))
                        catch |exception| default:
        {
            if (exception == OpenError.FileNotFound)
            {
                std.debug.print("Provided {s} folder does not exist.\n", .{if (io == 'i') "input" else "output"});
            }

            imageParams.areValid = false;
            break :default null;
        };

        if (inputDir) |dir|
        {
            @constCast(&dir).close();

            if (io == 'i')
            {
                imageParams.isFile = false;
                imageParams.input = try FilesInFolder(path, allocator);
            }
            else
            {
                if (imageParams.input == null)
                {
                    std.debug.print("Please provide input in advance of the output.\n", .{});
                    imageParams.areValid = false;
                    return;
                }
                
                imageParams.output = try GenerateOutputFiles(path, &imageParams.input.?, allocator);
            }    
        }
    }
}