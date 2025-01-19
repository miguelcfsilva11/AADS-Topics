const std = @import("std");

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

        pub fn traverse(self: *Self, visit: fn(*Node) void) void {
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

            std.debug.print("New node with key: {d} and level: {d}\n", .{key, lvl});
            std.debug.print("Current key: {d}\n", .{current.key});
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

            if (current.key == key) {
                current.highlighted = true;
                return current;
            }
            return null;
        }

        pub fn rangeSearch(self: *Self, start: i32, end: i32) ![]*Node {
            var current = self.header;
            const allocator = std.heap.page_allocator;
            var result = std.ArrayList(*Node).init(allocator);

            errdefer result.deinit(); // Ensure cleanup on error

            inline for (0..maxLevel + 1) |i| {
                if (self.level >= maxLevel - i) {
                    while (current.forward[maxLevel - i]) |forward| {
                        if (forward.key > start) {
                            break;
                        }
                        current.highlighted = true;
                        current = forward;
                    }
                }
            }

            while (current.forward[0]) |forward| {
                if (forward.key > end) {
                    break;
                }
                try result.append(forward);
                current = forward;
            }

            return try result.toOwnedSlice(); // Return the slice of nodes
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