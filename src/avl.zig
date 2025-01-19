const std = @import("std");
const print_steps: bool = @import("config.zig").print_steps;

pub const AVLTree = struct {
    const Allocator = std.mem.Allocator;

    pub const Node = struct {
        key: i32,
        height: usize,
        left: ?*Node,
        right: ?*Node,
        highlighted: bool, // New field to track if a node is highlighted
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
        if (node == null) {
            return 0;
        }

        const actual_node = node.?;
        return actual_node.height;
    }

    fn updateHeight(node: *Node) void {
        node.height = @max(nodeHeight(node.left), nodeHeight(node.right)) + 1;
    }

    fn balanceFactor(node: ?*Node) i32 {
        if (node == null) {
            return 0;
        }

        const actual_node = node.?;
        const left_height: i32 = @intCast(nodeHeight(actual_node.left));
        const right_height: i32 = @intCast(nodeHeight(actual_node.right)); // Cast to i32

        return left_height - right_height;
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

    fn insertNode(self: *AVLTree, node: ?*Node, key: i32) !*Node {
        
        if (node == null) {
            if (print_steps)
                std.debug.print("Inserting key: {d}\n", .{key});
            const newNode = try self.allocator.create(Node);
            newNode.* = Node{
                .key = key,
                .height = 1,
                .left = null,
                .right = null,
                .highlighted = false, // Initialize as not highlighted
            };
            return newNode;
        }
        
        if (print_steps)
            std.debug.print("Visiting node with key: {d}\n", .{node.?.key});
        if (key < node.?.key) {
            node.?.left = try insertNode(self, node.?.left, key);
        } else if (key > node.?.key) {
            node.?.right = try insertNode(self, node.?.right, key);
        } else {
            if (print_steps)
                std.debug.print("Key {d} already exists in the tree\n", .{key});
            return node.?;
        }

        return balance(node.?);
    }

    pub fn insert(self: *AVLTree, key: i32) !void {
        self.root = try insertNode(self, self.root, key);
    }

        
    fn inOrderTraversal(root: ?*Node, visit: fn (anytype) void) void {
        var stack: [256]?*Node = [_]?*Node{null} ** 256;
        var stackTop: usize = 0;
        var current: ?*Node = root;

        while (current != null or stackTop > 0) {
            while (current != null) {
                if (stackTop >= stack.len) {
                    std.debug.panic("Stack overflow during traversal", .{});
                }
                stack[stackTop] = current;
                stackTop += 1;
                current = current.?.left;
            }

            stackTop -= 1;
            current = stack[stackTop];

            if (current) |actualNode| {
                visit(actualNode);
            }

            current = current.?.right;
        }
    }


    pub fn search(self: *AVLTree, key: i32) ?*Node {
        var current = self.root;

        if (print_steps)
            std.debug.print("Looking for key: {d}\n", .{key});
        while (current != null) {
            if (print_steps)
                std.debug.print("Visiting node with key: {d}\n", .{current.?.key});

            current.?.highlighted = true; // Mark node as visited
            if (key < current.?.key) {
                current = current.?.left;
            } else if (key > current.?.key) {
                current = current.?.right;
            } else {
                if (print_steps)
                    std.debug.print("Found key: {d}\n", .{current.?.key});
                return current;
            }
        }
        return null;
    }

    pub fn remove(self: *AVLTree, key: i32) !void {
        self.root = try self.removeNode(self.root, key);
    }

    fn findMin(_: *AVLTree, node: *Node) *Node {
        var current = node;
        while (current.left != null) {
            current = current.left.?;
        }
        return current;
    }

    fn removeNode(self: *AVLTree, node: ?*Node, key: i32) !?*Node {
        if (node == null) {
            return null;
        }

        if (print_steps)
            std.debug.print("Visiting node with key: {d}\n", .{node.?.key});

        if (key < node.?.key) {
            node.?.left = try self.removeNode(node.?.left, key);
        } else if (key > node.?.key) {
            node.?.right = try self.removeNode(node.?.right, key);
        } else {
            
            if (print_steps)
                std.debug.print("Removing node with key: {d}\n", .{node.?.key});


            if (node.?.left == null and node.?.right == null) {
                // Case: Node with no children
                self.allocator.destroy(node.?);
                return null;
            } else if (node.?.left == null) {
                // Case: Node with only right child
                const temp = node.?.right;
                self.allocator.destroy(node.?);
                return temp;
            } else if (node.?.right == null) {
                // Case: Node with only left child
                const temp = node.?.left;
                self.allocator.destroy(node.?);
                return temp;

            } else {

                const temp = self.findMin(node.?.right.?);
                node.?.key = temp.key;
                node.?.right = try self.removeNode(node.?.right, temp.key);
            }
        }

        return balance(node.?);
    }

    pub fn searchHelper(node: ?*Node, low: i32, high: i32, nodes: *std.ArrayList(?*Node)) !void {
        if (node == null) return;

        if (print_steps)
            std.debug.print("Visiting node with key: {d}\n", .{node.?.key});

        const current = node.?;

        // Traverse left subtree only if current key > low
        if (current.key > low) {
            try searchHelper(current.left, low, high, nodes);
        }

        // Add current node if it's within the range
        if (low <= current.key and current.key <= high) {

            if (print_steps) {
                std.debug.print("Adding node with key: {d}\n", .{current.key});
            }
            node.?.highlighted = true; // Mark node as visited
            try nodes.append(node);
        }

        // Traverse right subtree only if current key < high
        if (current.key < high) {
            try searchHelper(current.right, low, high, nodes);
        }
    }

    pub fn rangeSearch(self: *AVLTree, low: i32, high: i32) ![]?*Node {
        const allocator = std.heap.page_allocator;
        var nodes = std.ArrayList(?*Node).init(allocator);
        defer nodes.deinit();

        try searchHelper(self.root, low, high, &nodes);

        return try nodes.toOwnedSlice();
    }


    pub fn traverse(self: *AVLTree, visit: fn (anytype) void) void {
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
