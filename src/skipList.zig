const std = @import("std");

pub const SkipList = struct {
    const Allocator = std.mem.Allocator;
    const maxLevel = 4; // Define the max level as a compile-time constant

    pub const Node = struct {
        key: i32,
        forward: []?*Node,
        highlighted: bool,
    };

    header: ?*Node,
    tail: ?*Node,
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
        while (current != null) {
            visit(current.?);
            current = current.?.forward[0];
        }
    }

    fn createNode(self: *SkipList, key: i32, level: usize) !*Node {
        const node_ptr = try self.allocator.create(Node);
        const forward = try self.allocator.alloc(?*Node, level + 1);
        node_ptr.* = Node{
            .key = key,
            .forward = forward,
            .highlighted = false,
        };

        for (0..level + 1) |i| {
            forward[i] = null;
        }

        return node_ptr;
    }

    pub fn insert(self: *SkipList, key: i32) !void {
        var update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
        defer self.allocator.free(update);

        var current = self.header;

        var i: usize = self.level;
        while (i >= 0) : (i -= 1) {
            while (current.?.forward[i] != null and current.?.forward[i].?.key < key) {
                current = current.?.forward[i];
            }
            update[i] = current;
            if (i == 0) break;
        }

        current = current.?.forward[0];
        const lvl = self.randomLevel();
        if (current == null or current.?.key != key) {
            if (lvl > self.level) {
                for (self.level + 1..lvl + 1) |j| {
                    update[j] = self.header;
                }
                self.level = lvl;
            }

            const newNode = try self.createNode(key, lvl);

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

        var i: usize = self.level;
        while (true) {
            while (current != null and current.?.forward[i] != null and current.?.forward[i].?.key <= key) {
                current = current.?.forward[i];
            }

            if (i == 0) {
                break;
            }
            i -= 1;
        }

        if (current != null and current.?.key == key) {
            current.?.highlighted = true;
            return current;
        }
        return null;
    }

    pub fn rangeSearch(self: *SkipList, start: i32, end: i32) ![]*Node {
        var current = self.header;
        var i: usize = self.level;

        while (true) {
            while (current != null and current.?.forward[i] != null and current.?.forward[i].?.key <= start) {
                current = current.?.forward[i];
            }

            if (i == 0) {
                break;
            }
            i -= 1;
        }

        var result = std.ArrayList(*Node).init(self.allocator);
        defer result.deinit();

        while (current != null and current.?.key <= end) {
            try result.append(current.?);
            current = current.?.forward[0];
        }

        return result.toOwnedSlice();
    }

    pub fn remove(self: *SkipList, key: i32) !void {
        var update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
        defer self.allocator.free(update);

        var current = self.header;

        var i: usize = self.level;
        while (true) {
            while (current != null and current.?.forward[i] != null and current.?.forward[i].?.key < key) {
                current = current.?.forward[i];
            }

            update[i] = current;
            if (i == 0) {
                break;
            }
            i -= 1;
        }

        current = current.?.forward[0];

        if (current != null and current.?.key == key) {
            for (0..current.?.forward.len) |j| {
                if (update[j] != null and update[j].?.forward[j] == current) {
                    update[j].?.forward[j] = current.?.forward[j];
                }
            }

            while (self.level > 0 and self.header.?.forward[self.level] == null) {
                self.level -= 1;
            }

            self.allocator.free(current.?.forward);
            self.allocator.destroy(current.?);
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