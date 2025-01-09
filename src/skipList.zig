const std = @import("std");

pub const SkipList = struct {
    const Allocator = std.mem.Allocator;

    pub const Node = struct {
        key: i32,
        forward: []?*Node,
        
    };

    maxLevel: usize,
    probability: f64,
    header: ?*Node,
    level: usize,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator, maxLevel: usize, probability: f64) SkipList {
        return SkipList{
            .maxLevel = maxLevel,
            .probability = probability,
            .header = null,
            .level = 0,
            .allocator = allocator,
        };
    }

    fn randomLevel(self: *SkipList) usize {
        var lvl: usize = 0;
        while (std.math.rand.random(self.probability) < self.probability and lvl < self.maxLevel) {
            lvl += 1;
        }
        return lvl;
    }

    fn createNode(self: *SkipList, key: i32, level: usize) ?*Node {
        return self.allocator.create(Node){
            .key = key,
            .forward = try self.allocator.alloc(?*Node, level + 1),
        };
    }

    pub fn insert(self: *SkipList, key: i32) !void {
        const update = try self.allocator.alloc(?*Node, self.maxLevel + 1);
        defer self.allocator.free(update);

        var current = self.header;

        var i: usize = self.level;
        while (i > 0) : (i -= 1) {
            while (current.?.forward[i] != null and current.?.forward[i].?.key < key) {
                current = current.?.forward[i];
            }
            
            update[i] = current;        
        }

        current = current.?.forward[0];

        if (current == null or current.?.key != key) {
            const lvl = self.randomLevel();
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
        while (i > 0) : (i -= 1) {
            while (current.?.forward[i] != null and current.?.forward[i].?.key < key) {
                current = current.?.forward[i];
            }
        }


        current = current.?.forward[0];
        if (current != null and current.?.key == key) {
            return current;
        }
        return null;
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
