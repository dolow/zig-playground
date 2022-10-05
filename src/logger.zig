const std = @import("std");
const debug = std.debug;
const io = std.io;
const fs = std.fs;
const fmt = std.fmt;

pub var logger: *Logger = undefined;

// static struct
const Logger = struct {
    const Self = @This();

    pub const writer: io.Writer(fs.File, fs.File.WriteError, fs.File.write) = io.getStdOut().writer();

    //buf: *io.BufferedWriter(4096, @TypeOf(writer)),

    pub fn printf(self: *const Self, comptime format: []const u8, args: anytype) void {
        fmt.format(writer, format, args) catch |err| {
            self.debugf("Logger.printf: fmt.format failed with error {}\n", .{err});
        };
    }
    pub fn println(self: *const Self, line: []const u8) void {
        writer.print("{s}\n", .{line}) catch |err| {
            self.debugf("Logger.println: writer.print failed with error {}\n", .{err});
        };
    }

    pub fn debugln(_: *const Self, line: []const u8) void {
        debug.print("{s}\n", .{line});
    }
    pub fn debugf(_: *const Self, comptime format: []const u8, args: anytype) void {
        debug.print(comptime fmt.comptimePrint("{s}\n", .{format}), args);
    }
};

pub fn new_logger() *const Logger {
    return &Logger{};
}
