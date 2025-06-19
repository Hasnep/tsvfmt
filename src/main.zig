const std = @import("std");
const lib = @import("tsvfmt_lib");
const clap = @import("clap");

const Mode = enum {
    align_mode,
    shrink_mode,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Define CLI parameters
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                Display this help and exit.
        \\-m, --mode <MODE>              Set the processing mode: align or shrink (defaults to align)
        \\-a, --align                   Set mode to align, short for --mode=align (default)
        \\-s, --shrink                  Set mode to shrink, short for --mode=shrink
        \\<FILE>...                     TSV files to process (if none provided, uses stdin/stdout)
    );

    // Initialize diagnostics for error reporting
    var diag = clap.Diagnostic{};

    // Define parsers for argument parsing
    const parsers = comptime .{
        .FILE = clap.parsers.string,
        .MODE = clap.parsers.enumeration(Mode),
    };
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = allocator,
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    // Handle help option
    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }

    // Determine mode
    var mode: Mode = .align_mode; // Default to align mode
    if (res.args.@"align" != 0 and res.args.shrink != 0) {
        std.log.err("The --align and --shrink flags cannot be used at the same time", .{});
        return error.InvalidMode;
    }
    if (res.args.mode == null) {
        if (res.args.@"align" != 0) {
            mode = .align_mode;
        }
        if (res.args.shrink != 0) {
            mode = .shrink_mode;
        }
        // Otherwise use default value
    } else {
        // The --mode flag is provided
        if (res.args.@"align" != 0 or res.args.shrink != 0) {
            std.log.err("The --align and --shrink flags cannot be used with the --mode flag", .{});
            return error.InvalidMode;
        }
        mode = res.args.mode.?;
    }

    // Get file arguments
    const files = res.positionals[0];

    if (files.len == 0) {
        // No files provided, use stdin/stdout
        try processStdinStdout(allocator, mode);
    } else {
        // Process files in-place
        var has_errors = false;
        for (files) |file_path| {
            processFile(allocator, mode, file_path) catch {
                has_errors = true;
            };
        }
        if (has_errors) {
            std.process.exit(1);
        }
    }
}

fn processStdinStdout(allocator: std.mem.Allocator, mode: Mode) !void {
    const stdin = std.io.getStdIn().reader();
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const writer = bw.writer();

    // Read all input at once for both modes to properly calculate column widths
    const content = try stdin.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(content);

    switch (mode) {
        .shrink_mode => {
            const shrunk = try lib.shrinkTsv(allocator, content);
            defer allocator.free(shrunk);

            try writer.writeAll(shrunk);
        },
        .align_mode => {
            const column_widths = try lib.getColumnWidths(allocator, content);
            defer allocator.free(column_widths);
            try lib.alignTsv(writer, content, column_widths);
        },
    }

    try bw.flush();
}

fn processFile(allocator: std.mem.Allocator, mode: Mode, file_path: []const u8) !void {
    // Read the file
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.log.err("File not found: {s}", .{file_path});
                return err;
            },
            error.AccessDenied => {
                std.log.err("Permission denied: {s}", .{file_path});
                return err;
            },
            error.IsDir => {
                std.log.err("Is a directory: {s}", .{file_path});
                return err;
            },
            else => {
                std.log.err("Failed to open file '{s}': {}", .{ file_path, err });
                return err;
            },
        }
    };
    defer file.close();

    const content = file.readToEndAlloc(allocator, std.math.maxInt(usize)) catch |err| {
        std.log.err("Failed to read file '{s}': {}", .{ file_path, err });
        return err;
    };
    defer allocator.free(content);

    // Process the content
    const processed_content = switch (mode) {
        .shrink_mode => lib.shrinkTsv(allocator, content) catch |err| {
            std.log.err("Failed to process file '{s}': {}", .{ file_path, err });
            return err;
        },
        .align_mode => blk: {
            const column_widths = lib.getColumnWidths(allocator, content) catch |err| {
                std.log.err("Failed to analyze file '{s}': {}", .{ file_path, err });
                return err;
            };
            defer allocator.free(column_widths);

            var buffer = std.ArrayList(u8).init(allocator);
            lib.alignTsv(buffer.writer(), content, column_widths) catch |err| {
                std.log.err("Failed to process file '{s}': {}", .{ file_path, err });
                return err;
            };
            break :blk buffer.toOwnedSlice() catch |err| {
                std.log.err("Failed to process file '{s}': {}", .{ file_path, err });
                return err;
            };
        },
    };
    defer allocator.free(processed_content);

    // Write back to the file
    const output_file = std.fs.cwd().createFile(file_path, .{}) catch |err| {
        switch (err) {
            error.AccessDenied => {
                std.log.err("Permission denied writing to file: {s}", .{file_path});
                return err;
            },
            error.PathAlreadyExists => {
                // This shouldn't happen with createFile, but handle it
                std.log.err("Cannot overwrite file: {s}", .{file_path});
                return err;
            },
            else => {
                std.log.err("Failed to write to file '{s}': {}", .{ file_path, err });
                return err;
            },
        }
    };
    defer output_file.close();

    output_file.writeAll(processed_content) catch |err| {
        std.log.err("Failed to write to file '{s}': {}", .{ file_path, err });
        return err;
    };

    std.log.info("Processed file: {s}", .{file_path});
}
