const std = @import("std");
const time = std.time;

const AVLTree = @import("./avl.zig").AVLTree;
const SkipList = @import("./skiplist.zig").SkipList;

fn benchmarkOperation(structure: anytype, _: bool, values: []i32, operation: fn (anytype, i32) void, label: []const u8) void {

    const start_time = time.nanoTimestamp();

    for (values) |value| {
        operation(structure, value);
    }
    const end_time = time.nanoTimestamp();
    const duration = end_time - start_time;
    std.debug.print("{s} took {} ns\n", .{label, duration});

}

fn insertOp(structure: anytype, value: i32) void {
    structure.insert(value) catch |err| {
        std.debug.print("Error inserting value: {?}\n", .{err});
        return;
    };
}

fn searchOp(structure: anytype, value: i32) void {
    _ = structure.search(value);
}
fn rangeSearchOp(structure: anytype, start: i32, end: i32) void {
    _ = structure.rangeSearch(start, end);
}

fn deleteOp(structure: anytype, value: i32) void {
    structure.remove(value) catch |err| {
        std.debug.print("Error deleting value: {?}\n", .{err});
        return;
    };
}

pub fn main() !void {
    const num_elements = 10000;
    var allocator = std.heap.page_allocator;

    const values = try allocator.alloc(i32, num_elements);
    defer allocator.free(values);

    var rng = std.rand.DefaultPrng.init(0);

    for (values) |*value| {
        
        const new_value: i32 = @intCast(rng.next() % 10000);
        value.* = new_value;
    }

    var avl_allocator = std.heap.page_allocator;
    var skip_allocator = std.heap.page_allocator;

    //take first arg when calling zig run


    const seed: u64 = @intCast(0);

    var avl = AVLTree.init(&avl_allocator);
    var skiplist = SkipList.init(&skip_allocator, 0.5, seed);

    // AVL Tree Benchmarks

    benchmarkOperation(&avl, true, values, insertOp, "AVL Insertions");
    benchmarkOperation(&avl, true, values, searchOp, "AVL Searches");
    benchmarkOperation(&avl, true ,values, deleteOp, "AVL Deletions");

    benchmarkOperation(&skiplist, false, values, insertOp, "Skip List Insertions");
    benchmarkOperation(&skiplist, false, values, searchOp, "Skip List Searches");
    benchmarkOperation(&skiplist, false, values, deleteOp, "Skip List Deletions");
}
