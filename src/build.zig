const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "visualization",
        .root_source_file = b.path("visualization.zig"), // Use relative path
        .target = target,
        .optimize = mode,
    });

    // Link the raylib library
    
    exe.linkSystemLibrary("raylib");
    exe.addIncludePath(b.path("include"));

    // Install the executable
    b.installArtifact(exe);

    // Add a run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}