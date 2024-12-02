const std = @import("std");
const input = @embedFile("./d2p1.txt");

const MAX_REPORTS_SIZE = 1000;
const MAX_LEVEL_SIZE = 100;
const MAX_VIOLATIONS = 100;

const Slope = enum {
    Up,
    Down,
};

const Safety = enum {
    Safe,
    Unsafe,
};

const ViolationType = enum {
    SlopeViolation,
    DifferenceViolation,
    DuplicateViolation,
};

const Violation = struct {
    violation_type: ViolationType,
    index: u32,
};

const Report = struct {
    level: [MAX_LEVEL_SIZE]u32,
    level_size: usize,
    slope: Slope,
    safety: Safety,
    initialized: bool,
    violations: [MAX_VIOLATIONS]Violation,
    violation_count: usize,

    fn init() Report {
        return .{
            .level = undefined,
            .level_size = 0,
            .slope = undefined,
            .safety = Safety.Safe,
            .initialized = true,
            .violations = undefined,
            .violation_count = 0,
        };
    }

    fn add_level(self: *Report, level: u32) !void {
        if (self.level_size >= MAX_LEVEL_SIZE) return error.OutOfMemory;
        self.level[self.level_size] = level;
        self.level_size += 1;
        if (self.level_size == 2) {
            if (self.level[0] < self.level[1]) {
                self.slope = Slope.Up;
            } else {
                self.slope = Slope.Down;
            }
        }
    }

    fn detect_violations(self: *Report) !void {
        self.violation_count = 0;
        var i: u32 = 1;
        while (i < self.level_size) : (i += 1) {
            const last_level = self.level[i - 1];
            const current_level = self.level[i];

            // Check for duplicates
            if (last_level == current_level) {
                if (self.violation_count >= MAX_VIOLATIONS) return error.TooManyViolations;
                self.violations[self.violation_count] = .{
                    .violation_type = .DuplicateViolation,
                    .index = i - 1,
                };
                self.violation_count += 1;
                continue;
            }

            // Check for slope violations
            const is_increasing = current_level > last_level;
            if ((self.slope == .Up and !is_increasing) or
                (self.slope == .Down and is_increasing))
            {
                if (self.violation_count >= MAX_VIOLATIONS) return error.TooManyViolations;
                self.violations[self.violation_count] = .{
                    .violation_type = .SlopeViolation,
                    .index = i - 1,
                };
                self.violation_count += 1;
                continue;
            }

            // Check for difference violations
            const diff = try self.get_diff(i - 1, i);
            if (diff < 1 or diff > 3) {
                if (self.violation_count >= MAX_VIOLATIONS) return error.TooManyViolations;
                self.violations[self.violation_count] = .{
                    .violation_type = .DifferenceViolation,
                    .index = i - 1,
                };
                self.violation_count += 1;
            }
        }
    }

    fn process_report(self: *Report) !void {
        switch (self.violation_count) {
            0 => {
                self.safety = Safety.Safe;
                return;
            },
            1 => {
                const violation = self.violations[0];
                const indices_to_try = [_]u32{ violation.index, violation.index + 1 };
                for (indices_to_try) |index| {
                    var test_report = self.create_test_report();
                    test_report.remove_level(index);

                    if (test_report.level_size >= 2) {
                        if (test_report.level[0] < test_report.level[1]) {
                            test_report.slope = Slope.Up;
                        } else {
                            test_report.slope = Slope.Down;
                        }
                    }

                    try test_report.detect_violations();
                    if (test_report.violation_count == 0) {
                        self.safety = Safety.Safe;
                        return;
                    }
                }
            },
            else => {
                var i: usize = 0;
                while (i < self.level_size) : (i += 1) {
                    var test_report = self.create_test_report();
                    test_report.remove_level(@intCast(i));

                    if (test_report.level_size >= 2) {
                        if (test_report.level[0] < test_report.level[1]) {
                            test_report.slope = Slope.Up;
                        } else {
                            test_report.slope = Slope.Down;
                        }
                    }

                    try test_report.detect_violations();
                    if (test_report.violation_count == 0) {
                        self.safety = Safety.Safe;
                        return;
                    }
                }
            },
        }

        self.safety = Safety.Unsafe;
    }

    fn create_test_report(self: *const Report) Report {
        var test_report = Report.init();
        test_report.level_size = self.level_size;
        @memcpy(test_report.level[0..self.level_size], self.level[0..self.level_size]);
        test_report.slope = self.slope;
        return test_report;
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
        while (i < self.level_size - 1) : (i += 1) {
            self.level[i] = self.level[i + 1];
        }
        self.level_size -= 1;
    }

    fn get_diff(self: *Report, l1: u32, l2: u32) !i32 {
        const last_level: i32 = @intCast(self.level[l1]);
        const current_level: i32 = @intCast(self.level[l2]);
        if (self.slope == Slope.Up) {
            return current_level - last_level;
        } else {
            return last_level - current_level;
        }
    }
};

pub fn main() !void {
    const result = try solve(input);
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}

fn solve(input_str: []const u8) !u32 {
    var reports: [MAX_REPORTS_SIZE]Report = undefined;
    try parse(input_str, &reports);

    var safe_reports: u32 = 0;
    var i: usize = 0;
    while (i < MAX_REPORTS_SIZE) : (i += 1) {
        if (reports[i].initialized == false) {
            break;
        }

        try reports[i].detect_violations();

        try reports[i].process_report();

        if (reports[i].safety == Safety.Safe) {
            safe_reports += 1;
        }
    }
    return safe_reports;
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
}

test "single violation - removable" {
    const test_input = "1 3 2 4 5";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 1), result);
}

test "multiple violations - not fixable" {
    const test_input = "1 2 7 8 9";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 0), result);
}

test "duplicate number violation - fixable" {
    const test_input = "8 6 4 4 1";
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 1), result);
}

test "mixed cases" {
    const test_input =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;
    const result = try solve(test_input);
    try std.testing.expectEqual(@as(u32, 4), result);
}
