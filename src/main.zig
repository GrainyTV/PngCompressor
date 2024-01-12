// Includes and imports
// ------------------------------
    const std = @import("std");
    const ar = @import("compression.zig");
    const parse = @import("parser.zig");
// ------------------------------

pub fn main() void 
{
    var arena = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const parsedParameters = parse.HandleArgumentsWithExceptions(&allocator);

    if (parsedParameters.HasValue())
    {
        const parameters = parsedParameters.value.?;

        if (parameters.overwrite and parameters.output.HasValue() == false)
        {
            for (parameters.input.value.?) |file|
            {
                ar.CompressImage(&file, &file);
            }
        }
        else
        {
            for (parameters.input.value.?, parameters.output.value.?) |input, output|
            {
                ar.CompressImage(&input, &output);
            }
        }
    }
}