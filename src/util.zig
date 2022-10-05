const allocator = @import("./shared_allocator.zig").allocator;

pub fn appendStr(base: []u8, src: []u8) ![]u8 {
    var result = try allocator().alloc(u8, base.len + src.len);
    var i: usize = 0;
    while (i < base.len) : (i += 1) {
        result[i] = base[i];
    }
    while (i < base.len + src.len) : (i += 1) {
        result[i] = src[i - base.len];
    }   
    // std.mem.copy(alloc, result, base);
    // std.mem.copy(alloc, result[base.len], src);
    return result;
}

pub fn append(comptime T: type, base: []T, src: []T) ![]T {
    var result = try allocator().alloc(T, base.len + src.len);
    var i: usize = 0;
    while (i < base.len) : (i += 1) {
        result[i] = base[i];
    }
    while (i < base.len + src.len) : (i += 1) {
        result[i] = src[i - base.len];
    }   
    // std.mem.copy(alloc, result, base);
    // std.mem.copy(alloc, result[base.len], src);
    return result;
}

pub fn appendOne(comptime T: type, base: []T, src: T) ![]T {
    var result = try allocator().alloc(T, base.len + 1);
    var i: usize = 0;
    while (i < base.len) : (i += 1) {
        result[i] = base[i];
    }
    result[i] = src;
    return result;
}