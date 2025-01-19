const std = @import("std");
const time = std.time;
const config = @import("config.zig");


const AVLTree = @import("./avl.zig").AVLTree;
const SkipList = @import("./skiplist.zig").SkipList;

fn benchmarkOperation(structure: anytype, _: bool, other_values: ?[]i32, values: []i32, operation: fn (anytype, i32, i32) void, label: []const u8) void {
    const start_time = time.nanoTimestamp();

    for (values, 0..) |value, index| {
        if (operation == rangeSearchOp) {
            operation(structure, value, other_values.?[index]);
        } else {
            operation(structure, value, 0);
        }
    }

    const end_time = time.nanoTimestamp();
    const duration = end_time - start_time;
    std.debug.print("{s} took {?} ns\n", .{label, duration});
}

fn insertOp(structure: anytype, value: i32, _: i32) void {
    structure.insert(value) catch |err| {
        std.debug.print("Error inserting value: {?}\n", .{err});
        return;
    };
}

fn searchOp(structure: anytype, value: i32, _: i32) void {
    _ = structure.search(value);
}

fn rangeSearchOp(structure: anytype, start: i32, end: i32) void {
    _ = structure.rangeSearch(start, end) catch |err| {
        std.debug.print("Error range searching value: {?}\n", .{err});
        return;
    };
}

fn deleteOp(structure: anytype, value: i32, _: i32) void {
    structure.remove(value) catch |err| {
        std.debug.print("Error deleting value: {?}\n", .{err});
        return;
    };
}

fn readValuesFromFile(allocator: std.mem.Allocator, file_path: []const u8) ![]i32 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_size = try file.getEndPos();
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);

    _ = try file.readAll(file_contents);

    var values = std.ArrayList(i32).init(allocator);
    var lines = std.mem.split(u8, file_contents, "\n");

    while (lines.next()) |line| {
        if (line.len == 0) continue; // Skip empty lines
        const value = try std.fmt.parseInt(i32, line, 10);
        try values.append(value);
    }

    return values.toOwnedSlice();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get file paths from command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <values_file> <other_values_file>\n", .{args[0]});
        return;
    }

    const values_file_path = args[1];
    const other_values_file_path = args[2];

    // Read values from the files
    const values = try readValuesFromFile(allocator, values_file_path);
    defer allocator.free(values);

    const other_values = try readValuesFromFile(allocator, other_values_file_path);
    defer allocator.free(other_values);

    if (values.len != other_values.len) {
        std.debug.print("Error: The two files must contain the same number of values.\n", .{});
        return;
    }

    const skiplevel: usize = config.skipListLevel;

    var avl_allocator = std.heap.page_allocator;
    var skip_allocator = std.heap.page_allocator;

    const seed: u64 = config.seed;

    var avl = AVLTree.init(&avl_allocator);
    var skiplist = SkipList(skiplevel).init(&skip_allocator, 0.5, seed);


    benchmarkOperation(&skiplist, false, other_values, values, insertOp, "Skip List Insertions");
    benchmarkOperation(&skiplist, false, other_values, values, searchOp, "Skip List Searches");
    benchmarkOperation(&skiplist, false, other_values, values, deleteOp, "Skip List Deletions");
    benchmarkOperation(&skiplist, false, other_values, values, rangeSearchOp, "Skip List Range Searches");

    benchmarkOperation(&avl, true, other_values, values, insertOp, "AVL Insertions");
    benchmarkOperation(&avl, true, other_values, values, searchOp, "AVL Searches");
    benchmarkOperation(&avl, true, other_values, values, deleteOp, "AVL Deletions");
    benchmarkOperation(&avl, true, other_values, values, rangeSearchOp, "AVL Range Searches");

}