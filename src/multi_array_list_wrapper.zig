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

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;
const person = @import("./person.zig");

test "multi array list wrapper" {
    var wrapper = new_multi_array_list_wrapper(person.Person);
    defer wrapper.deinit();

    try std.testing.expectError(
        MultiArrayListWrapperError.AllocationNotBegan,
        wrapper.add(person.Person{ .name = "Smith", .age = 99 })
    );
    try std.testing.expectError(
        MultiArrayListWrapperError.IndexOutOfBounds,
        wrapper.at(0)
    );

    wrapper.set_allocator(allocator());

    const names = [2][]const u8{"John", "Noel"};

    var index: usize = 0;
    for (names) |name| {
        try wrapper.add(person.Person{ .name = names[index], .age = 22 });
        try std.testing.expectEqual(@as(usize, index + 1), wrapper.size());
        const p = try wrapper.at(index);
        try std.testing.expectEqual(name, p.name);
        index += 1;
    }
}