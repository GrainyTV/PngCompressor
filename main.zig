// Includes and imports
// ------------------------------
	const std = @import("std");
	const c = @cImport(
	{
		@cInclude("stdio.h");
		@cInclude("stdlib.h");
	});
	const lodepng = @cImport(
	{
		@cInclude("lodepng.h");
	});
	const libimagequant = @cImport(
	{
		@cInclude("libimagequant.h");
	});
// ------------------------------

// Usings and abbreviations
// ------------------------------
	const print = std.debug.print;
	const fileSystem = std.fs;
	const List = std.ArrayList;
	const Allocator = std.mem.Allocator;
	const OpenError = fileSystem.Dir.OpenError;
// ------------------------------

fn FilesInFolder(subpath: []const u8) ![][]const u8
{
	var folder = try fileSystem.cwd().openIterableDir(subpath, .{ .access_sub_paths = false, .no_follow = true });
	var folderIterator = folder.iterate();

	var list = List([]const u8).init(std.heap.page_allocator);

	while(try folderIterator.next()) |file|
	{
		try list.append(file.name);
	}

	return list.toOwnedSlice();
}

fn CreateDirectoryForProcessedImages() !void
{
	var folder = fileSystem.cwd().openDir("compressedImages", .{}) catch |exception|
	{
		if(exception == OpenError.FileNotFound)
		{
			fileSystem.cwd().makeDir("compressedImages") catch unreachable;
			return;
		}

		return exception;
	};
	
	defer folder.close();
}

fn ProcessImage(fileName: []const u8) void
{
	var image: *u8 = undefined;
	var width: u32 = undefined;
	var height: u32 = undefined;
	var @"error": c_uint = undefined;

	@"error" = lodepng.lodepng_decode32_file(@ptrCast(&image), &width, &height, @ptrCast(CombinePath("images", fileName)));
	defer c.free(image);

	if(@"error" != 0)
	{
		_ = c.printf("error %u: %s\n", @"error", lodepng.lodepng_error_text(@"error"));
		return;
	}

	// Use libimagequant to make a palette for the RGBA pixels

	const handler = libimagequant.liq_attr_create();
	const editedImage = libimagequant.liq_image_create_rgba(handler, image, @intCast(width), @intCast(height), 0);
	
	// You could set more options here, like liq_set_quality
	
	_ = libimagequant.liq_set_speed(handler, 1);

	var quantizationResult: *libimagequant.liq_result = undefined;
	
	if(libimagequant.liq_image_quantize(editedImage, handler, @ptrCast(&quantizationResult)) != 0) 
	{
		print("Quantization failed for image: {s}\n", .{fileName});
		return;
	}

	// Use libimagequant to make new image pixels from the palette

	const amountOfPixels: usize = width * height;
	var rawEightBitPixels = c.malloc(amountOfPixels);
	
	_ = libimagequant.liq_set_dithering_level(quantizationResult, 1.0);
	_ = libimagequant.liq_write_remapped_image(quantizationResult, editedImage, rawEightBitPixels, amountOfPixels);
	
	const palette = libimagequant.liq_get_palette(quantizationResult);
	
	// Save converted pixels as a PNG file

	var imageState: lodepng.LodePNGState = undefined;
	
	lodepng.lodepng_state_init(&imageState);
	imageState.info_raw.colortype = lodepng.LCT_PALETTE;
	imageState.info_raw.bitdepth = 8;
	imageState.info_png.color.colortype = lodepng.LCT_PALETTE;
	imageState.info_png.color.bitdepth = 8;

	for(0..palette.*.count) |i|
	{
		_ = lodepng.lodepng_palette_add(&imageState.info_png.color, palette.*.entries[i].r, palette.*.entries[i].g, palette.*.entries[i].b, palette.*.entries[i].a);
		_ = lodepng.lodepng_palette_add(&imageState.info_raw, palette.*.entries[i].r, palette.*.entries[i].g, palette.*.entries[i].b, palette.*.entries[i].a);
	}

	var newImage: *u8 = undefined;
	var fileSize: usize = undefined;
	@"error" = lodepng.lodepng_encode(@ptrCast(&newImage), &fileSize, @ptrCast(rawEightBitPixels), width, height, &imageState);
	
	if(@"error" != 0)
	{
		_ = c.printf("error %u: %s\n", @"error", lodepng.lodepng_error_text(@"error"));
	}

	_ = lodepng.lodepng_save_file(newImage, fileSize, @ptrCast(CombinePath("compressedImages", fileName)));
	lodepng.lodepng_state_cleanup(&imageState);

	libimagequant.liq_result_destroy(quantizationResult);
	libimagequant.liq_image_destroy(editedImage);
	libimagequant.liq_attr_destroy(handler);
	
	c.free(rawEightBitPixels);
}

fn CombinePath(firstPart: []const u8, secondPart: []const u8) []const u8
{
	print("{s}\n", .{secondPart});

	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	//defer arena.deinit();

	const allocator = arena.allocator();
	const combinedPath = allocator.alloc(u8, firstPart.len + 1 + secondPart.len) catch unreachable;
	
	@memcpy(combinedPath[0..firstPart.len], firstPart);
	@memcpy(combinedPath[firstPart.len..firstPart.len + 1], "/");
	@memcpy(combinedPath[firstPart.len + 1..], secondPart);

	print("{s}\n", .{combinedPath});

	return combinedPath;
}

pub fn main() !void 
{
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();

	var folder = try fileSystem.cwd().openIterableDir("images", .{ .access_sub_paths = false, .no_follow = true });
	var folderIterator = folder.iterate();

	var list = List([]const u8).init(std.heap.page_allocator);

	while(try folderIterator.next()) |file|
	{
		try list.append(file.name);
	}

	const images = list.toOwnedSlice() catch unreachable; //FilesInFolder("images") catch unreachable;

	if(images.len == 0)
	{
		return;
	}

	//print("{s}\n", .{images[0]});

	//CreateDirectoryForProcessedImages() catch |exception|
//	{
		//print("{}\n", .{exception});
	//};

	//print("{s}\n", .{images[0]});

	for(images) |image| //0..images.*.items.len) |i|
	{
		ProcessImage(image);
		//print("Image {d}-{s} done.\n", .{i, image});
	}
}