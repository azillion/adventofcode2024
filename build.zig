const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const source_dir = "src";
    const exe = b.addExecutable(.{
        .name = "adventofcode2024",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const test_step = b.step("test", "Run all tests");

    // First, iterate through the day directories
    var src_dir = std.fs.cwd().openDir(source_dir, .{ .iterate = true }) catch |err| {
        std.log.err("Failed to open directory 'src': {}", .{err});
        return;
    };
    defer src_dir.close();

    var dir_iterator = src_dir.iterate();
    while (true) {
        const dir_entry = dir_iterator.next() catch |err| {
            std.log.err("Failed to iterate over directory 'src': {}", .{err});
            break;
        };
        if (dir_entry == null) break;
        const dir_file_entry = dir_entry.?;

        // Only process directories that start with 'd'
        if (dir_file_entry.kind != .directory or !std.mem.startsWith(u8, dir_file_entry.name, "d")) continue;

        // Open the day directory
        var day_dir = src_dir.openDir(dir_file_entry.name, .{ .iterate = true }) catch |err| {
            std.log.err("Failed to open directory 'src/{s}': {}", .{ dir_file_entry.name, err });
            continue;
        };
        defer day_dir.close();

        // Iterate through files in the day directory
        var file_iterator = day_dir.iterate();
        while (true) {
            const file_entry = file_iterator.next() catch |err| {
                std.log.err("Failed to iterate over directory 'src/{s}': {}", .{ dir_file_entry.name, err });
                break;
            };
            if (file_entry == null) break;
            const day_file_entry = file_entry.?;

            // Only process .zig files
            if (day_file_entry.kind != .file or !std.mem.endsWith(u8, day_file_entry.name, ".zig")) continue;

            const day_name = std.mem.trimRight(u8, day_file_entry.name, ".zig");
            const file_path = b.pathJoin(&.{ source_dir, dir_file_entry.name, day_file_entry.name });

            const day_exe = b.addExecutable(.{
                .name = day_name,
                .root_source_file = b.path(file_path),
                .target = target,
                .optimize = optimize,
            });

            // Create the run step
            var run_step_name_buffer: [32]u8 = undefined;
            const run_step_name = std.fmt.bufPrint(&run_step_name_buffer, "run-{s}", .{day_name}) catch continue;
            var run_desc_buffer: [32]u8 = undefined;
            const run_desc = std.fmt.bufPrint(&run_desc_buffer, "Run {s}", .{day_name}) catch continue;
            const run_day_step = b.step(run_step_name, run_desc);
            const run_day_cmd = b.addRunArtifact(day_exe);
            run_day_step.dependOn(&run_day_cmd.step);

            // Create the test step
            var test_step_name_buffer: [32]u8 = undefined;
            const test_step_name = std.fmt.bufPrint(&test_step_name_buffer, "test-{s}", .{day_name}) catch continue;
            var test_desc_buffer: [32]u8 = undefined;
            const test_desc = std.fmt.bufPrint(&test_desc_buffer, "Test {s}", .{day_name}) catch continue;

            const day_test = b.addTest(.{
                .root_source_file = b.path(file_path),
                .target = target,
                .optimize = optimize,
            });
            const run_day_test_cmd = b.addRunArtifact(day_test);
            const test_day_step = b.step(test_step_name, test_desc);
            test_day_step.dependOn(&run_day_test_cmd.step);
            test_step.dependOn(&run_day_test_cmd.step);
        }
    }
}
