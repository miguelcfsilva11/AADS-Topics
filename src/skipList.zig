const std = @import("std");


pub const SkipList = struct {
    const Allocator = std.mem.Allocator;

    pub const Node = struct {
        key: i32,
        forward: []?*Node,
        highlighted: bool,

        pub fn forward_nodes(self: ?*Node) NodeIterator {
            return NodeIterator.init(self);
        }
    };

    pub const NodeIterator = struct {
        current: ?*SkipList.Node,

        pub fn init(start: ?*SkipList.Node) NodeIterator {
            return NodeIterator{
                .current = start,
            };
        }

        pub fn next(self: *NodeIterator) ?*SkipList.Node {
            if (self.current == null) {
                return null;
            }
            const result = self.current;
            self.current = self.current.?.forward[0];
            return result;
        }
    };


    seed: u64,
    rng: std.rand.DefaultPrng,
    maxLevel: usize,
    probability: f64,
    header: ?*Node,
    tail: ?*Node,
    level: usize,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator, maxLevel: usize, probability: f64, seed: u64) SkipList {
        
        const rng = std.rand.DefaultPrng.init(seed); 

        return SkipList{
            .seed = seed,
            .maxLevel = maxLevel,
            .probability = probability,
            .header = null,
            .tail = null,
            .rng = rng,
            .level = 0,
            .allocator = allocator,
        };
    }

    fn randomLevel(self: *SkipList) usize {

        var lvl: usize = 0;
        var random = self.rng.random();

        while (random.float(f64) < self.probability and lvl < self.maxLevel) {
            lvl += 1;
            random = self.rng.random();

        }
        return lvl;
    }

    pub fn traverse(self: *SkipList, visit: fn(*Node)void) void {
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

        if (self.header == null) {
            self.header = try self.createNode(-2147483648, self.maxLevel); // -INF
            self.tail   = try self.createNode(2147483647, self.maxLevel); // INF

            for (0..self.maxLevel + 1) |i| {
                self.header.?.forward[i] = self.tail;
            }
        }

        const update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
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

    pub fn getHeader(self: *SkipList) !*Node {
        return self.header orelse return error.NullHeader;
    }


    pub fn search(self: *SkipList, key: i32) ?*Node {
        var current = self.header;
        
        var i: usize = self.level;
        while (i >= 0) : (i -= 1) {
            while (current.?.forward[i] != null and current.?.forward[i].?.key <= key) {
                current = current.?.forward[i];
                current.?.highlighted = true;
            }

            if (i == 0) {
                break;
            }
        }

        current.?.highlighted = true;

        if (current != null and current.?.key == key) {

            return current;
        }
        return null;
    }


    pub fn remove(self: *SkipList, key: i32) !void {
        const update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
        defer self.allocator.free(update);

        // Initialize the update array
        for (0..self.maxLevel + 1) |i| {
            update[i] = null;
        }

        var current = self.header;

        // Correct traversal to update pointers
        var i: usize = self.level - 1;
        while (true) {
            while (current.?.forward[i] != null and current.?.forward[i].?.key < key) {
                current = current.?.forward[i];
            }
            update[i] = current;

            if (i == 0) break;
            i -= 1;
        }

        current = current.?.forward[0];

        if (current != null and current.?.key == key) {
            // Unlink node properly
            for (0..current.?.forward.len) |j| {
                if (update[j] != null and update[j].?.forward[j] == current) {
                    update[j].?.forward[j] = current.?.forward[j];
                }
            }

            // Reduce level if necessary
            while (self.level > 0 and self.header.?.forward[self.level - 1] == null) {
                self.level -= 1;
            }

            // Free the node's forward array, then the node
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
