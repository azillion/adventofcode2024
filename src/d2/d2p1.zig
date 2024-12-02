const std = @import("std");
const input = @embedFile("./d2p1.txt");

const MAX_REPORTS_SIZE = 1000;
const MAX_LEVEL_SIZE = 100;

// Wanted to only use static-allocation for this. Who needs dynamic memory allocation anyway? :^)

const Slope = enum {
    Up,
    Down,
};

const Safety = enum {
    Safe,
    Unsafe,
};

const Report = struct {
    level: [MAX_LEVEL_SIZE]u32,
    level_size: usize,
    slope: Slope,
    safety: Safety,

    fn init() Report {
        return .{
            .level = undefined,
            .level_size = 0,
            .slope = undefined,
            .safety = undefined,
        };
    }

    fn add_level(self: *Report, level: u32) !void {
        if (self.level_size >= MAX_LEVEL_SIZE) return error.OutOfMemory;
        self.level[self.level_size] = level;
        self.level_size += 1;

        switch (self.level_size) {
            0 => {},
            1 => {},
            2 => {
                if (self.level[0] < self.level[1]) {
                    self.slope = Slope.Up;
                } else {
                    self.slope = Slope.Down;
                }
                try self.check_safety();
            },
            else => {
                try self.check_slope();
                try self.check_safety();
            },
        }
    }

    // check if the level change is gradual, if not, it's unsafe
    fn check_safety(self: *Report) !void {
        // if the last level is the same as the last, if so, it's unsafe
        // we can do this check here because we know that the level_size is at least 2
        if (self.level[self.level_size - 2] == self.level[self.level_size - 1]) {
            self.safety = Safety.Unsafe;
        }
        // if the level is still safe, we can check if this level is at least 1 step away from the previous level
        var diff: i32 = 0;
        const last_level: i32 = try u32ToI32(self.level[self.level_size - 2]);
        const current_level: i32 = try u32ToI32(self.level[self.level_size - 1]);
        if (self.slope == Slope.Up) {
            diff = current_level - last_level;
        } else {
            diff = last_level - current_level;
        }
        if (diff < 1 or diff > 3) {
            self.safety = Safety.Unsafe;
        }
    }

    // check if the slope has changed, if so, it's unsafe
    fn check_slope(self: *Report) !void {
        if (self.level_size < 2) return;
        if (self.level[self.level_size - 2] < self.level[self.level_size - 1] and self.slope == Slope.Down) {
            self.safety = Safety.Unsafe;
        } else if (self.level[self.level_size - 2] > self.level[self.level_size - 1] and self.slope == Slope.Up) {
            self.safety = Safety.Unsafe;
        }
    }
};

pub fn u32ToI32(value: u32) !i32 {
    if (value <= std.math.maxInt(u32)) {
        return @intCast(value);
    } else {
        return error.OutOfRange;
    }
}

pub fn main() !void {
    const result = try solve(input);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}

fn solve(input_str: []const u8) !u32 {
    return try parse(input_str);
}

fn parse(input_str: []const u8) !u32 {
    var reports: [MAX_REPORTS_SIZE]Report = undefined;
    var line_iter = std.mem.tokenize(u8, input_str, "\n");
    var safe: u32 = 0;
    var i: usize = 0;
    while (line_iter.next()) |line| : (i += 1) {
        var number_iter = std.mem.tokenize(u8, line, " ");
        reports[i] = Report.init();

        while (number_iter.next()) |number| {
            if (reports[i].safety != undefined and reports[i].safety == Safety.Unsafe) {
                break;
            }
            const num = try std.fmt.parseInt(u32, number, 10);
            try reports[i].add_level(num);
        }
        if (reports[i].safety == undefined) {
            reports[i].safety = Safety.Safe;
            safe += 1;
        }
    }
    return safe;
}

test "example input" {
    const test_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 2), result);
}
