const std = @import("std");
const workingDir = std.fs.cwd();

pub fn build(b: *std.Build) void 
{
    b.exe_dir = ".";
    b.cache_root = 
    .{ 
        .path = "./zig-cache",
        .handle = workingDir.openDir("./zig-cache", .{}) catch workingDir, 
    };
    b.global_cache_root = 
    .{ 
        .path = "./zig-cache-global",
        .handle = workingDir.openDir("./zig-cache-global", .{}) catch workingDir, 
    };
    b.verbose = true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(
    .{
        .name = "PngCompressor",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
        .use_llvm = true,
    });

    const header = std.Build.LazyPath.relative("hdr");
    const library = std.Build.LazyPath.relative("lib");

    exe.addIncludePath(header);
    exe.addLibraryPath(library);
    exe.linkLibC();
    exe.linkSystemLibrary("lodepng");
    exe.linkSystemLibrary("imagequant");
    
    b.installArtifact(exe);
}