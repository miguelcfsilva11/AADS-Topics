const std = @import("std");

pub const ExecutionMetrics = struct {
    structure_type: []const u8,  // Name of the data structure
    insertions: i128,            // Time for total insertions (e.g., in nanoseconds)
    searches: i128,              // Time for searches
    rangeSearches: i128,         // Time for range searches
    deletions: i128,             // Time for deletions
    memory: usize,              // Memory usage in bytes
    size: usize,                // Size of the data structure

    pub fn init(structure_type: []const u8) ExecutionMetrics {
        return ExecutionMetrics{
            .structure_type = structure_type,
            .insertions = 0,
            .searches = 0,
            .rangeSearches = 0,
            .deletions = 0,
            .memory = 0,
            .size = 0,
        };
    }

    pub fn toCSV(self: *ExecutionMetrics, allocator: *std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator.*, 
            "{s},{?},{?},{?},{?},{?},{?}\n",
            .{
                self.structure_type,
                self.insertions,
                self.searches,
                self.rangeSearches,
                self.deletions,
                self.memory,
                self.size,
            }
        );
    }
};
