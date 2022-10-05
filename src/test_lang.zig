const std = @import("std");

test "array range" {
    const arr = [10]u8{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    const arr2_4 = arr[2..4];

    try std.testing.expectEqual(2, arr2_4.len);
    try std.testing.expectEqual(3, arr2_4[0]);
    try std.testing.expectEqual(4, arr2_4[1]);
}

test "assign and argument of u8 array" {
    const A = struct {
        const Self = @This();
        
        str: []const u8,

        pub fn setStr(self: *Self, s: []const u8) void {
            self.str = s;
        }
    };

    var a = A {
        .str = "foo",
    };

    try std.testing.expectEqualStrings("foo", a.str);

    a.str = "zoo";
    try std.testing.expectEqualStrings("zoo", a.str);

    const s = "bar";
    a.setStr(s);
    try std.testing.expectEqualStrings("bar", a.str);

    a.setStr("qux");
    try std.testing.expectEqualStrings("qux", a.str);

    const arr = [3]u8{'a', 'r', 'r'};
    a.setStr(&arr);
    
    try std.testing.expectEqualStrings("arr", a.str);
}