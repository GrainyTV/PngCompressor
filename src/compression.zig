// Includes and imports
// ------------------------------
    const std = @import("std");
    const convert = @import("convert.zig");
    const c = @cImport(
    {
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

// Abbreviations
// ------------------------------
    const SuccessfulImageLoad = 0;
    const SuccessfulQuantization = 0;
    const SuccessfulImageSave = 0;
// ------------------------------

pub fn CompressImage(inputFile: *const [*:0]const u8, outputFile: *const [*:0]const u8) void
{
    // Loading contents of image file
    // ------------------------------
    var rawImage: *u8 = undefined;
    var width: u32 = undefined;
    var height: u32 = undefined;
    var status: u32 = lodepng.lodepng_decode32_file(@ptrCast(&rawImage), &width, &height, inputFile.*);

    if (status != SuccessfulImageLoad)
    {
        std.debug.print("error_{d}: {s}\n", .{status, lodepng.lodepng_error_text(status)});
        return;
    }
    // ------------------------------

    
    // Use libimagequant to make a palette for the RGBA pixels
    // ------------------------------
    const handler = libimagequant.liq_attr_create();
    const editedImage = libimagequant.liq_image_create_rgba(handler, rawImage, @intCast(width), @intCast(height), 0);
    // ------------------------------

    
    // You could set more options here, like liq_set_quality
    // ------------------------------
    _ = libimagequant.liq_set_speed(handler, 1);
    var quantizationResult: *libimagequant.liq_result = undefined;
    
    if (libimagequant.liq_image_quantize(editedImage, handler, @ptrCast(&quantizationResult)) != SuccessfulQuantization) 
    {
        std.debug.print("Quantization failed for image: {s}\n", .{std.fs.path.basename(convert.ToSlice(inputFile))});
        return;
    }
    // ------------------------------
    
    
    // Use libimagequant to make new image pixels from the palette
    // ------------------------------
    const amountOfPixels: usize = width * height;
    const rawEightBitPixels = c.malloc(amountOfPixels);
    defer c.free(rawEightBitPixels);
    
    _ = libimagequant.liq_set_dithering_level(quantizationResult, 1.0);
    _ = libimagequant.liq_write_remapped_image(quantizationResult, editedImage, rawEightBitPixels, amountOfPixels);
    const palette = libimagequant.liq_get_palette(quantizationResult);
    // ------------------------------
    

    // Apply palette to output file
    // ------------------------------
    var imageState: lodepng.LodePNGState = undefined;
    defer lodepng.lodepng_state_cleanup(&imageState);
    
    lodepng.lodepng_state_init(&imageState);
    imageState.info_raw.colortype = lodepng.LCT_PALETTE;
    imageState.info_raw.bitdepth = 8;
    imageState.info_png.color.colortype = lodepng.LCT_PALETTE;
    imageState.info_png.color.bitdepth = 8;

    for (0..palette.*.count) |i|
    {
        _ = lodepng.lodepng_palette_add(&imageState.info_png.color, palette.*.entries[i].r, palette.*.entries[i].g, palette.*.entries[i].b, palette.*.entries[i].a);
        _ = lodepng.lodepng_palette_add(&imageState.info_raw, palette.*.entries[i].r, palette.*.entries[i].g, palette.*.entries[i].b, palette.*.entries[i].a);
    }
    // ------------------------------
    
    
    // Save converted pixels as a PNG file
    // ------------------------------
    var newImage: *u8 = undefined;
    var fileSize: usize = undefined;
    status = lodepng.lodepng_encode(@ptrCast(&newImage), &fileSize, @ptrCast(rawEightBitPixels), width, height, &imageState);
    
    if(status != SuccessfulImageSave)
    {
        std.debug.print("error_{d}: {s}\n", .{status, lodepng.lodepng_error_text(status)});
    }

    _ = lodepng.lodepng_save_file(newImage, fileSize, outputFile.*);

    libimagequant.liq_result_destroy(quantizationResult);
    libimagequant.liq_image_destroy(editedImage);
    libimagequant.liq_attr_destroy(handler);
    // ------------------------------
}