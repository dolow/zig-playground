const std = @import("std");

fn TestType(comptime T: type) type {
    return struct {
        const Self = @This();
        i: T,

        pub fn init(v: T) Self {
            return Self{ .i = v };
        }

        // manipulating value, can not compile with const self
        // pub fn set(self: Self, i: T) void

        pub fn set(self: *Self, i: T) void {
            self.i = i;
        }
        pub fn imut_get(self: Self) T {
            return self.i;
        }
        pub fn mut_get(self: *Self) T {
            return self.i;
        }
    };
}

pub fn expectComptimeEqual(comptime T: type, expected: T, actual: T) !void {
    try std.testing.expectEqual(expected, actual);
}

test "array range" {
    const arr = [10]u8{1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    const arr2_4 = arr[2..4];

    try std.testing.expectEqual(2, arr2_4.len);
    try std.testing.expectEqual(3, arr2_4[0]);
    try std.testing.expectEqual(4, arr2_4[1]);
}

test "ref/deref self arg test" {
    const first_expect = 1;
    var t = TestType(u8).init(first_expect);
    try expectComptimeEqual(u8, first_expect, t.imut_get());
    try expectComptimeEqual(u8, first_expect, t.mut_get());

    const second_expect = 2;
    t.set(second_expect);
    try expectComptimeEqual(u8, second_expect, t.imut_get());
    try expectComptimeEqual(u8, second_expect, t.mut_get());
    
    const third_expect = 3;
    const t2 = TestType(u8).init(third_expect);
    try expectComptimeEqual(u8, third_expect, t2.imut_get());
    // try std.testing.expectEqual(true, (0 == t2.mut_get()));
}

test "ref/deref, mut/imut test" {
    var _var = TestType(u8).init(0);
    var _var_ptr = &TestType(u8).init(0);
    const _const = TestType(u8).init(0);
    const _const_ptr = &TestType(u8).init(0);

    const _var_to_const = _var;
    const _var_ptr_to_const = _var_ptr;
    var _const_to_var = _const;
    var _const_ptr_to_var = _const_ptr;

    const _var_ptr_deref_to_const = _var_ptr.*;
    const _const_ptr_deref_to_const = _const_ptr.*;
    var _var_ptr_deref_to_var = _var_ptr.*;
    var _const_ptr_deref_to_var = _const_ptr.*;

    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_var)));
    try std.testing.expectEqualStrings("*test_lang.TestType(u8)", @typeName(@TypeOf(&_var)));

    try std.testing.expectEqualStrings("*const test_lang.TestType(u8)", @typeName(@TypeOf(_var_ptr)));
    try std.testing.expectEqualStrings("**const test_lang.TestType(u8)", @typeName(@TypeOf(&_var_ptr)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_var_ptr.*)));

    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_const)));
    try std.testing.expectEqualStrings("*const test_lang.TestType(u8)", @typeName(@TypeOf(&_const)));

    try std.testing.expectEqualStrings("*const test_lang.TestType(u8)", @typeName(@TypeOf(_const_ptr)));
    try std.testing.expectEqualStrings("*const *const test_lang.TestType(u8)", @typeName(@TypeOf(&_const_ptr)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_const_ptr.*)));

    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_var_to_const)));
    try std.testing.expectEqualStrings("*const test_lang.TestType(u8)", @typeName(@TypeOf(_var_ptr_to_const)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_const_to_var)));
    try std.testing.expectEqualStrings("*const test_lang.TestType(u8)", @typeName(@TypeOf(_const_ptr_to_var)));

    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_var_ptr_deref_to_const)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_const_ptr_deref_to_const)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_var_ptr_deref_to_var)));
    try std.testing.expectEqualStrings("test_lang.TestType(u8)", @typeName(@TypeOf(_const_ptr_deref_to_var)));

    _var.set(1);
    // _var_ptr.set(1);
    // _const.set(1);
    // _const_ptr.set(1);
    // _var_to_const.set(1);
    // _var_ptr_to_const.set(1);
    _const_to_var.set(1);
    // _const_ptr_to_var.set(1);
    // _var_ptr_deref_to_const.set(1);
    // _const_ptr_deref_to_const.set(1);
    _var_ptr_deref_to_var.set(1);
    _const_ptr_deref_to_var.set(1);

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