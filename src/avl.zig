const std = @import("std");

pub const AVLTree = struct {
    const Allocator = std.mem.Allocator;

    pub const Node = struct {
        key: i32,
        height: usize,
        left: ?*Node,
        right: ?*Node,
    };

    root: ?*Node,
    allocator: *Allocator,

    pub fn init(allocator: *Allocator) AVLTree {
        return AVLTree{
            .root = null,
            .allocator = allocator,
        };
    }

    fn nodeHeight(node: ?*Node) usize {
        return if (node == null) 0 else |actual_node| usize(actual_node.height);
    }

    fn updateHeight(node: *Node) void {
        node.height = std.math.max(nodeHeight(node.left), nodeHeight(node.right)) + 1;
    }

    fn balanceFactor(node: ?*Node) i32 {
        return if (node == null) 0 else nodeHeight(node.left) - nodeHeight(node.right);
    }

    fn rotateRight(y: *Node) *Node {
        var x = y.left.?;
        y.left = x.right;
        x.right = y;

        updateHeight(y);
        updateHeight(x);

        return x;
    }

    fn rotateLeft(x: *Node) *Node {
        var y = x.right.?;
        x.right = y.left;
        y.left = x;

        updateHeight(x);
        updateHeight(y);

        return y;
    }

    fn balance(node: *Node) *Node {
        updateHeight(node);

        const bf = balanceFactor(node);

        if (bf > 1) {
            if (balanceFactor(node.left.?) < 0) {
                node.left = rotateLeft(node.left.?);
            }
            return rotateRight(node);
        } else if (bf < -1) {
            if (balanceFactor(node.right.?) > 0) {
                node.right = rotateRight(node.right.?);
            }
            return rotateLeft(node);
        }

        return node;
    }

    fn insertNode(self: *AVLTree, node: ?*Node, key: i32) ?*Node {
        if (node == null) {
            return self.allocator.create(Node){
                .key = key,
                .height = 1,
                .left = null,
                .right = null,
            };
        }

        if (key < node.?.key) {
            node.?.left = insertNode(self, node.?.left, key);
        } else if (key > node.?.key) {
            node.?.right = insertNode(self, node.?.right, key);
        } else {
            // Duplicate keys are not allowed
            return node;
        }

        return balance(node.?);
    }

    pub fn insert(self: *AVLTree, key: i32) void {
        self.root = insertNode(self, self.root, key);
    }

    fn inOrderTraversal(node: ?*Node, visit: fn (i32) void) void {
        if (node == null) return null;

        inOrderTraversal(node.?.left, visit);
        visit(node.?.key);
        inOrderTraversal(node.?.right, visit);
    }

    pub fn search(self: *AVLTree, key: i32) ?*Node {
        var current = self.root;
        while (current != null) {
            if (key < current.?.key) {
                current = current.?.left;
            } else if (key > current.?.key) {
                current = current.?.right;
            } else {
                return current;
            }
        }
        return null;
    }

    pub fn rangeSearch(self: *AVLTree, low: i32, high: i32) ![]?*Node {
        var nodes = try self.allocator.alloc(?*Node, 0);
        var queue = try self.allocator.alloc(?*Node, 0);

        defer self.allocator.free(queue);

        if (self.root != null) {
            try queue.append(self.root.?);
        }

        while (queue.len > 0) {
            const current = queue[0];

            // Shift the queue to the left
            for (queue[1..], 0..) |item, i| {
                queue[i] = item;
            }
            queue.len -= 1;

            if (current != null) {
                const node = current.?;

                if (low <= node.key and node.key <= high) {
                    try nodes.append(current);
                }

                if (node.key > low and node.left != null) {
                    try queue.append(node.left.?);
                }

                if (node.key < high and node.right != null) {
                    try queue.append(node.right.?);
                }
            }
        }

        return nodes;
    }

    pub fn traverseInOrder(self: *AVLTree, visit: fn (i32) void) void {
        inOrderTraversal(self.root, visit);
    }

    pub fn deinit(self: *AVLTree) void {
        // Define the freeNode function inside deinit
        const freeNode = struct {
            fn impl(node: ?*Node, allocator: *std.mem.Allocator) void {
                if (node == null) return;

                // Unwrap the optional safely
                const actual_node = node.?;
                impl(actual_node.left, allocator);
                impl(actual_node.right, allocator);
                allocator.destroy(actual_node);
            }
        }.impl;

        // Call the freeNode function
        freeNode(self.root, self.allocator);
        self.root = null;
    }
};
