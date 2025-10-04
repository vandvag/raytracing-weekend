const std = @import("std");
const Progress = std.Progress;

const color = @import("color.zig");
const Color = color.Color;
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

const IMG_WIDTH = 256;
const IMG_HEIGHT = 256;

pub fn main() !void {
    var wbuffer: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuffer);
    const out = &file_writer.interface;

    var progress_buffer: [1024]u8 = undefined;
    const progress = Progress.start(.{
        .draw_buffer = &progress_buffer,
        .estimated_total_items = IMG_HEIGHT * IMG_WIDTH,
        .root_name = "Rendering",
    });
    defer progress.end();

    try out.print("P3\n{d} {d}\n255\n", .{ IMG_WIDTH, IMG_HEIGHT });

    for (0..IMG_HEIGHT) |h| {
        progress.completeOne();
        for (0..IMG_WIDTH) |w| {
            const h_float: f32 = @floatFromInt(h);
            const w_float: f32 = @floatFromInt(w);
            const pixel_color = color.fromVec3(.{
                w_float / (IMG_WIDTH - 1),
                h_float / (IMG_HEIGHT - 1),
                0.0,
            });

            try out.print("{f}", .{pixel_color});
        }
    }

    try out.flush();
}
