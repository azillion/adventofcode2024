const std = @import("std");
const input = @embedFile("./d1p1.txt");

const MAX_SIZE = 2000;

// Wanted to only use static-allocation for this. Who needs dynamic memory allocation anyway? :^)

const List = struct {
    items: [MAX_SIZE]u32,
    len: usize,

    fn init() List {
        return .{
            .items = undefined,
            .len = 0,
        };
    }

    fn append(self: *List, value: u32) !void {
        if (self.len >= MAX_SIZE) return error.OutOfMemory;
        self.items[self.len] = value;
        self.len += 1;
    }
};

const HashMap = struct {
    keys: [MAX_SIZE]u32,
    values: [MAX_SIZE]u32,
    used: [MAX_SIZE]bool,
    size: usize,

    fn init() HashMap {
        return .{
            .keys = undefined,
            .values = undefined,
            .used = [_]bool{false} ** MAX_SIZE,
            .size = 0,
        };
    }

    fn put(self: *HashMap, key: u32, value: u32) !void {
        var index = @mod(key, MAX_SIZE);
        const start_index = index;

        while (true) {
            if (!self.used[index]) {
                self.keys[index] = key;
                self.values[index] = value;
                self.used[index] = true;
                self.size += 1;
                return;
            }

            if (self.keys[index] == key) {
                self.values[index] = value;
                return;
            }

            index = @mod(index + 1, MAX_SIZE);
            if (index == start_index) return error.OutOfMemory;
        }
    }

    fn get(self: HashMap, key: u32) ?u32 {
        var index = @mod(key, MAX_SIZE);
        const start_index = index;

        while (self.used[index]) {
            if (self.keys[index] == key) {
                return self.values[index];
            }
            index = @mod(index + 1, MAX_SIZE);
            if (index == start_index) return null;
        }
        return null;
    }
};

pub fn main() !void {
    const result = try solve(input);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}

fn solve(input_str: []const u8) !u32 {
    var hashmap1 = HashMap.init();
    var hashmap2 = HashMap.init();
    var list1 = List.init();

    try parse(input_str, &hashmap1, &hashmap2, &list1);

    var total: u32 = 0;
    var i: usize = 0;
    while (i < list1.len) : (i += 1) {
        const key = list1.items[i];
        if (hashmap2.get(key)) |other_value| {
            total += key * other_value;
        }
    }

    return total;
}

fn parse(input_str: []const u8, hashmap1: *HashMap, hashmap2: *HashMap, list1: *List) !void {
    var line_iter = std.mem.tokenize(u8, input_str, "\n");
    while (line_iter.next()) |line| {
        var number_iter = std.mem.tokenize(u8, line, " ");

        const num1_str = number_iter.next() orelse return error.InvalidInput;
        const num2_str = number_iter.next() orelse return error.InvalidInput;

        const num1 = try std.fmt.parseInt(u32, num1_str, 10);
        const num2 = try std.fmt.parseInt(u32, num2_str, 10);

        try list1.append(num1);

        const count1 = hashmap1.get(num1) orelse 0;
        const count2 = hashmap2.get(num2) orelse 0;
        try hashmap1.put(num1, count1 + 1);
        try hashmap2.put(num2, count2 + 1);
    }
}

test "example input" {
    const test_input =
        \\3   4
        \\4   3
        \\2   5
        \\1   3
        \\3   9
        \\3   3
    ;

    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 31), result);
}

test "empty input" {
    const test_input = "";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 0), result);
}

test "single line input" {
    const test_input = "5 5";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 5), result);
}

test "hash map counting" {
    var map = HashMap.init();
    try map.put(1, 1);
    try map.put(1, 2);
    try map.put(2, 1);

    try std.testing.expectEqual(@as(u32, 2), map.get(1).?);
    try std.testing.expectEqual(@as(u32, 1), map.get(2).?);
    try std.testing.expectEqual(@as(?u32, null), map.get(3));
}
