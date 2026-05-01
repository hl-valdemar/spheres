const rl = @import("raylib");

pub fn main() !void {
    const screen_width = 1280;
    const screen_height = 720;

    rl.InitWindow(screen_width, screen_height, "spheres");
    defer rl.CloseWindow();

    rl.DisableCursor();
    rl.SetTargetFPS(60);

    var camera = rl.Camera3D{
        .position = .{ .x = 4.0, .y = 3.0, .z = 4.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 60.0,
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    while (!rl.WindowShouldClose()) {
        rl.UpdateCamera(&camera, rl.CAMERA_FIRST_PERSON);

        rl.BeginDrawing();
        defer rl.EndDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode3D(camera);
        defer rl.EndMode3D();

        rl.DrawSphereEx(.{ .x = 0.0, .y = 0.0, .z = 0.0 }, 1.0, 10, 10, .{
            .r = 255,
            .g = @intFromFloat(0.3 * 255),
            .b = @intFromFloat(0.4 * 255),
            .a = 255,
        });
        rl.DrawGrid(20, 1.0);
    }
}
