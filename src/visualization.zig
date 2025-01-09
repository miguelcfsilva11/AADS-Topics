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

    // Initialize Raylib window
    raylib.InitWindow(800, 600, "AVL Tree Visualization");
    defer raylib.CloseWindow();

    raylib.SetTargetFPS(60);

    while (!raylib.WindowShouldClose()) {
        // Check if it's time to insert a new value
        if (raylib.IsKeyPressed(raylib.KEY_ONE)) { // Check if the "1" key is pressed
            if (valuesInserted < totalValues) {
                const value = @rem(random.int(i32), 201) - 100; // Generate a random value
                try avl.insert(value); // Insert the value into the AVL tree
                valuesInserted += 1; // Increment the count of inserted values
            } else {
                raylib.DrawText("All values have been inserted!", 10, 60, 20, raylib.RED);
            }
        }


        // Drawing logic
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);
        if (avl.root) |nonNullNode| {
            drawTree(nonNullNode, 400, 50, 200);
        }
        raylib.DrawText("Inserting values dynamically...", 10, 10, 20, raylib.GRAY);
        raylib.DrawText("Press ESC to quit.", 10, 40, 20, raylib.GRAY);
    }
}

fn drawTree(node: *Node, x: f32, y: f32, offset: f32) void {
    if (node.left) |left| {
        const startPos = raylib.Vector2{ .x = x, .y = y };
        const endPos = raylib.Vector2{ .x = x - offset, .y = y + 100 };

        raylib.DrawLineV(startPos, endPos, raylib.BLACK);
        drawTree(left, x - offset, y + 100, offset / 2);
    }

    if (node.right) |right| {
        const startPos = raylib.Vector2{ .x = x, .y = y };
        const endPos = raylib.Vector2{ .x = x + offset, .y = y + 100 };

        raylib.DrawLineV(startPos, endPos, raylib.BLACK);
        drawTree(right, x + offset, y + 100, offset / 2);
    }

    raylib.DrawCircleV(raylib.Vector2{ .x = x, .y = y }, 20, raylib.SKYBLUE);

    var buffer: [32]u8 = undefined;
    const keySlice = std.fmt.bufPrint(buffer[0..], "{}", .{node.key}) catch unreachable;

    // Null-terminate the string
    buffer[keySlice.len] = 0;

    raylib.DrawText(
        @ptrCast(&buffer[0]),             // C-style string
        @intFromFloat(x - 10),            // x position (c_int)
        @intFromFloat(y - 10),            // y position (c_int)
        20,                               // Font size (c_int)
        raylib.BLACK                      // Color
    );
}
