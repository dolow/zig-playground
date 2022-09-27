const std = @import("std");
const fs = std.fs;
const json = std.json;
const io = std.io;

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;
const deinit_allocator = shared_acclocator.deinit;

const logger = @import("./logger.zig");
const person = @import("./person.zig");
// const company = @import("./company.zig");
const malw = @import("./multi_array_list_wrapper.zig");
const debug = std.debug;

const app_name = "hello world";

pub fn main() !void {
    defer _ = deinit_allocator();

    const l = logger.new_logger();

    var may_json = std.os.getenv("JSON");
    if (may_json == null) {
        l.debugln("JSON is required");
        return;
    }

    const sample_file_name = may_json.?;
    
    l.debugln("hello world");
    l.printf("launching {s}\n", .{app_name});

    const cwd = fs.cwd();

    var path_work_buf: [fs.MAX_PATH_BYTES]u8 = undefined;
    const real_path = cwd.realpath(".", &path_work_buf) catch |err| {
        l.printf("realpath error: {}\n", .{err});
        return;
    };

    l.printf("real_path {s}\n", .{real_path});

    // run time allocation
    var sample_json_path = std.fmt.allocPrint(allocator(), "{s}/{s}", .{real_path, sample_file_name}) catch |err| {
        l.printf("allocPrint error: {}\n", .{err});
        return;
    };
    // must dealloc memory that is allocated on runtime
    defer allocator().free(sample_json_path);

    var fd = try cwd.openFile(sample_json_path, .{});
    defer fd.close();

    const stat = fd.stat() catch |err| {
        l.printf("fd.stat error: {}\n", .{err});
        return;
    };

    var buf_reader = std.io.bufferedReader(fd.reader());
    var st = buf_reader.reader();

    // if (stat.size > LIMIT) {
    //   while (try st.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    //     // be nice to memory...
    //   }
    // }
    
    var file_content = std.ArrayList(u8).init(allocator());
    defer file_content.deinit();
    
    file_content.resize(stat.size) catch |err| {
        l.printf("file_content.resize error: {}\n", .{err});
    };

    // st.readAll(file_content) catch |err| {
    const read_length = st.readAll(file_content.items) catch |err| {
        l.printf("st.readAll error: {}\n", .{err});
        return;
    };

    if (read_length != stat.size) {
        l.println("read length and file length is differed");
    }

    var parser = json.Parser.init(allocator(), false);
    defer parser.deinit();

    var parsed = parser.parse(file_content.items) catch |err| {
        l.printf("parser.parse error: {}\n", .{err});
        return;
    };
    defer parsed.deinit();

    l.printf("parsed.root.Object.count() {}\n", .{parsed.root.Object.count()});

    const a = parsed.root.Object.get("a");
    if (a != null) {
        l.printf("a.Integer {}\n", .{a.?.Integer});
    }

    var managed_stringify_buf = std.ArrayList(u8).init(allocator());
    defer managed_stringify_buf.deinit();

    parsed.root.jsonStringify(json.StringifyOptions{}, managed_stringify_buf.writer())
        catch |err| l.printf("jsonStringify error: {}\n", .{err});
    
    const parsed_json = managed_stringify_buf.items;
    l.println(parsed_json);

    var custom_stringify_buf = std.ArrayList(u8).init(allocator());
    defer custom_stringify_buf.deinit();

    write_json_value(custom_stringify_buf.writer(), &parsed.root, 0);

    const custom_parsed_json = custom_stringify_buf.items;
    l.println(custom_parsed_json);
}

fn aaaa(writer: io.Writer(*std.ArrayList(u8), error.OutOfMemory, .appendWrite)) !void {
    try std.fmt.format(writer, "aaaa", .{});
}

fn write_json_value(writer: anytype, v: *json.Value, depth: u8) void {
    switch (v.*) {
        .Bool => {
            std.fmt.format(writer, "{}", .{v.Bool})
                catch |err| debug.print("{}\n", .{err});
        },
        .Integer => {
            std.fmt.format(writer, "{}", .{v.Integer})
                catch |err| debug.print("{}\n", .{err});
        },
        .Float => {
            std.fmt.format(writer, "{}", .{v.Float})
                catch |err| debug.print("{}\n", .{err});
        },
        .NumberString => {
            std.fmt.format(writer, "\"{s}\"", .{v.NumberString})
                catch |err| debug.print("{}\n", .{err});
        },
        .String => {
            std.fmt.format(writer, "\"{s}\"", .{v.String})
                catch |err| debug.print("{}\n", .{err});
        },
        .Array => {
            std.fmt.format(writer, "[\n", .{})
                catch |err| debug.print("{}\n", .{err});

            var i: u8 = 0;
            array_it: for (v.Array.items) |item| {
                var deitem = item;
                append_indent(writer, depth + 1);
                write_json_value(writer, &deitem, depth + 1);

                if (i < v.Array.items.len - 1) {
                    std.fmt.format(writer, ",", .{}) catch |err| {
                        debug.print("{}\n", .{err});
                        break :array_it;
                    };
                }

                std.fmt.format(writer, "\n", .{}) catch |err| {
                    debug.print("{}\n", .{err});
                    break :array_it;
                };
                i = i + 1;
            }
            append_indent(writer, depth);
            std.fmt.format(writer, "]", .{})
                catch |err| debug.print("{}\n", .{err});
        },
        .Object => {
            std.fmt.format(writer, "{{\n", .{})
                catch |err| debug.print("{}\n", .{err});
            write_json_object(writer, &v.Object, depth + 1)
                catch |err| debug.print("{}\n", .{err});
            append_indent(writer, depth);
            std.fmt.format(writer, "}}", .{})
                catch |err| debug.print("{}\n", .{err});
        },
        .Null => {
            std.fmt.format(writer, "null", .{})
                catch |err| debug.print("{}\n", .{err});
        },
    }
}

fn append_indent(writer: anytype, depth: u8) void {
    var i: usize = 0;
    while (i < depth * 2) : (i += 1) {
        _ = writer.writeByte(' ') catch |err| debug.print("{}\n", .{err});
    }
}

fn write_json_object(writer: anytype, obj: anytype, depth: u8) !void {
    var i: u8 = 0;
    var it = obj.iterator();
    while (it.next()) |p| {
        const k = p.key_ptr;
        const v = p.value_ptr;

        append_indent(writer, depth);
        
        try std.fmt.format(writer, "{s}: ", .{k.*});
        write_json_value(writer, v, depth);

        if (i < obj.count() - 1) {
            try std.fmt.format(writer, ",", .{});
        }

        try std.fmt.format(writer, "\n", .{});

        i = i + 1;
    }
}

test "premitive allocator of struct" {
    var people = person.People{};
    defer people.deinit(allocator());

    try std.testing.expectEqual(@as(usize, 0), people.len);

    const names = [2][]const u8{"my name 1", "my name 2"};

    var index: usize = 0;
    for (names) |name| {
        try people.append(allocator(), person.Person{ .name = names[index], .age = 22 });
        try std.testing.expectEqual(@as(usize, index + 1), people.len);
        try std.testing.expectEqual(name, people.get(index).name);
        index += 1;
    }
}

test "multi array list wrapper" {
    var wrapper = malw.new_multi_array_list_wrapper(person.Person);

    try std.testing.expectError(
        malw.MultiArrayListWrapperError.AllocationNotBegan,
        wrapper.add(person.Person{ .name = "aaaa", .age = 22 })
    );
    try std.testing.expectError(
        malw.MultiArrayListWrapperError.IndexOutOfBounds,
        wrapper.at(0)
    );

    wrapper.set_allocator(allocator());
    defer wrapper.deinit();

    const names = [2][]const u8{"my name 1", "my name 2"};

    var index: usize = 0;
    for (names) |name| {
        try wrapper.add(person.Person{ .name = names[index], .age = 22 });
        try std.testing.expectEqual(@as(usize, index + 1), wrapper.size());
        const p = try wrapper.at(index);
        try std.testing.expectEqual(name, p.name);
        index += 1;
    }
}

test "logger" {
    const A = struct {
        const Self = @This();
        
        aaaa: []const u8,
        bbbb: []const u8,

        pub fn setB(self: *Self, s: []const u8) void {
            self.bbbb = s;
        }

        pub fn getB(self: Self) []const u8 {
            return self.bbbb;
        }
        pub fn getBRef(self: *Self) []const u8 {
            return self.bbbb;
        }
    };

    var a = A {
        .aaaa = "aaaa",
        .bbbb = ""
    };

    const l = logger.new_logger();
    // a; // main.A
    const arr = [3]u8{'a', 'r', 'r'};
    const s = "bbbb2";
    l.println(a.aaaa);
    l.println(a.bbbb);

    a.bbbb = "var";
    l.println(a.bbbb);

    a.setB(s);
    l.println(a.bbbb);

    a.setB("literal");
    l.println(a.bbbb);

    a.setB(&arr);
    l.println(a.bbbb);

    l.println(a.getB());
    l.println(a.getBRef());
}

test "sample struct" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
