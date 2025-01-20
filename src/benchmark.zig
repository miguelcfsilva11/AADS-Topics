const std = @import("std");
const time = std.time;
const config = @import("config.zig");
const AVLTree = @import("./avl.zig").AVLTree;
const SkipList = @import("./skiplist.zig").SkipList;

const ExecutionMetrics = @import("./metrics.zig").ExecutionMetrics;


fn benchmarkOperation(structure: anytype, other_values: ?[]i32, values: []i32, operation: fn (anytype, i32, i32) void, _: []const u8) i128 {
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
    return duration;

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

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: {s} <values_file> <other_values_file>\n", .{args[0]});
        return;
    }

    const values_file_path = args[1];
    const other_values_file_path = args[2];

    const values = try readValuesFromFile(allocator, values_file_path);
    defer allocator.free(values);

    const other_values = try readValuesFromFile(allocator, other_values_file_path);
    defer allocator.free(other_values);

    if (values.len != other_values.len) {
        std.debug.print("Error: The two files must contain the same number of values.\n", .{});
        return;
    }

    const skiplevel: usize = config.skipListLevel;

    var arena_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var avl_allocator = arena_allocator.allocator();

    var double_allocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var skip_allocator = double_allocator.allocator();

    const seed: u64 = config.seed;

    var avl = AVLTree.init(&avl_allocator);
    var skiplist = SkipList(skiplevel).init(&skip_allocator, 0.5, seed);

    var avl_metrics: ExecutionMetrics = ExecutionMetrics.init("AVL Tree");
    var skiplist_metrics: ExecutionMetrics = ExecutionMetrics.init("Skip List");


    skiplist_metrics.insertions    = benchmarkOperation(&skiplist, other_values, values, insertOp, "Skip List Insertions");
    skiplist_metrics.memory        = skiplist.totalSize();
    skiplist_metrics.searches      = benchmarkOperation(&skiplist, other_values, values, searchOp, "Skip List Searches");
    skiplist_metrics.deletions     = benchmarkOperation(&skiplist, other_values, values, deleteOp, "Skip List Deletions");
    skiplist_metrics.rangeSearches = benchmarkOperation(&skiplist, other_values, values, rangeSearchOp, "Skip List Range Searches");
    skiplist_metrics.size          = values.len;

    avl_metrics.insertions    = benchmarkOperation(&avl, other_values, values, insertOp, "AVL Insertions");
    avl_metrics.memory        = avl.totalSize();
    avl_metrics.searches      = benchmarkOperation(&avl, other_values, values, searchOp, "AVL Searches");
    avl_metrics.deletions     = benchmarkOperation(&avl, other_values, values, deleteOp, "AVL Deletions");
    avl_metrics.rangeSearches = benchmarkOperation(&avl, other_values, values, rangeSearchOp, "AVL Range Searches");
    avl_metrics.size          = values.len;



    const file_allocator = std.heap.page_allocator;

    const file_name = try std.fmt.allocPrint(file_allocator, "metrics/metrics_{d}.csv", .{values.len});

    var file: std.fs.File = undefined;
    const mode: std.fs.File.OpenMode = std.fs.File.OpenMode.write_only;
    file = (std.fs.cwd().openFile(file_name, .{.mode = mode}) catch |err| switch (err) {
        error.FileNotFound => try std.fs.cwd().createFile(file_name, .{.truncate = false}),
        else => {
            std.debug.print("Error opening file: {?}\n", .{err});
            return err;
        },
    });

    // Write header if the file is empty
    const file_info = try file.stat();
    if (file_info.size == 0) {
        try file.writer().print("Structure Type,Insertions,Searches,Range Searches,Deletions,Memory,Size\n", .{});
    }

    var CsvAllocator = std.heap.page_allocator;

    const avlCsvEntry = try avl_metrics.toCSV(&CsvAllocator);
    const skipCsvEntry = try skiplist_metrics.toCSV(&CsvAllocator);

    defer CsvAllocator.free(avlCsvEntry);
    defer CsvAllocator.free(skipCsvEntry);


    try file.writer().print("{s}", .{avlCsvEntry});
    try file.writer().print("{s}", .{skipCsvEntry});
    defer file.close();

    std.debug.print("Metrics successfully written to {s}\n", .{file_name});
}