const std = @import("std");

pub const MultiArrayListWrapperError = error {
    AllocationNotBegan,
    IndexOutOfBounds,
};

pub fn MultiArrayListWrapper(comptime T: type) type {
    return struct {
        const Self = @This();

        elements: std.MultiArrayList(T),
        alloc: ?std.mem.Allocator,

        pub fn add(self: *Self, element: T) !void {
            if (self.alloc == null) {
                return MultiArrayListWrapperError.AllocationNotBegan;
            }
            try self.elements.append(self.alloc.?, element);
        }

        pub fn at(self: *Self, index: usize) !T {
            if (index >= self.elements.len) {
                return MultiArrayListWrapperError.IndexOutOfBounds;
            }
            return self.elements.get(index);
        }

        pub fn size(self: *Self) usize {
            return self.elements.len;
        }

        pub fn set_allocator(self: *Self, alloc: std.mem.Allocator) void {
            self.alloc = alloc;
        }
        pub fn clear_allocator(self: *Self) void {
            self.alloc = null;
        }

        pub fn deinit(self: *Self) void {
            if (self.alloc == null) {
                return;
            }
            self.elements.deinit(self.alloc.?);
            self.clear_allocator();
        }
    };
}

pub fn new_multi_array_list_wrapper(comptime T: type) MultiArrayListWrapper(T) {
    return .{
        .elements = std.MultiArrayList(T){},
        .alloc = null,
    };
}