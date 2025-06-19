const std = @import("std");

pub fn shrinkTsv(allocator: std.mem.Allocator, content: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    // Collect all lines first
    var lines_list = std.ArrayList([]const u8).init(allocator);
    defer lines_list.deinit();

    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        try lines_list.append(line);
    }

    // Remove the last empty line if the content ended with a newline
    if (lines_list.items.len > 0 and lines_list.items[lines_list.items.len - 1].len == 0) {
        _ = lines_list.pop();
    }

    // Process each line
    for (lines_list.items, 0..) |line, line_index| {
        if (line_index > 0) {
            try result.append('\n');
        }

        if (line.len == 0) {
            // Handle empty lines - just continue to add the newline
            continue;
        }

        var columns = std.mem.splitSequence(u8, line, "\t");
        var first_column = true;

        while (columns.next()) |column| {
            if (!first_column) {
                try result.append('\t');
            }
            first_column = false;

            // Trim whitespace from the column
            const trimmed = std.mem.trim(u8, column, " \t\r\n");
            try result.appendSlice(trimmed);
        }
    }

    // Add final newline only if the original content ended with one
    if (content.len > 0 and content[content.len - 1] == '\n') {
        try result.append('\n');
    }

    return try result.toOwnedSlice();
}

test "shrinkTsv should shrink the TSV content" {
    const allocator = std.testing.allocator;
    const tsv_content = "header1   \t     header2   \t  header3  \n  value1 \t   value2 \tvalue3\n longervalue\t  short \t  veryverylongvalue\n";
    const result = try shrinkTsv(allocator, tsv_content);
    defer allocator.free(result);
    const expected = "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\tveryverylongvalue\n";

    try std.testing.expectEqualStrings(expected, result);
}

pub fn getColumnWidths(allocator: std.mem.Allocator, content: []const u8) ![]usize {
    var column_widths = std.ArrayList(usize).init(allocator);
    defer column_widths.deinit();
    var lines = std.mem.splitSequence(u8, content, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines
        // Split line by tabs to get columns
        var columns = std.mem.splitSequence(u8, line, "\t");
        var col_index: usize = 0;
        while (columns.next()) |column| {
            // Ensure we have enough space in our widths array
            while (col_index >= column_widths.items.len) {
                try column_widths.append(0);
            }
            // Update the maximum width for this column
            const current_width = column_widths.items[col_index];
            const new_width = std.mem.trim(u8, column, " \t\r\n").len;
            if (new_width > current_width) {
                column_widths.items[col_index] = new_width;
            }
            col_index += 1;
        }
    }
    // Convert ArrayList to owned slice
    return try column_widths.toOwnedSlice();
}

test "getColumnWidths should return the correct column widths" {
    const allocator = std.testing.allocator;
    const tsv_content = "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\tveryverylongvalue\n";

    const result = try getColumnWidths(allocator, tsv_content);
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqual(@as(usize, 11), result[0]); // "longervalue" is 11 chars
    try std.testing.expectEqual(@as(usize, 7), result[1]); // "header2" is 7 chars
    try std.testing.expectEqual(@as(usize, 17), result[2]); // "veryverylongvalue" is 17 chars
}

test "getColumnWidths should trim leading and trailing whitespace" {
    const allocator = std.testing.allocator;
    const tsv_content = "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\t   veryverylongvalue   \n";

    const result = try getColumnWidths(allocator, tsv_content);
    defer allocator.free(result);

    try std.testing.expectEqual(@as(usize, 3), result.len);
    try std.testing.expectEqual(@as(usize, 11), result[0]); // "longervalue" is 11 chars
    try std.testing.expectEqual(@as(usize, 7), result[1]); // "header2" is 7 chars
    try std.testing.expectEqual(@as(usize, 17), result[2]); // "veryverylongvalue" is 17 chars
}

pub fn alignTsv(writer: anytype, content: []const u8, column_widths: []const usize) !void {
    var lines = std.mem.splitSequence(u8, content, "\n");
    while (lines.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines

        // First pass: count columns in this line
        var column_count: usize = 0;
        var temp_columns = std.mem.splitSequence(u8, line, "\t");
        while (temp_columns.next()) |_| {
            column_count += 1;
        }

        // Second pass: format the columns
        var columns = std.mem.splitSequence(u8, line, "\t");
        var col_index: usize = 0;
        while (columns.next()) |column| {
            if (col_index >= column_widths.len) break; // Prevent out of bounds access

            const trimmed_column = std.mem.trim(u8, column, " \t\r\n");
            try writer.writeAll(trimmed_column);

            // Add padding if this column is shorter than the maximum width (except for last column)
            if (col_index < column_count - 1 and trimmed_column.len < column_widths[col_index]) {
                const padding = column_widths[col_index] - trimmed_column.len;
                var i: usize = 0;
                while (i < padding) : (i += 1) {
                    try writer.writeByte(' ');
                }
            }
            // Add separator between columns (except for the last column)
            if (col_index < column_count - 1) {
                try writer.writeByte('\t');
            }
            col_index += 1;
        }
        try writer.writeByte('\n');
    }
}

test "alignTsv should format TSV content with proper alignment" {
    const allocator = std.testing.allocator;
    const tsv_content = "header1\theader2\theader3\nvalue1\tvalue2\tvalue3\nlongervalue\tshort\tveryverylongvalue\n";

    const column_widths = try getColumnWidths(allocator, tsv_content);
    defer allocator.free(column_widths);

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try alignTsv(buffer.writer(), tsv_content, column_widths);

    const result = buffer.items;
    const expected = "header1    \theader2\theader3\nvalue1     \tvalue2 \tvalue3\nlongervalue\tshort  \tveryverylongvalue\n";

    try std.testing.expectEqualStrings(expected, result);
}

test "alignTsv should handle empty lines and trim whitespace" {
    const allocator = std.testing.allocator;
    const tsv_content = "col1\tcol2\n\n  value1  \t  value2  \n";

    const column_widths = try getColumnWidths(allocator, tsv_content);
    defer allocator.free(column_widths);

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try alignTsv(buffer.writer(), tsv_content, column_widths);

    const result = buffer.items;
    const expected = "col1  \tcol2\nvalue1\tvalue2\n";

    try std.testing.expectEqualStrings(expected, result);
}
