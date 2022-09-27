const std = @import("std");

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

    try std.testing.expectEqualStrings(a.str, "foo");

    a.str = "zoo";
    try std.testing.expectEqualStrings(a.str, "zoo");

    const s = "bar";
    a.setStr(s);
    try std.testing.expectEqualStrings(a.str, "bar");

    a.setStr("qux");
    try std.testing.expectEqualStrings(a.str, "qux");

    const arr = [3]u8{'a', 'r', 'r'};
    a.setStr(&arr);
    
    try std.testing.expectEqualStrings(a.str, "arr");
}