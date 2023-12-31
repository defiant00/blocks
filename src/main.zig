const std = @import("std");
const VM = @import("vm.zig").VM;

const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 5 };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);

    if (args.len == 3 and std.mem.eql(u8, args[1], "build")) {
        try buildRunFile(alloc, args[2], false);
    } else if (args.len == 3 and std.mem.eql(u8, args[1], "run")) {
        try buildRunFile(alloc, args[2], true);
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "help")) {
        printUsage();
    } else if (args.len == 2 and std.mem.eql(u8, args[1], "version")) {
        std.debug.print("{}\n", .{version});
    } else {
        printUsage();
        return error.InvalidCommand;
    }
}

fn buildRunFile(alloc: std.mem.Allocator, path: []const u8, run: bool) !void {
    var file = try std.fs.cwd().openFile(path, .{});
    const source = try file.readToEndAlloc(alloc, std.math.maxInt(usize));

    var vm: VM = undefined;
    try vm.init(alloc);
    defer vm.deinit();

    try vm.load(source);

    alloc.free(source);
    file.close();

    if (run) try vm.run();
}

fn printUsage() void {
    std.debug.print(
        \\Usage: blocks [command]
        \\
        \\Commands:
        \\  build [file]    Build specified file
        \\  run   [file]    Build and run specified file
        \\
        \\  help            Print this help and exit
        \\  version         Print version and exit
        \\
    , .{});
}
