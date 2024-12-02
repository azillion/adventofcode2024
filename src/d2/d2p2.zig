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
    initialized: bool,

    fn init() Report {
        return .{
            .level = undefined,
            .level_size = 0,
            .slope = undefined, // we don't need to store this but it's easier
            .safety = Safety.Safe,
            .initialized = true,
        };
    }

    fn add_level(self: *Report, level: u32) !void {
        if (self.level_size >= MAX_LEVEL_SIZE) return error.OutOfMemory;
        self.level[self.level_size] = level;
        self.level_size += 1;
        switch (self.level_size) {
            2 => {
                if (self.level[0] < self.level[1]) {
                    self.slope = Slope.Up;
                } else {
                    self.slope = Slope.Down;
                }
            },
            else => {},
        }
    }

    fn check_report_safety(self: *Report) !bool {
        var j: u32 = 1;
        while (j < self.level_size) : (j += 1) {
            const i = j - 1;
            if (try self.check_safety(i, j) != null) {
                return false;
            }
        }
        return true;
    }

    fn create_test_report(self: *const Report) Report {
        var test_report = Report.init();
        test_report.level_size = self.level_size;
        @memcpy(test_report.level[0..self.level_size], self.level[0..self.level_size]);
        test_report.slope = self.slope;
        return test_report;
    }

    fn process_report(self: *Report) !void {
        // First check if it's safe without any modifications
        if (try self.check_report_safety()) {
            self.safety = Safety.Safe;
            return;
        }

        // If not safe, try removing each level one at a time
        var i: usize = 0;
        while (i < self.level_size) : (i += 1) {
            var test_report = self.create_test_report();
            test_report.remove_level(@intCast(i));

            // Set the slope for the test report based on first two numbers
            if (test_report.level_size >= 2) {
                if (test_report.level[0] < test_report.level[1]) {
                    test_report.slope = Slope.Up;
                } else {
                    test_report.slope = Slope.Down;
                }
            }

            if (try test_report.check_report_safety()) {
                self.safety = Safety.Safe;
                return;
            }
        }

        self.safety = Safety.Unsafe;
    }

    fn remove_level(self: *Report, index: u32) void {
        if (index >= self.level_size) {
            return;
        }

        if (index == self.level_size - 1) {
            self.level_size -= 1;
            return;
        }
        var i = index;
        while (i < self.level_size) {
            self.level[i] = self.level[i + 1];
            i += 1;
        }
        self.level_size -= 1;
    }

    // check if the level change is gradual, if not, it's unsafe
    fn check_safety(self: *Report, l1: u32, l2: u32) !?u32 {
        const last_level = self.level[l1];
        const current_level = self.level[l2];
        if (try self.check_slope(l1, l2) != null) {
            return l1;
        }
        // if the last level is the same as the last, if so, it's unsafe
        // we can do this check here because we know that the level_size is at least 2
        if (last_level == current_level) {
            return l1;
        }
        // if the level is still safe, we can check if this level is at least 1 step away from the previous level
        const diff = try self.get_diff(l1, l2);
        if (diff < 1 or diff > 3) {
            return l1;
        }
        return null;
    }

    fn get_diff(self: *Report, l1: u32, l2: u32) !i32 {
        const last_level_i32: i32 = try u32ToI32(self.level[l1]);
        const current_level_i32: i32 = try u32ToI32(self.level[l2]);
        if (self.slope == Slope.Up) {
            return current_level_i32 - last_level_i32;
        } else {
            return last_level_i32 - current_level_i32;
        }
    }

    fn check_slope(self: *Report, l1: u32, l2: u32) !?u32 {
        const last_level = self.level[l1];
        const current_level = self.level[l2];
        if (self.slope == Slope.Up and last_level >= current_level) {
            return l1;
        } else if (self.slope == Slope.Down and last_level <= current_level) {
            return l1;
        }
        return null;
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
    var reports: [MAX_REPORTS_SIZE]Report = undefined;
    try parse(input_str, &reports);
    var i: usize = 0;
    var safe_reports: u32 = 0;
    while (i < MAX_REPORTS_SIZE) : (i += 1) {
        if (reports[i].initialized == false) {
            break;
        }
        try reports[i].process_report();
        if (reports[i].safety == Safety.Safe) {
            safe_reports += 1;
        }
    }
    // try print_reports(&reports);
    return safe_reports;
}

fn print_reports(reports: *[MAX_REPORTS_SIZE]Report) !void {
    var i: usize = 0;
    while (i < MAX_REPORTS_SIZE) : (i += 1) {
        if (reports[i].initialized == false) {
            break;
        }
        std.debug.print("Report {d}: ", .{i});
        var j: usize = 0;
        while (j < reports[i].level_size) : (j += 1) {
            std.debug.print("{d} ", .{reports[i].level[j]});
        }
        std.debug.print(" | Safe: {}\n", .{reports[i].safety == Safety.Safe});
    }
}

fn parse(input_str: []const u8, reports: *[MAX_REPORTS_SIZE]Report) !void {
    var line_iter = std.mem.tokenize(u8, input_str, "\n");
    var i: usize = 0;
    while (line_iter.next()) |line| : (i += 1) {
        var number_iter = std.mem.tokenize(u8, line, " ");
        reports[i] = Report.init();

        while (number_iter.next()) |number| {
            const num = try std.fmt.parseInt(u32, number, 10);
            try reports[i].add_level(num);
        }
    }
    return;
}

test "report inherently safe" {
    const test_input = "7 6 4 2 1";

    const result = try solve(test_input);

    // Single safe report
    try std.testing.expectEqual(@as(u32, 1), result);
}

test "report inherently unsafe" {
    const test_input = "1 2 7 8 9";

    const result = try solve(test_input);

    // Unsafe regardless of the Problem Dampener
    try std.testing.expectEqual(@as(u32, 0), result);
}

test "report becomes safe with Problem Dampener" {
    const test_input =
        \\1 3 2 4 5
        \\8 6 4 4 1
    ;

    const result = try solve(test_input);

    // Two reports become safe by removing a single bad level
    try std.testing.expectEqual(@as(u32, 2), result);
}

test "mixed safe and unsafe reports" {
    const test_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    const result = try solve(test_input);

    // Verify that only 4 reports are safe, considering the Problem Dampener
    try std.testing.expectEqual(@as(u32, 4), result);
}
