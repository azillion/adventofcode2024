const std = @import("std");
const input = @embedFile("./d1p1.txt");

const MAX_SIZE = 1000;

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

pub fn main() !void {
    const result = try solve(input);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}

fn solve(input_str: []const u8) !u32 {
    var list1 = List.init();
    var list2 = List.init();

    try parse(input_str, &list1, &list2);

    std.mem.sort(u32, list1.items[0..list1.len], {}, std.sort.asc(u32));
    std.mem.sort(u32, list2.items[0..list2.len], {}, std.sort.asc(u32));

    var total: u32 = 0;
    var i: usize = 0;
    while (i < list1.len) : (i += 1) {
        const val1 = list1.items[i];
        const val2 = list2.items[i];
        total += if (val1 > val2) val1 - val2 else val2 - val1;
    }

    return total;
}

fn parse(input_str: []const u8, list1: *List, list2: *List) !void {
    var line_iter = std.mem.tokenize(u8, input_str, "\n");
    while (line_iter.next()) |line| {
        var number_iter = std.mem.tokenize(u8, line, " ");

        const num1_str = number_iter.next() orelse return error.InvalidInput;
        const num2_str = number_iter.next() orelse return error.InvalidInput;

        const num1 = try std.fmt.parseInt(u32, num1_str, 10);
        const num2 = try std.fmt.parseInt(u32, num2_str, 10);

        try list1.append(num1);
        try list2.append(num2);
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

test "single pair" {
    const test_input = "5   5";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 5), result);
}
