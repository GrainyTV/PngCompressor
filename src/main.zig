// Includes and imports
// ------------------------------
    const std = @import("std");
    const ar = @import("compression.zig");
    const parse = @import("parser.zig");
// ------------------------------

pub fn main() !void 
{
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const parameters = try parse.HandleArguments(&allocator);

    if (parameters.areValid)
    {
        if (parameters.isFile and parameters.overwrite)
        {
            ar.CompressImage(&parameters.input.?[0], &parameters.input.?[0]);    
        }
        else if (parameters.isFile == false and parameters.overwrite)
        {
            for (parameters.input.?) |file|
            {
                ar.CompressImage(&file, &file);
            }
        }
        else if (parameters.isFile and parameters.overwrite == false)
        {
            ar.CompressImage(&parameters.input.?[0], &parameters.output.?[0]);
        }
        else
        {
            for (parameters.input.?, parameters.output.?) |input, output|
            {
                ar.CompressImage(&input, &output);
            }
        }
    }
}