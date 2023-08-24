const std = @import("std");

test {
    std.testing.refAllDecls(@This());
}

pub const StringPool = struct {
    strings: std.StringHashMap(void),

    pub fn init(alloc: std.mem.Allocator) StringPool {
        return .{
            .strings = std.StringHashMap(void).init(alloc),
        };
    }

    pub fn deinit(self: *StringPool) void {
        var key_iter = self.strings.keyIterator();
        while (key_iter.next()) |key| self.strings.allocator.free(key.*);
        self.strings.deinit();
    }

    pub fn copy(self: *StringPool, string: []const u8) ![]const u8 {
        const interned = self.strings.getKey(string);
        if (interned) |i| return i;

        const new_string = try self.strings.allocator.alloc(u8, string.len);
        @memcpy(new_string, string);
        try self.strings.put(new_string, {});
        return new_string;
    }

    test "copy" {
        var sp = StringPool.init(std.testing.allocator);
        defer sp.deinit();

        const s1 = try sp.copy("first");
        _ = try sp.copy("second");
        _ = try sp.copy("third");
        const s1_2 = try sp.copy("first");

        try std.testing.expect(sp.strings.count() == 3);
        try std.testing.expect(sp.strings.contains("first"));
        try std.testing.expect(sp.strings.contains("second"));
        try std.testing.expect(sp.strings.contains("third"));
        try std.testing.expect(!sp.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }

    pub fn copyEscape(self: *StringPool, string: []const u8) ![]const u8 {
        // calculate escaped length
        var escaped_len: usize = 0;
        var i: usize = 0;
        while (i < string.len) : (i += 1) {
            if ((i + 1 < string.len) and string[i] == '"' and string[i + 1] == '"') {
                i += 1;
            }
            escaped_len += 1;
        }

        // use copy if there are no escaped characters
        if (escaped_len == string.len) return self.copy(string);

        // allocate and copy the string
        const new_string = try self.strings.allocator.alloc(u8, escaped_len);
        var new_i: usize = 0;
        i = 0;
        while (i < string.len) : (i += 1) {
            new_string[new_i] = string[i];
            new_i += 1;
            if ((i + 1 < string.len) and string[i] == '"' and string[i + 1] == '"') {
                i += 1;
            }
        }

        return self.take(new_string);
    }

    test "copy escape" {
        var sp = StringPool.init(std.testing.allocator);
        defer sp.deinit();

        const s1 = try sp.copyEscape("first");
        const s2 = try sp.copyEscape("\"\"");
        _ = try sp.copyEscape("\"\"\"\"");
        _ = try sp.copyEscape("\"\"\"\"\"\"");
        const s1_2 = try sp.copyEscape("first");
        const s2_2 = try sp.copyEscape("\"\"");

        try std.testing.expect(sp.strings.count() == 4);
        try std.testing.expect(sp.strings.contains("first"));
        try std.testing.expect(sp.strings.contains("\""));
        try std.testing.expect(sp.strings.contains("\"\""));
        try std.testing.expect(sp.strings.contains("\"\"\""));
        try std.testing.expect(!sp.strings.contains("\"\"\"\""));
        try std.testing.expectEqual(s1, s1_2);
        try std.testing.expectEqual(s2, s2_2);
    }

    pub fn take(self: *StringPool, string: []const u8) ![]const u8 {
        const interned = self.strings.getKey(string);
        if (interned) |i| {
            self.strings.allocator.free(string);
            return i;
        }
        try self.strings.put(string, {});
        return string;
    }

    test "take" {
        var sp = StringPool.init(std.testing.allocator);
        defer sp.deinit();

        const new_str_1 = try sp.strings.allocator.alloc(u8, 5);
        @memcpy(new_str_1, "first");
        const s1 = try sp.take(new_str_1);

        const new_str_2 = try sp.strings.allocator.alloc(u8, 6);
        @memcpy(new_str_2, "second");
        _ = try sp.take(new_str_2);

        const new_str_3 = try sp.strings.allocator.alloc(u8, 5);
        @memcpy(new_str_3, "third");
        _ = try sp.take(new_str_3);

        const new_str_4 = try sp.strings.allocator.alloc(u8, 5);
        @memcpy(new_str_4, "first");
        const s1_2 = try sp.take(new_str_4);

        try std.testing.expect(sp.strings.count() == 3);
        try std.testing.expect(sp.strings.contains("first"));
        try std.testing.expect(sp.strings.contains("second"));
        try std.testing.expect(sp.strings.contains("third"));
        try std.testing.expect(!sp.strings.contains("fourth"));
        try std.testing.expectEqual(s1, s1_2);
    }
};
