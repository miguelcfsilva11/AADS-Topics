const std = @import("std");
const print_steps = @import("config.zig").print_steps;

pub fn SkipList(comptime maxLevel: usize) type {
    return struct {
        const Self = @This();
        const Allocator = std.mem.Allocator;

        pub const Node = struct {
            key: i32,
            forward: []?*Node,
            highlighted: bool,
        };

        header: *Node,
        tail: *Node,
        seed: u64,
        rng: std.rand.DefaultPrng,
        probability: f64,
        level: usize,
        allocator: *Allocator,
        update: []?*Node,  
        maxLevel: usize = maxLevel,    

        pub fn init(allocator: *Allocator, probability: f64, seed: u64) Self {
            const rng = std.rand.DefaultPrng.init(seed);

            var header = allocator.create(Node) catch unreachable;
            var tail = allocator.create(Node) catch unreachable;
            const update = allocator.alloc(?*Node, maxLevel + 1) catch unreachable;

            header.* = Node{
                .key = -2147483648,
                .forward = allocator.alloc(?*Node, maxLevel + 1) catch unreachable,
                .highlighted = false,
            };

            tail.* = Node{
                .key = 2147483647,
                .forward = allocator.alloc(?*Node, maxLevel + 1) catch unreachable,
                .highlighted = false,
            };

            inline for (0..maxLevel + 1) |i| {
                header.forward[i] = tail;
                tail.forward[i] = null;
            }

            return Self{
                .seed = seed,
                .probability = probability,
                .header = header,
                .tail = tail,
                .rng = rng,
                .level = 0,
                .allocator = allocator,
                .update = update,
            };
        }

        fn randomLevel(self: *Self) usize {
            var lvl: usize = 0;
            while (self.rng.random().float(f64) < self.probability and lvl < maxLevel) {
                lvl += 1;
            }
            return lvl;
        }

        pub fn traverse(self: *Self, visit: fn(anytype) void) void {
            var current = self.header;
            while (current.forward[0]) |c| {
                visit(c);
                current = c;
            }
        }

        fn createNode(self: *Self, key: i32, _: usize) !*Node {
            const node_ptr = try self.allocator.create(Node);
            const forward = try self.allocator.alloc(?*Node, maxLevel + 1);
            node_ptr.* = Node{
                .key = key,
                .forward = forward,
                .highlighted = false,
            };

            inline for (0..maxLevel + 1) |i| {
                forward[i] = null;
            }



            return node_ptr;
        }

        pub fn insert(self: *Self, key: i32) !void {
            var current = self.header;

            for (0..maxLevel + 1) |i| {
                self.update[i] = null;
            }
            
            inline for (0..maxLevel + 1) |i| {
                while (current.forward[maxLevel - i] != null) {
                    if (current.forward[maxLevel - i]) |node| {

                        if (print_steps) {
                            std.debug.print("Visiting node with key: {d}\n", .{node.key});
                        }
                        if (node.key > key) {
                            break;
                        }
                        current = node;
                    }
                }
                self.update[maxLevel - i] = current;
            }

            const lvl = self.randomLevel();
            const newNode = try self.createNode(key, lvl);

            if (current.key == key)
                return; 

            if (lvl > self.level) {
                for (self.level + 1..lvl + 1) |j| {
                        self.update[j] = self.header;
                    }
                
                self.level = lvl;
            
            }

            for (0.. lvl + 1) |j| {
                if (self.update[j]) |node| {
                    newNode.forward[j] = node.forward[j];
                    node.forward[j] = newNode;
                }
            }

            if (print_steps) {
                std.debug.print("Inserted key: {d} with level: {d}\n", .{key, lvl});
            }
        }

        pub fn search(self: *Self, key: i32) ?*Node {
            var current = self.header;

            inline for (0..maxLevel + 1) |i| {
                if (self.level >= maxLevel - i) {

                    while (current.forward[maxLevel - i]) |forward| {
                        if (forward.key > key) {
                            break;
                        }
                        current.highlighted = true;
                        current = forward;
                    }
                }
            }
            current.highlighted = true;

            if (current.key == key) {
                return current;
            }
            return null;
        }

        pub fn rangeSearch(self: *Self, start: i32, end: i32) ![]*Node {
            var current = self.header;
            const allocator = std.heap.page_allocator;
            var result = std.ArrayList(*Node).init(allocator);

            errdefer result.deinit(); // Ensure cleanup on error

            if (print_steps)
                std.debug.print("Searching for range: {d} - {d}\n", .{start, end});

            inline for (0..maxLevel + 1) |i| {
                if (self.level >= maxLevel - i) {
                    if (print_steps)
                        std.debug.print("Searching level: {d}\n", .{maxLevel - i});
                    while (current.forward[maxLevel - i]) |forward| {
                        if (forward.key > start) {
                            break;
                        }
                        if (print_steps) {
                            std.debug.print("Visiting node with key: {d}\n", .{forward.key});
                        }
                        current = forward;
                    }
                }
            }

            if (current.key == start) {
                current.highlighted = true;
                try result.append(current);
            }

            while (current.forward[0]) |forward| {
                if (print_steps) {
                    std.debug.print("Visiting node with key: {d}\n", .{forward.key});
                }
                if (forward.key > end) {
                    break;
                }
                forward.highlighted = true;
                try result.append(forward);
                current = forward;
            }
            if (print_steps) {
                for (result.items) |node| {
                    std.debug.print("Found node with key: {d}\n", .{node.key});
                }
            }
            return try result.toOwnedSlice(); // Return the slice of nodes
        }

        pub fn totalSize(self: *Self) usize {
            var total_size: usize = 0;

            // Add size of the update array
            total_size += @sizeOf(?*Node) * (maxLevel + 1);

            // Add size of the header and tail nodes
            total_size += @sizeOf(Node);
            total_size += @sizeOf(Node);

            // Add size of the forward arrays for header and tail nodes
            total_size += (@sizeOf(?*Node) * (maxLevel + 1)) * 2;

            // Traverse the skip list and calculate size for all nodes
            var current = self.header.forward[0];
            while (current) |node| {
                total_size += @sizeOf(Node);
                total_size += @sizeOf(?*Node) * (maxLevel + 1);
                current = node.forward[0];
            }

            return total_size;
        }

        pub fn remove(self: *Self, key: i32) !void {


            var current = self.header;

            // reset update array
            for (0..maxLevel + 1) |i| {
                self.update[i] = null;
            }

            inline for (0..maxLevel + 1) |i| {
                while (current.forward[maxLevel - i]) |forward| {

                    self.update[maxLevel - i] = current;
                    if (forward.key >= key) {
                        break;
                    } else {
                        current = forward;
                    }
                }
            }

            if (current.forward[0]) |next| {
                if (next.key == key) {
                    inline for (0..maxLevel + 1) |j| {
                        if (self.level >= j) {
                            if (self.update[j]) |node| {
                                if (next.forward[j]) |forward| {
                                    node.forward[j] = forward;
                                }
                            }
                        }
                    }

                    while (self.level > 0 and self.header.forward[self.level] == null) {
                        self.level -= 1;
                    }

                    self.allocator.free(next.forward);

                    self.allocator.destroy(next);
                }

                else {
                    return;
                }


            }

            // TODO how to free memory dedicated to the  removed node

        }

        pub fn deinit(self: *Self) void {
            var current = self.header;
            while (current != null) {
                const next = current.?.forward[0];
                self.allocator.destroy(current.?);
                current = next;
            }
            self.allocator.free(self.update);
        }
    };
}