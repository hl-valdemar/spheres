const rl = @import("raylib");

pub fn main() !void {
    const screen_width = 800;
    const screen_height = 800;
    const render_width: i32 = 320;
    const render_height: i32 = 320;
    const snap_resolution = [2]f32{
        @as(f32, @floatFromInt(render_width)) / 2,
        @as(f32, @floatFromInt(render_height)) / 2,
    };
    const light_direction = [3]f32{ -0.45, 0.8, -0.35 };
    const sphere_color = [4]f32{ 1.0, 0.3, 0.4, 1.0 };
    const ambient_strength: f32 = 0.25;
    const color_levels: i32 = 16;
    const dither_strength: f32 = 0.75;

    rl.InitWindow(screen_width, screen_height, "spheres");
    defer rl.CloseWindow();

    rl.DisableCursor();
    rl.SetTargetFPS(30);

    const scene_target = rl.LoadRenderTexture(render_width, render_height);
    defer rl.UnloadRenderTexture(scene_target);
    rl.SetTextureFilter(scene_target.texture, rl.TEXTURE_FILTER_POINT);

    const snap_shader = rl.LoadShaderFromMemory(
        @embedFile("shaders/ps1_snap.vs"),
        @embedFile("shaders/vertex_color.fs"),
    );
    defer rl.UnloadShader(snap_shader);

    const snap_resolution_loc = rl.GetShaderLocation(snap_shader, "snapResolution");
    const light_direction_loc = rl.GetShaderLocation(snap_shader, "lightDirection");
    const base_color_loc = rl.GetShaderLocation(snap_shader, "baseColor");
    const ambient_strength_loc = rl.GetShaderLocation(snap_shader, "ambientStrength");
    const color_levels_loc = rl.GetShaderLocation(snap_shader, "colorLevels");
    const dither_strength_loc = rl.GetShaderLocation(snap_shader, "ditherStrength");

    rl.SetShaderValue(
        snap_shader,
        snap_resolution_loc,
        &snap_resolution,
        rl.SHADER_UNIFORM_VEC2,
    );
    rl.SetShaderValue(
        snap_shader,
        light_direction_loc,
        &light_direction,
        rl.SHADER_UNIFORM_VEC3,
    );
    rl.SetShaderValue(
        snap_shader,
        base_color_loc,
        &sphere_color,
        rl.SHADER_UNIFORM_VEC4,
    );
    rl.SetShaderValue(
        snap_shader,
        ambient_strength_loc,
        &ambient_strength,
        rl.SHADER_UNIFORM_FLOAT,
    );
    rl.SetShaderValue(
        snap_shader,
        color_levels_loc,
        &color_levels,
        rl.SHADER_UNIFORM_INT,
    );
    rl.SetShaderValue(
        snap_shader,
        dither_strength_loc,
        &dither_strength,
        rl.SHADER_UNIFORM_FLOAT,
    );

    var sphere = rl.LoadModelFromMesh(rl.GenMeshSphere(1.0, 8, 8));
    defer rl.UnloadModel(sphere);
    sphere.materials[0].shader = snap_shader;

    var camera = rl.Camera3D{
        .position = .{ .x = 4.0, .y = 3.0, .z = 4.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 80.0,
        .projection = rl.CAMERA_PERSPECTIVE,
    };

    while (!rl.WindowShouldClose()) {
        rl.UpdateCamera(&camera, rl.CAMERA_FIRST_PERSON);

        {
            rl.BeginTextureMode(scene_target);
            defer rl.EndTextureMode();

            rl.ClearBackground(rl.BLACK);

            rl.BeginMode3D(camera);
            defer rl.EndMode3D();

            rl.DrawModel(sphere, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, 1.0, rl.WHITE);
            // rl.DrawGrid(20, 1.0);
        }

        {
            rl.BeginDrawing();
            defer rl.EndDrawing();

            rl.ClearBackground(rl.BLACK);
            rl.DrawTexturePro(
                scene_target.texture,
                .{
                    .x = 0.0,
                    .y = 0.0,
                    .width = @floatFromInt(render_width),
                    .height = -@as(f32, @floatFromInt(render_height)),
                },
                .{
                    .x = 0.0,
                    .y = 0.0,
                    .width = @floatFromInt(screen_width),
                    .height = @floatFromInt(screen_height),
                },
                .{ .x = 0.0, .y = 0.0 },
                0.0,
                rl.WHITE,
            );
        }
    }
}
