const std = @import("std");
const Allocator = std.mem.Allocator;

const GcAllocator = @import("memory.zig").GcAllocater;
const Parser = @import("parser.zig");

test {
    std.testing.refAllDecls(@This());
}

pub const VM = struct {
    parent_allocator: Allocator,
    gc: GcAllocator,
    allocator: Allocator,

    strings: std.StringHashMap(void),

    pub fn init(self: *VM, allocator: Allocator) void {
        self.parent_allocator = allocator;
        self.gc = GcAllocator.init(self);
        self.allocator = self.gc.allocator();

        self.strings = std.StringHashMap(void).init(self.allocator);
    }

    pub fn deinit(self: *VM) void {
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
        vm.init(std.testing.allocator);
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
        vm.init(std.testing.allocator);
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

        const heap_chars_1_2 = try vm.allocator.alloc(u8, 5);
        std.mem.copy(u8, heap_chars_1_2, "first");
        const s1_2 = try vm.takeString(heap_chars_1_2);

        try std.testing.expect(vm.strings.count() == 3);
        try std.testing.expect(vm.strings.contains("first"));
        try std.testing.expect(vm.strings.contains("second"));
        try std.testing.expect(vm.strings.contains("third"));
        try std.testing.expect(!vm.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn load(self: *VM, source: []const u8) !void {
        Parser.parse(self, source);

        // todo - return node, or have the VM hold the state?
    }

    pub fn interpret(self: *VM) !void {
        _ = self;
    }
};
