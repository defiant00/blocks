const std = @import("std");
const Allocator = std.mem.Allocator;

const debug = @import("debug.zig");
const GcAllocator = @import("memory.zig").GcAllocater;
const Node = @import("ast.zig").Node;
const Parser = @import("parser.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const VM = struct {
    parent_allocator: Allocator,
    gc: GcAllocator,
    allocator: Allocator,

    root: Node,
    strings: std.StringHashMap(void),

    pub fn init(self: *VM, allocator: Allocator) !void {
        self.parent_allocator = allocator;
        self.gc = GcAllocator.init(self);
        self.allocator = self.gc.allocator();

        self.root = try Node.List(self.allocator, 0, 0);
        self.strings = std.StringHashMap(void).init(self.allocator);
    }

    pub fn deinit(self: *VM) void {
        self.root.deinit();

        var key_iter = self.strings.keyIterator();
        while (key_iter.next()) |key| self.allocator.free(key.*);
        self.strings.deinit();
    }

    pub fn collectGarbage(self: *VM) void {
        _ = self;
    }

    pub fn copyString(self: *VM, chars: []const u8) ![]const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| return i;

        const heap_chars = try self.allocator.alloc(u8, chars.len);
        std.mem.copy(u8, heap_chars, chars);
        try self.strings.put(heap_chars, {});
        return heap_chars;
    }

    test "copy string" {
        var vm: VM = undefined;
        try vm.init(std.testing.allocator);
        defer vm.deinit();

        const s1 = try vm.copyString("first");
        _ = try vm.copyString("second");
        _ = try vm.copyString("third");
        const s1_2 = try vm.copyString("first");

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn copyEscapeString(self: *VM, chars: []const u8) ![]const u8 {
        // calculate escaped length
        var escaped_len: usize = 0;
        var i: usize = 0;
        while (i < chars.len) : (i += 1) {
            if ((i + 1 < chars.len) and chars[i] == '"' and chars[i + 1] == '"') {
                i += 1;
            }
            escaped_len += 1;
        }

        // use the base copy string if no escaped characters
        if (escaped_len == chars.len) return copyString(self, chars);

        // allocate and copy the string
        const heap_chars = try self.allocator.alloc(u8, escaped_len);
        var heap_i: usize = 0;
        i = 0;
        while (i < chars.len) : (i += 1) {
            heap_chars[heap_i] = chars[i];
            heap_i += 1;
            if ((i + 1 < chars.len) and chars[i] == '"' and chars[i + 1] == '"') {
                i += 1;
            }
        }

        return self.takeString(heap_chars);
    }

    test "copy escape string" {
        var vm: VM = undefined;
        try vm.init(std.testing.allocator);
        defer vm.deinit();

        const s1 = try vm.copyEscapeString("first");
        const s2 = try vm.copyEscapeString("\"\"");
        _ = try vm.copyEscapeString("\"\"\"\"");
        _ = try vm.copyEscapeString("\"\"\"\"\"\"");
        const s1_2 = try vm.copyEscapeString("first");
        const s2_2 = try vm.copyEscapeString("\"\"");

        try std.testing.expect(vm.strings.count() == 4);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("\""));
        try std.testing.expect(vm.strings.contains("\"\""));
        try std.testing.expect(vm.strings.contains("\"\"\""));
        try std.testing.expect(!vm.strings.contains("\"\"\"\""));
        try std.testing.expectEqual(s1, s1_2);
        try std.testing.expectEqual(s2, s2_2);
    }

    pub fn takeString(self: *VM, chars: []const u8) ![]const u8 {
        const interned = self.strings.getKey(chars);
        if (interned) |i| {
            self.allocator.free(chars);
            return i;
        }
        try self.strings.put(chars, {});
        return chars;
    }

    test "take string" {
        var vm: VM = undefined;
        try vm.init(std.testing.allocator);
        defer vm.deinit();

        const heap_chars_1 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1, "first");
        const s1 = try vm.takeString(heap_chars_1);

        const heap_chars_2 = try vm.allocator.alloc(u8, 6);
        std.mem.copy(u8, heap_chars_2, "second");
        _ = try vm.takeString(heap_chars_2);

        const heap_chars_3 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_3, "third");
        _ = try vm.takeString(heap_chars_3);

        const heap_chars_4 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_4, "first");
        const s1_2 = try vm.takeString(heap_chars_4);

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn load(self: *VM, source: []const u8) !void {
        try Parser.parse(self, source);
        if (debug.print_ast) self.root.print();
    }

    pub fn run(self: *VM) !void {
        _ = self;
    }
};
