const std = @import("std");
const fs = std.fs;
const json = std.json;

const logger = @import("./logger.zig");

const shared_acclocator = @import("./shared_allocator.zig");
const allocator = shared_acclocator.allocator;

const debug = std.debug;

pub fn json_file_to_yaml(file_path: []const u8, out: *std.ArrayList(u8)) ![]u8 {
    const l = logger.new_logger();

    const cwd = fs.cwd();
    var fd = try cwd.openFile(file_path, .{});
    defer fd.close();

    // json.Parser just refer and does not copy key and string value from loaded file content.
    // therefore the lifetime of both parsed value and working json content are the same.
    // in this case, function receives working buffer to keep responsibility of memory to its caller.
    var buf = std.ArrayList(u8).init(allocator());
    defer buf.deinit();

    var tree = unmarshal_file(fd, &buf) catch |err| {
        l.printf("unmarshal_file error: {}\n", .{err});
        return err;
    };
    defer tree.deinit();

    var managed_stringify_buf = std.ArrayList(u8).init(allocator());
    defer managed_stringify_buf.deinit();

    tree.root.jsonStringify(json.StringifyOptions{}, managed_stringify_buf.writer())
        catch |err| l.printf("jsonStringify error: {}\n", .{err});

    write_yaml_value(out.writer(), &tree.root, 0);

    return out.items;
}

pub fn unmarshal_file(fd: fs.File, file_content: *std.ArrayList(u8)) !json.ValueTree {    
    const l = logger.new_logger();

    var buf_reader = std.io.bufferedReader(fd.reader());

    var st = buf_reader.reader();
    const stat = fd.stat() catch |err| {
        l.printf("fd.stat error: {}\n", .{err});
        return err;
    };

    // if (stat.size > LIMIT) {
    //   while (try st.readUntilDelimiterOrEof(&buf, '\n')) |line| {
    //     // be nice to memory...
    //   }
    // }
    
    file_content.resize(stat.size) catch |err| {
        l.printf("file_content.resize error: {}\n", .{err});
        return err;
    };

    const read_length = st.readAll(file_content.items) catch |err| {
        l.printf("st.readAll error: {}\n", .{err});
        return err;
    };

    if (read_length != stat.size) {
        l.println("read length and file length is differed");
    }

    var parser = json.Parser.init(allocator(), false);
    defer parser.deinit();

    var parsed = parser.parse(file_content.items) catch |err| {
        l.printf("parser.parse error: {}\n", .{err});
        return err;
    };

    return parsed;
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

fn write_yaml_value(writer: anytype, v: *json.Value, depth: u8) void {
    switch (v.*) {
        .Bool => {
            std.fmt.format(writer, "{}\n", .{v.Bool})
                catch |err| debug.print("{}\n", .{err});
        },
        .Integer => {
            std.fmt.format(writer, "{}\n", .{v.Integer})
                catch |err| debug.print("{}\n", .{err});
        },
        .Float => {
            std.fmt.format(writer, "{}\n", .{v.Float})
                catch |err| debug.print("{}\n", .{err});
        },
        .NumberString => {
            std.fmt.format(writer, "\"{s}\"\n", .{v.NumberString})
                catch |err| debug.print("{}\n", .{err});
        },
        .String => {
            std.fmt.format(writer, "\"{s}\"\n", .{v.String})
                catch |err| debug.print("{}\n", .{err});
        },
        .Array => {
            std.fmt.format(writer, "\n", .{})
                catch |err| debug.print("{}\n", .{err});

            for (v.Array.items) |item| {
                var mut_item = item;
                append_indent(writer, depth + 1);
                std.fmt.format(writer, "- ", .{})
                  catch |err| debug.print("{}\n", .{err});
                write_yaml_value(writer, &mut_item, depth + 1);
            }
        },
        .Object => {
            std.fmt.format(writer, "\n", .{})
                catch |err| debug.print("{}\n", .{err});
                
            write_yaml_object(writer, &v.Object, depth + 1)
                catch |err| debug.print("{}\n", .{err});
        },
        .Null => {
            std.fmt.format(writer, "null\n", .{})
                catch |err| debug.print("{}\n", .{err});
        },
    }
}

fn write_yaml_object(writer: anytype, obj: anytype, depth: u8) !void {
    var it = obj.iterator();
    while (it.next()) |p| {
        const k = p.key_ptr;
        const v = p.value_ptr;

        append_indent(writer, depth);
        
        try std.fmt.format(writer, "{s}: ", .{k.*});
        write_yaml_value(writer, v, depth);
    }
}

fn append_indent(writer: anytype, depth: u8) void {
    if (depth == 0) {
        return;
    }
    var i: usize = 0;
    while (i < (depth - 1) * 2) : (i += 1) {
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
