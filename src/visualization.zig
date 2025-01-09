const std = @import("std");
const AVLTree = @import("./avl.zig").AVLTree;
const SkipList = @import("./skipList.zig").SkipList;

pub fn main() !void {

    var allocator = std.heap.page_allocator;
    const numValues = 10;
    var prng = std.rand.DefaultPrng.init(12345); // Initialize with a seed
    const random = prng.random();

    var values: [numValues]i32 = undefined;

    for (0..numValues) |i| {
        // Generate a random i32 within [-100, 100]
        values[i] = @rem(random.int(i32), 201) - 100;
    }

    std.debug.print("Generated Values: {any}\n", .{values});

    // Visualize AVL Tree
    var avl = AVLTree.init(&allocator);
    defer avl.deinit();
    try visualizeAVL(&avl, &values);

    // Visualize Skip List
    var skipList = SkipList.init(allocator, 4, 0.5);
    defer skipList.deinit();
    try visualizeSkipList(skipList, values);
}

fn visualizeAVL(avl: *AVLTree, values: []const i32) !void {
    var stepPNGs: [][]const u8 = try std.heap.page_allocator.alloc([]const u8, values.len);
    defer std.heap.page_allocator.free(stepPNGs);

    var i: usize = 0;
    for (values) |value| {
        const dotFileName = std.fmt.allocPrint(std.heap.page_allocator, "step{d}_avl_tree.dot", .{i + 1}) catch unreachable;
        const pngFileName = std.fmt.allocPrint(std.heap.page_allocator, "step{d}_avl_tree.png", .{i + 1}) catch unreachable;
        stepPNGs[i] = pngFileName;
        try insertAndVisualizeAVL(avl, value, dotFileName, pngFileName);
        i += 1;
    }


    try generateAnimation(stepPNGs, "avl_tree_animation.gif");
}

fn visualizeSkipList(skipList: SkipList, values: []const i32) !void {
    var stepPNGs: []const []const u8 = try std.heap.page_allocator.alloc([]const u8, values.len);
    defer std.heap.page_allocator.free(stepPNGs);

    var i: usize = 0;
    for (values) |value| {

        const dotFileName = std.fmt.allocPrint(std.heap.page_allocator, "step{d}_skip_list.dot", .{i + 1}) catch unreachable;
        const pngFileName = std.fmt.allocPrint(std.heap.page_allocator, "step{d}_skip_list.png", .{i + 1}) catch unreachable;
        stepPNGs[i] = pngFileName;
        try insertAndVisualizeSkipList(skipList, value, dotFileName, pngFileName);

        i += 1;
    }

    try generateAnimation(stepPNGs, "skip_list_animation.gif");
}

fn insertAndVisualizeAVL(avl: *AVLTree, key: i32, dotFileName: []const u8, pngFileName: []const u8) !void {
    avl.insert(key);
    try generateAVLTreeDot(avl, dotFileName);
    try runGraphviz(dotFileName, pngFileName);
}

fn insertAndVisualizeSkipList(skipList: SkipList, key: i32, dotFileName: []const u8, pngFileName: []const u8) !void {
    try skipList.insert(key);
    try generateSkipListDot(skipList, dotFileName);
    try runGraphviz(dotFileName, pngFileName);
}

fn generateAVLTreeDot(avl: *AVLTree, fileName: []const u8) !void {
    var file = try std.fs.cwd().createFile(fileName, .{});
    defer file.close();

    const writer = file.writer();
    try writer.print("digraph AVLTree {\n", .{});
    try writeAVLNode(avl.root, writer);
    try writer.print("}\n", .{});
}

fn writeAVLNode(node: ?*AVLTree.Node, writer: anytype) !void {
    if (node == null) return;
    const n = node.?;

    if (n.left) |left| {
        try writer.print("    \"{d}\" -> \"{d};\n", .{n.key, left.key});
        try writeAVLNode(n.left, writer);
    }

    if (n.right) |right| {
        try writer.print("    \"{d}\" -> \"{d};\n", .{n.key, right.key});
        try writeAVLNode(n.right, writer);
    }
}

fn generateSkipListDot(skipList: SkipList, fileName: []const u8) !void {
    var file = try std.fs.cwd().createFile(fileName, .{});
    defer file.close();

    const writer = file.writer();
    try writer.print("digraph SkipList {\n", .{});
    if (skipList.header) |header| {
        try writeSkipListNode(header, writer);
    }
    try writer.print("}\n", .{});
}

fn writeSkipListNode(node: *SkipList.Node, writer: anytype) !void {
    var current = node;
    while (current != null) {
        for (0..current.forward.len) |level| {
            const next = current.forward[level];
            if (next) {
                try writer.print("    \"{d}\" -> \"{d}\" [label=\"Level {d}\"];\n", .{current.key, next.?.key, level});
            }
        }
        current = current.forward[0];
    }
}

fn runGraphviz(dotFile: []const u8, outputFile: []const u8) !void {
    var gp = std.ChildProcess.init(.{"dot", "-Tpng", dotFile, "-o", outputFile});
    defer gp.deinit();
    try gp.spawnAndWait();
}

fn generateAnimation(imageFiles: []const []const u8, outputGif: []const u8) !void {
    var args = try std.heap.page_allocator.alloc([]const u8, imageFiles.len + 3);
    defer std.heap.page_allocator.free(args);

    args[0] = "convert"; // Use ImageMagick or similar tools
    var i: usize = 0;
    for (imageFiles) |file| {
        args[i + 1] = file;
        i += 1;
    }
    args[imageFiles.len + 1] = outputGif;
    args[imageFiles.len + 2] = null;

    var gp = std.ChildProcess.init(args);
    defer gp.deinit();
    try gp.spawnAndWait();
}
