const std = @import("std");
const AVLTree = @import("./avl.zig").AVLTree;

const SkipList = @import("./skiplist.zig").SkipList;
const raylib = @cImport({
    @cInclude("raylib.h");
});

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    const numValues = 10000;
    const seed: u64 = 12345;
    var prng = std.rand.DefaultPrng.init(seed);
    var random = prng.random();

    var avl = AVLTree.init(&allocator);
    var skiplist = SkipList.init(&allocator, 4, 0.5, seed);
    var valuesInserted: usize = 0;
    const totalValues = numValues;

    raylib.InitWindow(1600, 1000, "Data Structure Visualization");
    defer raylib.CloseWindow();

    var inputBuffer: [32]u8 = [_]u8{0} ** 32;
    var inputLength: usize = 0;
    raylib.SetTargetFPS(60);

    var mode: enum { StartScreen, AVLTree, SkipList } = .StartScreen;

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(raylib.RAYWHITE);

        switch (mode) {
            .StartScreen => {
                raylib.DrawText("Choose Visualization", 300, 200, 30, raylib.BLACK);
                raylib.DrawText("Press A for AVL Tree", 300, 250, 20, raylib.GRAY);
                raylib.DrawText("Press S for SkipList", 300, 280, 20, raylib.GRAY);

                if (raylib.IsKeyPressed(raylib.KEY_A)) {
                    mode = .AVLTree;
                } else if (raylib.IsKeyPressed(raylib.KEY_S)) {
                    mode = .SkipList;
                }
            },
            .AVLTree => {
                if (handleAVLTree(&avl, &allocator, &prng, &random, &inputBuffer, &inputLength, &valuesInserted, totalValues)) {
                    mode = .StartScreen;
                }
            },
            .SkipList => {
                if (handleSkipList(&skiplist, &allocator, &prng, &random, &inputBuffer, &inputLength, &valuesInserted, totalValues)) {
                    mode = .StartScreen;
                }
            },
        }
    }
}

fn handleAVLTree(avl: *AVLTree, _: *std.mem.Allocator, _: *std.rand.DefaultPrng, random: *std.rand.Random, inputBuffer: *[32]u8, inputLength: *usize, valuesInserted: *usize, totalValues: usize) bool {
   
    var inputValue : i32 = 0;
    if (raylib.IsKeyPressed(raylib.KEY_BACKSPACE)) {
        return true;
    }

    if (raylib.IsKeyPressed(raylib.KEY_TAB)) {

        if (inputLength.* > 0) {
            inputValue = parseInput(inputBuffer[0..inputLength.*]) catch |err| {
                std.debug.print("Parse error: {}\n", .{err});
                // clear buffer
                inputLength.* = 0;
                return false;
            };

            avl.traverseInOrder(resetTreeHighlight);
            const result = avl.search(inputValue);

            if (result == null) {
                std.debug.print("Key not found: {}\n", .{inputValue});
            } else {
                std.debug.print("Key found: {}\n", .{inputValue});
            }

            inputLength.* = 0;
        }
    }

    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) {
        if (inputLength.* > 0) {
            inputValue = parseInput(inputBuffer[0..inputLength.*]) catch |err| {
                std.debug.print("Parse error: {}\n", .{err});
                inputLength.* = 0;

                return false;
            };
            avl.traverseInOrder(resetTreeHighlight);
            try avl.remove(inputValue);
            inputLength.* = 0;
        }
    }

    if (raylib.IsKeyPressed(raylib.KEY_K)) {
        if (valuesInserted.* < totalValues) {
            const value = @rem(random.int(i32), 201) - 100;
            
            avl.insert(value) catch |err| {
                std.debug.print("Insert error: {}\n", .{err});
                return false;
            };
            valuesInserted.* += 1;
        }
    } else {
        handleInput(inputBuffer, inputLength);
        if (inputLength.* > 0) {
            inputValue = parseInput(inputBuffer[0..inputLength.*]) catch  {
                    if (avl.root) |nonNullNode| {
                        drawTree(nonNullNode, 800, 100, 400);
                    }
                    drawInputValue(inputValue);  // Draw the input value on screen
                    drawControls();
                    // clear buffer
                    return false;
                };
        }
    }

    if (avl.root) |nonNullNode| {
        drawTree(nonNullNode, 800, 100, 400);
    }

    drawInputValue(inputValue);  // Draw the input value on screen
    drawControls();
    return false;
}

fn handleSkipList(skiplist: *SkipList, _: *std.mem.Allocator, _: *std.rand.DefaultPrng, random: *std.rand.Random, inputBuffer: *[32]u8, inputLength: *usize, valuesInserted: *usize, totalValues: usize) bool {
    if (raylib.IsKeyPressed(raylib.KEY_BACKSPACE)) {
        return true;
    }
    
    var inputValue: i32 = 0;

    if (raylib.IsKeyPressed(raylib.KEY_TAB)) {
        if (inputLength.* > 0) {
            inputValue = parseInput(inputBuffer[0..inputLength.*]) catch |err| {
                std.debug.print("Parse error: {}", .{err});
                inputLength.* = 0;
                return false;
            };

            skiplist.traverse(resetListHighlight);
            const result = skiplist.search(inputValue);
            if (result == null) {
                std.debug.print("Key not found: {}", .{inputValue});
            } else {
                std.debug.print("Key found: {}", .{inputValue});
            }
            inputLength.* = 0;
        }
    }


    if (raylib.IsKeyPressed(raylib.KEY_ENTER)) {
        if (inputLength.* > 0) {

            inputValue = parseInput(inputBuffer[0..inputLength.*]) catch |err| {
                std.debug.print("Parse error: {}\n", .{err});
                inputLength.* = 0;
                return false;
            };


            skiplist.traverse(resetListHighlight);

            skiplist.remove(inputValue) catch |err| {
                std.debug.print("Remove error: {}\n", .{err});
                return false;
            };

            std.debug.print("Key removed: {}\n", .{inputValue});
            inputLength.* = 0;
    
        }
    }

    if (raylib.IsKeyPressed(raylib.KEY_K)) {
        
        
        skiplist.traverse(resetListHighlight);

        if (valuesInserted.* < totalValues) {
            const value = @rem(random.int(i32), 201) - 100;
            skiplist.insert(value) catch |err| {
                std.debug.print("Insert error: {}\n", .{err});
                return false;
            };
            valuesInserted.* += 1;
        }
    } else {
        handleInput(inputBuffer, inputLength);
                if (inputLength.* > 0) {
                inputValue = parseInput(inputBuffer[0..inputLength.*]) catch  {
                        drawSkipList(skiplist);
                        drawInputValue(inputValue);  // Draw the input value on screen
                        drawControls();
                        // clear buffer
                        return false;
                };
        }
    }

    

    drawSkipList(skiplist);
    drawInputValue(inputValue);  // Draw the input value on screen
    drawControls();
    return false;
}

fn drawInputValue(inputValue: i32) void {
    var buffer: [32]u8 = undefined;
    const inputSlice = std.fmt.bufPrint(buffer[0..], "Input Value: {}", .{inputValue}) catch unreachable;
    buffer[inputSlice.len] = 0;

    raylib.DrawText(
        @ptrCast(&buffer[0]),
        10,   // X-position
        130,  // Y-position
        20,   // Font size
        raylib.DARKGRAY
    );
}

fn drawTree(node: *AVLTree.Node, x: f32, y: f32, offset: f32) void {
    if (node.left) |left| {
        drawConnection(node, left, x, y, x - offset, y + 100);
        drawTree(left, x - offset, y + 100, offset / 2);
    }

    if (node.right) |right| {
        drawConnection(node, right, x, y, x + offset, y + 100);
        drawTree(right, x + offset, y + 100, offset / 2);
    }

    drawAVLNode(node, x, y);
}

fn drawSkipList(skiplist: *SkipList) void {
    var x: f32 = 50;

    var current: ?* SkipList.Node = skiplist.getHeader() catch {
        // Handle the error here, maybe log or return
        return; // or continue without drawing
    };


    current = current.?.forward[0];

    const allocator = std.heap.page_allocator;
    const prevlist =  allocator.alloc(?i32, skiplist.maxLevel + 1) catch {
        return; // or continue without drawing
    };

    const postlist =  allocator.alloc(?i32, skiplist.maxLevel + 1) catch {
        return; // or continue without drawing
    };

    defer allocator.free(postlist);
    defer allocator.free(prevlist);

    // set list values to null

    for (0..skiplist.maxLevel + 1) |i| {
        prevlist[i] = null;
        postlist[i] = null;
    }
    
    while (true) {
        x += 100;

        var counter: usize = 0;


        for (0..current.?.forward.len) |i| {
            if (current.?.forward[i]) |_| {
                counter += 1;
            }
        }

        for (1..counter + 1) |k| {
            const fcounter: f32 = @floatFromInt(k);
            var minX: f32 = 0;
            var maxX: f32 = 0;

            if (prevlist[k - 1]) |previous|  {

                if (postlist[k - 1]) |post| {

                    const pprevious: f32 = @floatFromInt(post);
                    const fprevious: f32 = @floatFromInt(previous);

                    minX = if (x < fprevious) x else fprevious;
                    maxX = if (x > pprevious ) x else pprevious;

                    const startPos = raylib.Vector2{ .x = minX, .y = 425 - 25 * fcounter };
                    const endPos = raylib.Vector2{ .x = maxX, .y = 425 - 25 * fcounter };

                    raylib.DrawLineV(startPos, endPos, raylib.BLACK);

                }
                
            }
            else {
                minX = x ;
                maxX = x ;
            }

            const intMinX: i32 = @intFromFloat(minX);
            const intMaxX: i32 = @intFromFloat(maxX);

            prevlist[k - 1] =  intMinX;
            postlist[k - 1] =  intMaxX;

        }


        drawSkipListNode(current.?, x, 400, counter);
        if (current.?.forward[0].?.forward[0] == null) {
            break;
        }
        else {
            current = current.?.forward[0];
        }
        
    }

}


fn drawSkipListNode(node: *SkipList.Node, x: f32, y: f32, level: usize) void {
    const squareSize: i32 = 20;  // Size of each small square
    const spacing: i32 = 5;      // Space between squares

    const color = if (node.highlighted) raylib.ORANGE else raylib.SKYBLUE;

    const intx: i32 = @intFromFloat(x);
    const inty: i32 = @intFromFloat(y);

    // Calculate total height of stacked squares
    const intLevel: i32 = @intCast(level);
    const totalHeight: i32 = intLevel * (squareSize + spacing);

    // Start drawing from the top to stack down
    var i: i32 = 0;
    while (i < level) : (i += 1) {
        const offsetY: i32 = inty - i * (squareSize + spacing);
        raylib.DrawRectangle(intx - (squareSize / 2), offsetY, squareSize, squareSize, color);
    }
    

    // Draw the node's key centered on the top square
    drawNodeText(
        node.key,
        @floatFromInt(intx - @divFloor(squareSize, 4)),
        @floatFromInt(inty - @divFloor(totalHeight, 2))
    );
}



fn drawConnection(_: *AVLTree.Node, child: *AVLTree.Node, startX: f32, startY: f32, endX: f32, endY: f32) void {
    const startPos = raylib.Vector2{ .x = startX, .y = startY };
    const endPos = raylib.Vector2{ .x = endX, .y = endY };

    const color = if (child.highlighted) raylib.RED else raylib.BLACK;
    raylib.DrawLineV(startPos, endPos, color);
}



fn drawAVLNode(node: *AVLTree.Node, x: f32, y: f32) void {
    const color = if (node.highlighted) raylib.ORANGE else raylib.SKYBLUE;
    raylib.DrawCircleV(raylib.Vector2{ .x = x, .y = y }, 20, color);
    drawAVLNodeText(node.key, x, y);
}

fn drawAVLNodeText(key: i32, x: f32, y: f32) void {
    var buffer: [32]u8 = undefined;
    const keySlice = std.fmt.bufPrint(buffer[0..], "{}", .{key}) catch unreachable;
    buffer[keySlice.len] = 0;
    raylib.DrawText(@ptrCast(&buffer[0]), @intFromFloat(x - 10), @intFromFloat(y - 10), 20, raylib.BLACK);
}

fn drawNodeText(key: i32, x: f32, _: f32) void {
    var buffer: [32]u8 = undefined;
    const keySlice = std.fmt.bufPrint(buffer[0..], "{}", .{key}) catch unreachable;
    buffer[keySlice.len] = 0;

    const textWidth: i32 = raylib.MeasureText(@ptrCast(&buffer[0]), 20);
    const floatTW: f32 = @floatFromInt(textWidth);

    // Center the text horizontally and move it slightly below the square
    raylib.DrawText(
        @ptrCast(&buffer[0]),
        @intFromFloat(x - floatTW / 2),
        450,  // 5 pixels below the square
        20,
        raylib.BLACK
    );
}

fn drawControls() void {
    raylib.DrawText("Press BACKSPACE to return to start screen", 10, 10, 20, raylib.GRAY);
    raylib.DrawText("Press K to insert a random value", 10, 40, 20, raylib.GRAY);
    raylib.DrawText("Press ENTER to delete a value", 10, 70, 20, raylib.GRAY);
    raylib.DrawText("Press TAB to search for a value", 10, 100, 20, raylib.GRAY);
}

fn handleInput(inputBuffer: *[32]u8, inputLength: *usize) void {
    const key = raylib.GetCharPressed();
    if (key != 0 and inputLength.* < inputBuffer.len) {
        inputBuffer[inputLength.*] = @intCast(key);
        inputLength.* += 1;
    }
}

fn parseInput(input: []const u8) !i32 {
    return std.fmt.parseInt(i32, input, 10);
}

fn resetTreeHighlight(node: *AVLTree.Node) void {
    node.highlighted = false;
}

fn resetListHighlight(node: *SkipList.Node) void {
    node.highlighted = false;
}
