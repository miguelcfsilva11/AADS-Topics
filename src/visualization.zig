const std = @import("std");
const AVLTree = @import("./avl.zig").AVLTree;
const Node = @import("./avl.zig").AVLTree.Node;

const raylib = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    const numValues = 10000;
    var prng = std.rand.DefaultPrng.init(12345); // Initialize with a seed
    var random = prng.random();

    var avl = AVLTree.init(&allocator);

    var valuesInserted: usize = 0; // Track how many values have been inserted
    const totalValues = numValues;

    raylib.InitWindow(800, 600, "AVL Tree Visualization");

    defer raylib.CloseWindow();

    var inputBuffer: [32]u8 = [_]u8{0} ** 32;
    var inputLength: usize = 0;
    raylib.SetTargetFPS(60);

    while (!raylib.WindowShouldClose()) {
        if (raylib.IsKeyPressed(raylib.KEY_TAB)) {
            if (inputLength > 0) {
                const inputStr = inputBuffer[0..inputLength];
                const inputValue = try parseInput(inputStr);
                const resetHighlight = struct {
                        fn visit(node: *Node) void {
                            node.highlighted = false;
                        }
                }.visit;
                avl.traverseInOrder(resetHighlight);
                _ = avl.search(inputValue); // Highlight visited nodes in search
                inputLength = 0;
            }
        }

        if (raylib.IsKeyPressed(raylib.KEY_ENTER)) {
            if (inputLength > 0) {
                const inputStr = inputBuffer[0..inputLength];
                const inputValue = try parseInput(inputStr);
                                const resetHighlight = struct {
                        fn visit(node: *Node) void {
                            node.highlighted = false;
                        }
                }.visit;
                avl.traverseInOrder(resetHighlight);
                
                try avl.remove(inputValue); // Remove the value from the AVL tree
                inputLength = 0;
            }
        }

        if (raylib.IsKeyPressed(raylib.KEY_K)) {
            if (valuesInserted < totalValues) {
                const value = @rem(random.int(i32), 201) - 100; // Generate a random value
                try avl.insert(value); // Insert the value into the AVL tree
                valuesInserted += 1;
            }
        } else {
            const key = raylib.GetCharPressed();

            if (key != 0 and inputLength < inputBuffer.len) {
                inputBuffer[inputLength] = @intCast(key);
                inputLength += 1;
            }
        }

        // Drawing logic
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);
        if (avl.root) |nonNullNode| {
            drawTree(nonNullNode, 400, 50, 200);
        }
        raylib.DrawText("Press K to insert a random value", 10, 10, 20, raylib.GRAY);
        raylib.DrawText("Press ENTER to delete a value", 10, 40, 20, raylib.GRAY);
        raylib.DrawText("Press TAB to search for a value", 10, 70, 20, raylib.GRAY);
    }
}

fn parseInput(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10);
}

fn drawTree(node: *Node, x: f32, y: f32, offset: f32) void {
    if (node.left) |left| {
        drawConnection(node, left, x, y, x - offset, y + 100);
        drawTree(left, x - offset, y + 100, offset / 2);
    }

    if (node.right) |right| {
        drawConnection(node, right, x, y, x + offset, y + 100);
        drawTree(right, x + offset, y + 100, offset / 2);
    }

    drawNode(node, x, y);
}

fn drawConnection(_: *Node, child: *Node, startX: f32, startY: f32, endX: f32, endY: f32) void {
    const startPos = raylib.Vector2{ .x = startX, .y = startY };
    const endPos = raylib.Vector2{ .x = endX, .y = endY };

    const color = if (child.highlighted) raylib.RED else raylib.BLACK;
    raylib.DrawLineV(startPos, endPos, color);
}

fn drawNode(node: *Node, x: f32, y: f32) void {
    const color = if (node.highlighted) raylib.ORANGE else raylib.SKYBLUE;


    raylib.DrawCircleV(raylib.Vector2{ .x = x, .y = y }, 20, color);

    var buffer: [32]u8 = undefined;
    const keySlice = std.fmt.bufPrint(buffer[0..], "{}", .{node.key}) catch unreachable;

    buffer[keySlice.len] = 0; // Null-terminate the string

    raylib.DrawText(
        @ptrCast(&buffer[0]),
        @intFromFloat(x - 10),
        @intFromFloat(y - 10),
        20,
        raylib.BLACK
    );
}
