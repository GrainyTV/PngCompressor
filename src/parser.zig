// Includes and imports
// ------------------------------
    const std = @import("std");
    const clap = @import("clap.zig");
    const dir = @import("directory.zig");
    const maybe = @import("maybe.zig");
    const convert = @import("convert.zig");
// ------------------------------

// Abbreviations
// ------------------------------
    const RequiredParameters = dir.RequiredParameters;
    const GeneralIterator = std.process.ArgIteratorGeneral(.{});
    const Maybe = maybe.Maybe;
    const HeapException = std.mem.Allocator.Error;
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

    .{
        .id = 'h',
        .names = .{ .short = 'h', .long = "help" },
        .takes_value = .none,
    },
};

const helpText =
    \\
    \\Usage: PngCompressor [option] [parameter]
    \\
    \\General Options:
    \\
    \\  -h, --help           Displays this help and exit.
    \\  -i, --input path     Specifies the input file or folder.
    \\  -o, --output path    Specifies the output file or folder.
    \\  -f, --force          Allows overwriting the input files.
    \\
    \\
;

pub const ParseException = error
{
    BadFormat,
    UnsupportedFile,
    FileInaccessible,
    OutputAdvancesInput,
    MissingInput,
    MissingOutput,
    MismatchedInputOutput,
    TooLongPath,
    OverwriteWithoutFlag,
    HelpRequestInitiated,
};

pub fn FancyPrint(comptime lines: []const u8) void
{
    const whiteColor = 0xE7;
    const stdOut = std.io.getStdOut().writer();
    var tokenizer = std.mem.tokenizeAny(u8, lines, "\n");
    
    while (tokenizer.next()) |line| 
    {
        stdOut.print("\x1B[1:38:5:{d}m==>{s}\x1B[0m\n", .{whiteColor, line}) catch unreachable;
    }
}

pub fn HandleArgumentsWithExceptions(allocator: *const std.mem.Allocator) Maybe(RequiredParameters)
{
    var argsIterator = try std.process.ArgIterator.initWithAllocator(allocator.*);
    defer argsIterator.deinit();

    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, allocator) catch |exception|
    {
        switch (exception)
        {
            ParseException.BadFormat => FancyPrint(
                \\ Bad command line argument(s)
                \\ For more information run: PngCompressor -h
            ),
            ParseException.UnsupportedFile => FancyPrint(
                \\ Provided file extension not supported
                \\ Work with PNG files
            ),
            ParseException.FileInaccessible => FancyPrint(
                \\ Inaccessible file
                \\ Check the path or ensure proper access
            ),
            ParseException.OutputAdvancesInput => FancyPrint(
                \\ Found output before input
                \\ Provide input before specifying output
            ),
            ParseException.MissingInput => FancyPrint(
                \\ No input found
                \\ Input is mandatory for the application to work
            ),
            ParseException.MissingOutput => FancyPrint(
                \\ Omitted output requires overwrite
                \\ Turn on overwrite or provide output
            ),
            ParseException.MismatchedInputOutput => FancyPrint(
                \\ Mismatched input and output
                \\ Use folder-to-folder or file-to-file approach
            ),
            ParseException.TooLongPath => FancyPrint(
                \\ Path too long
                \\ Reduce path length for compatibility
            ),
            ParseException.OverwriteWithoutFlag => FancyPrint(
                \\ Overwrite without flag
                \\ Turn on overwrite to approve this transaction
            ),
            ParseException.HelpRequestInitiated => 
            {
                const stdOut = std.io.getStdOut().writer();
                stdOut.print(helpText, .{}) catch unreachable;
            },
            HeapException.OutOfMemory => FancyPrint(
                \\ Out of heap memory
                \\ Try rerunning the process to resolve
            ),
        }

        return .{};
    };

    return .{ .value = parameters };
}

pub fn HandleArguments(comptime T: type, iterator: *T, allocator: *const std.mem.Allocator) !RequiredParameters
{
    _ = iterator.next();

    var parser = clap.streaming.Clap(u8, T)
    {
        .params = &params,
        .iter = iterator,
    };

    var imageParams = RequiredParameters{};
    var paramsCounter: usize = 0;

    while (parser.next() catch return ParseException.BadFormat) |arg|
    {
        paramsCounter += 1;

        switch (arg.param.id)
        {
            'i' => try dir.HandleInputPath(&arg.value.?, &imageParams, allocator),
            'o' => try dir.HandleOutputPath(&arg.value.?, &imageParams, allocator),
            'f' => imageParams.overwrite = true,
            'h' => return ParseException.HelpRequestInitiated,
            else => unreachable,
        }
    }

    if (paramsCounter == 0)
    {
        return ParseException.BadFormat;
    }

    if (imageParams.input.HasValue() == false)
    {
        return ParseException.MissingInput;
    }

    if (imageParams.output.HasValue() == false and imageParams.overwrite == false)
    {
        return ParseException.MissingOutput;
    }

    if (imageParams.isFile and imageParams.input.HasValue())
    {
        const input = convert.ToSlice(&imageParams.input.value.?[0]);

        if (dir.IsPng(&input) == false)
        {
            return ParseException.UnsupportedFile;
        }      
    }

    if (imageParams.isFile and imageParams.output.HasValue())
    {
        const output = convert.ToSlice(&imageParams.output.value.?[0]);

        if (dir.IsPng(&output) == false)
        {
            return ParseException.UnsupportedFile;
        }
    }

    if (imageParams.overwrite == false)
    {
        for (imageParams.output.value.?) |output|
        {
            if (dir.Exists(&convert.ToSlice(&output)))
            {
                return ParseException.OverwriteWithoutFlag;
            }
        }
    }

    return imageParams;
}

test "ParserShouldFail_Empty"
{
    const allocator = std.testing.allocator;    
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor");
    defer argsIterator.deinit();
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.BadFormat, parameters);
}

test "ParserShouldFail_Garbage"
{
    const allocator = std.testing.allocator;    
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -j -k -l randomValue");
    defer argsIterator.deinit();
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.BadFormat, parameters);
}

test "ParserShouldFail_NoInput"
{
    const allocator = std.testing.allocator;    
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -f");
    defer argsIterator.deinit();
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.MissingInput, parameters);
}

test "ParserShouldFail_InputBeforeOutput"
{
    const allocator = std.testing.allocator;
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -o ./example.png -i ./example2.png");
    defer argsIterator.deinit();
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.OutputAdvancesInput, parameters);
}

test "ParserShouldFail_NonExistentFile"
{
    const allocator = std.testing.allocator;
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -i ./example.png");
    defer argsIterator.deinit();
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.FileInaccessible, parameters);
}

test "ParserShouldFail_NotPng"
{
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -i ./README.md -o ./README.md");
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(ParseException.UnsupportedFile, parameters);
}

test "ParserShouldFail_NoMemory"
{
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var failingAllocator = std.testing.FailingAllocator.init(arena.allocator(), .{ .fail_index = 2, .resize_fail_index = 2 });
    const allocator = failingAllocator.allocator();

    var argsIterator = try GeneralIterator.init(allocator, "./PngCompressor -i ./example/example1.png -o ./example/example1_compressed.png");
    
    const parameters = HandleArguments(@TypeOf(argsIterator), &argsIterator, &allocator);
    try std.testing.expectError(HeapException.OutOfMemory, parameters);
}