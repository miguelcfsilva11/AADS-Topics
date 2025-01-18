const std = @import("std");

pub const SkipList = struct {
    const Allocator = std.mem.Allocator;
    const maxLevel = 8;

    pub const Node = struct {
        key: i32,
        forward: []?*Node,
        highlighted: bool,
    };

    header: *Node,
    tail: *Node,
    seed: u64,
    rng: std.rand.DefaultPrng,
    maxLevel: usize,
    probability: f64,
    level: usize,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator, probability: f64, seed: u64) SkipList {
        const rng = std.rand.DefaultPrng.init(seed);

        var header = allocator.create(Node) catch unreachable;
        var tail = allocator.create(Node) catch unreachable;

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

        return SkipList{
            .seed = seed,
            .maxLevel = comptime maxLevel,
            .probability = probability,
            .header = header,
            .tail = tail,
            .rng = rng,
            .level = 0,
            .allocator = allocator,
        };
    }

    fn randomLevel(self: *SkipList) usize {
        var lvl: usize = 0;
        while (self.rng.random().float(f64) < self.probability and lvl < self.maxLevel) {
            lvl += 1;
        }
        return lvl;
    }

    pub fn traverse(self: *SkipList, visit: fn(*Node) void) void {
        var current = self.header;
        while (current.forward[0]) |c| {
            visit(c);
            current = c;
        }
    }

    fn createNode(self: *SkipList, key: i32, _: usize) !*Node {
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

    pub fn insert(self: *SkipList, key: i32) !void {
        var update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
        defer self.allocator.free(update);

        var current = self.header;

        for (0..maxLevel + 1) |i| {
            
            while (current.forward[maxLevel - i] != null) {

                if (current.forward[maxLevel - i]) |node| {
                    if (node.key >= key) {
                        break;
                    }
                    current = node;

                }

            }
            update[maxLevel - i] = current;
        }

        const lvl = self.randomLevel();
        const newNode = try self.createNode(key, lvl);

        if (current.key != key) {

            if (lvl > self.level) {
                for (self.level + 1..lvl + 1) |j| {
                    update[j] = self.header;
                }
                self.level = lvl;
            }

          for (0..lvl + 1) |k| {
                if (update[k]) |node| {
                    newNode.forward[k] = node.forward[k];
                    node.forward[k] = newNode;
                }
            }


        }
    }

    pub fn search(self: *SkipList, key: i32) ?*Node {
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

    pub fn rangeSearch(self: *SkipList, start: i32, end: i32) ![]*Node {
        var current = self.header;
        const allocator =  std.heap.page_allocator;
        var result = std.ArrayList(*Node).init(allocator);

        errdefer result.deinit(); // Ensure cleanup on error

        // Traverse the SkipList level by level
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

        // traverse level 0 skiplist and keep adding until biggfer than end

        while (current.forward[0]) |forward| {
            if (forward.key > end) {
                break;
            }
            try result.append(forward);
            current = forward;
        }

        return try result.toOwnedSlice(); // Return the slice of nodes
    }

    pub fn remove(self: *SkipList, key: i32) !void {

        var update = try self.allocator.alloc(?*Node, maxLevel + 1);
        
        defer self.allocator.free(update);

        var current = self.header;

        inline for (0..maxLevel + 1) |i| {
            

            while (current.forward[maxLevel - i]) |forward| {

                update[maxLevel - i] = current;

                if (forward.key >= key) {
                    break;
                }
                else {
                    current = forward;
                }
                
            }
        }

        


        if (current.forward[0]) |next| {

            if (next.key == key) {
                inline for (0..maxLevel + 1) |j| {

                    if (self.level >= j) {
                        if (update[j]) |node| {
                            if (next.forward[j]) |forward| {
                                //std.debug.print("Setting forward of node with key: {d} to {d}\n", .{node.key, forward.key});
                                node.forward[j] = forward;
                                
                            }
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
    }

    pub fn deinit(self: *SkipList) void {
        var current = self.header;
        while (current != null) {
            const next = current.?.forward[0];
            self.allocator.destroy(current.?);
            current = next;
        }
    }
};