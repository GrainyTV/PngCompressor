const std = @import("std");
const Builder = std.Build;
const fileSystem = std.fs;
const concat = std.mem.concat;

pub fn addFolderOfCSourceFile(exe: *Builder.Step.Compile, path: []const u8) void
{
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();

	var folder = fileSystem.cwd().openIterableDir(path, .{ .access_sub_paths = false, .no_follow = true }) catch unreachable;
	defer folder.close();
	
	var folderIterator = folder.iterate();

	while (folderIterator.next() catch unreachable) |entry|
	{
		const cSource = concat(arena.allocator(), u8, &[_][]const u8{ path, "/", entry.name }) catch unreachable;
		exe.addCSourceFile(cSource, &[_][]const u8{});
	}
}

pub fn build(b: *Builder) void 
{
	b.exe_dir = ".";
	b.verbose = true;

	const target = b.standardTargetOptions(.{});
	const exe = b.addExecutable(
	.{
		.name = "PngCompressor",
		.root_source_file = .{ .path = "main.zig" },
		.target = target,
		.optimize = .ReleaseFast,
		.link_libc = true,
		.use_llvm = true,
		.use_lld = true,
	});

	exe.addCSourceFile("lodepng/lodepng.c", &[_][]const u8{});
	exe.addIncludePath("lodepng");
	addFolderOfCSourceFile(exe, "libimagequant/sources");
	exe.addIncludePath("libimagequant/headers");

	b.installArtifact(exe);
}