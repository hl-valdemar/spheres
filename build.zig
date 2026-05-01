const std = @import("std");

const BuildContext = struct {
    mod: *std.Build.Module,
    exe: *std.Build.Step.Compile,
    translate_rl: *std.Build.Step.TranslateC,
};

const WindowsRaylibPaths = struct {
    include: ?[]const u8,
    lib: ?[]const u8,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const os_tag = target.result.os.tag;
    const windows_paths = if (os_tag == .windows) resolveWindowsRaylibPaths(b) else WindowsRaylibPaths{
        .include = null,
        .lib = null,
    };
    const ctx = buildCommon(b, target, optimize, windows_paths.include);

    switch (os_tag) {
        .macos => configureMacOS(&ctx),
        .windows => configureWindows(&ctx, windows_paths),
        else => configureOtherPlatforms(&ctx),
    }

    finishBuild(b, ctx);
}

fn pathExists(io: std.Io, path: []const u8) bool {
    var dir = std.Io.Dir.openDirAbsolute(io, path, .{}) catch return false;
    dir.close(io);
    return true;
}

fn firstExistingPath(io: std.Io, paths: []const []const u8) ?[]const u8 {
    for (paths) |path| {
        if (pathExists(io, path)) return path;
    }
    return null;
}

fn resolveWindowsRaylibPaths(b: *std.Build) WindowsRaylibPaths {
    const io = b.graph.io;
    const raylib_include = b.option([]const u8, "raylib-include", "Path to the directory containing raylib.h");
    const raylib_lib = b.option([]const u8, "raylib-lib", "Path to the directory containing the raylib library");

    return .{
        .include = if (raylib_include) |include_path|
            include_path
        else
            firstExistingPath(io, &.{
                "C:\\raylib\\w64devkit\\include",
                "C:\\raylib\\raylib\\src",
            }),
        .lib = if (raylib_lib) |lib_path|
            lib_path
        else
            firstExistingPath(io, &.{
                "C:\\raylib\\w64devkit\\lib",
                "C:\\raylib\\raylib\\src",
            }),
    };
}

fn buildCommon(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, raylib_include: ?[]const u8) BuildContext {
    const translate_rl = b.addTranslateC(.{
        .root_source_file = b.path("src/lib/raylib.h"),
        .target = target,
        .optimize = optimize,
    });

    if (raylib_include) |include_path| {
        translate_rl.addIncludePath(.{ .cwd_relative = include_path });
    }

    translate_rl.link_libc = true;

    const raylib_mod = translate_rl.createModule();

    const mod = b.addModule("spheres", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .imports = &.{
            .{ .name = "raylib", .module = raylib_mod },
        },
    });

    const exe = b.addExecutable(.{
        .name = "spheres",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "spheres", .module = mod },
                .{ .name = "raylib", .module = raylib_mod },
            },
        }),
    });

    exe.root_module.link_libc = true;

    return .{
        .mod = mod,
        .exe = exe,
        .translate_rl = translate_rl,
    };
}

fn linkSystemLib(ctx: *const BuildContext, name: []const u8) void {
    ctx.translate_rl.linkSystemLibrary(name, .{});
    ctx.exe.root_module.linkSystemLibrary(name, .{});
}

fn configureMacOS(ctx: *const BuildContext) void {
    linkSystemLib(ctx, "raylib");
    ctx.exe.root_module.linkFramework("OpenGL", .{});
    ctx.exe.root_module.linkFramework("Cocoa", .{});
    ctx.exe.root_module.linkFramework("IOKit", .{});
    ctx.exe.root_module.linkFramework("CoreVideo", .{});
}

fn configureWindows(ctx: *const BuildContext, paths: WindowsRaylibPaths) void {
    if (paths.lib) |lib_path| {
        ctx.exe.root_module.addLibraryPath(.{ .cwd_relative = lib_path });
    }

    linkSystemLib(ctx, "raylib");
    linkSystemLib(ctx, "opengl32");
    linkSystemLib(ctx, "gdi32");
    linkSystemLib(ctx, "winmm");
    linkSystemLib(ctx, "user32");
    linkSystemLib(ctx, "shell32");

    if (paths.include == null or paths.lib == null) {
        @panic(
            "raylib was not found. Install the Windows raylib bundle to C:\\raylib, " ++
                "or pass -Draylib-include=\"...\" -Draylib-lib=\"...\".",
        );
    }
}

fn configureOtherPlatforms(ctx: *const BuildContext) void {
    linkSystemLib(ctx, "raylib");
}

fn finishBuild(b: *std.Build, ctx: BuildContext) void {
    b.installArtifact(ctx.exe);

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(ctx.exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{ .root_module = ctx.mod });
    const exe_tests = b.addTest(.{ .root_module = ctx.exe.root_module });

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&b.addRunArtifact(mod_tests).step);
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);
}
