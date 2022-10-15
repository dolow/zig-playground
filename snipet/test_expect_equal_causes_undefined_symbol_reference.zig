const std = @import("std");

fn TestType(comptime T: type) type {
    return struct {
        const Self = @This();
        i: T,

        pub fn init(v: T) Self {
            return Self{ .i = v };
        }
        pub fn get(self: *Self) T {
            return self.i;
        }
    };
}

test "const_test" {
    const first_expect = 1;
    var t = TestType(u8).init(first_expect);
    // it's ok
    try std.testing.expectEqual(true, (first_expect == t.get()));
    // it's not ok
    // try std.testing.expectEqual(first_expect, t.get());

    // wrapped
    try expectComptimeEqual(u8, first_expect, t.get());
    // using built in function @as
    // https://ziglang.org/documentation/0.9.1/#as
    try std.testing.expectEqual(@as(u8, first_expect), t.get());
}

// @TypeOf(anytype) for comptime type causes UndefinedSymbolError
pub fn expectComptimeEqual(comptime T: type, expected: T, actual: T) !void {
    try std.testing.expectEqual(expected, actual);
}