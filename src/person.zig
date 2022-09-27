const std = @import("std");

pub const Person = struct {
    name: []const u8,
    age: i8,
};

pub const People = std.MultiArrayList(Person);

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;

test "premitive allocator of struct" {
    var people = People{};
    defer people.deinit(allocator());

    try std.testing.expectEqual(@as(usize, 0), people.len);

    const names = [2][]const u8{"my name 1", "my name 2"};

    var index: usize = 0;
    for (names) |name| {
        try people.append(allocator(), Person{ .name = names[index], .age = 22 });
        try std.testing.expectEqual(@as(usize, index + 1), people.len);
        try std.testing.expectEqual(name, people.get(index).name);
        index += 1;
    }
}