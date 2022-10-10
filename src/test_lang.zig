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

const MyTypes = struct {
    pub const U8Type = MyType(u8);
    pub const I8Type = MyType(i8);
};

fn MyType(comptime T: type) type {
    return struct {
        const Self = @This();

        v: T,
        pub fn init(v: T) Self {
            return Self{ .v = v };
        }
        pub fn get(self: Self) T {
            return self.v;
        }
    };
}
fn sum(my_type: MyTypes.U8Type) u8 {
    return my_type.get() + 10;
}

test "allocation patterns" {
    var static_alloc1: [16]u8 = undefined;
    try std.testing.expectEqual(16, static_alloc1.len);

    const size: usize = 16;
    var static_alloc2: [size]u8 = undefined;
    try std.testing.expectEqual(16, static_alloc2.len);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var runtime_alloc = try allocator.alloc(u8, 16);
    defer allocator.free(runtime_alloc);
    try std.testing.expectEqual(size, runtime_alloc.len);
}

test "value as type" {
    const t = MyType(u8).init(10);
    const expect: u8 = 20;
    try std.testing.expectEqual(expect, sum(t));
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

test "type name and mutability check for ref/deref and mut/imut combinations" {
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

test "reference/copy and mutability check" {
    const _const = [2]u8{1,2};
    var _var_const_copy = _const;
    // _const[1] = 15;
    _var_const_copy[1] = 16;

    const not_changed: u8 = 2;
    const changed: u8 = 16;
    try std.testing.expectEqual(not_changed, _const[1]);
    try std.testing.expectEqual(changed, _var_const_copy[1]);

    const _ref_const = &[2]u8{1,2};
    var _var_ref_const = _ref_const;
    var _var_ref_const_deref = _ref_const.*;
    // _ref_const[1] = 14;
    // _var_ref_const[1] = 15;
    _var_ref_const_deref[1] = 16;

    try std.testing.expectEqual(not_changed, _ref_const[1]);
    try std.testing.expectEqual(not_changed, _var_ref_const[1]);
    try std.testing.expectEqual(changed, _var_ref_const_deref[1]);

    var _var = [2]u8{1,2};
    var _var_copy = _var;
    var _var_ref = &_var;
    _var_copy[1] = 16;

    try std.testing.expectEqual(not_changed, _var[1]);
    try std.testing.expectEqual(changed, _var_copy[1]);

    _var_ref[1] = 16;
    try std.testing.expectEqual(changed, _var[1]);

    var _ref_var = &[2]u8{1,2};
    var _ref_var_deref = _ref_var.*;
    _ref_var_deref[1] = 16;

    try std.testing.expectEqual(changed, _ref_var_deref[1]);
    try std.testing.expectEqual(not_changed, _ref_var[1]);
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