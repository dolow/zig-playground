const std = @import("std");

pub const Person = struct {
    name: []const u8,
    age: i8,
};

pub const People = std.MultiArrayList(Person);
