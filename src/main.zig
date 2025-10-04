const std = @import("std");

const IMG_WIDTH = 256;
const IMG_HEIGHT = 256;

pub fn main() !void {
    var wbuffer: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuffer);
    const out = &file_writer.interface;

    try out.print("P3\n{d} {d}\n255\n", .{ IMG_WIDTH, IMG_HEIGHT });

    for (0..IMG_HEIGHT) |h| {
        for (0..IMG_WIDTH) |w| {
            const h_float: f32 = @floatFromInt(h);
            const w_float: f32 = @floatFromInt(w);
            const r: u8 = @intFromFloat(255.999 * (w_float / (IMG_WIDTH - 1)));
            const g: u8 = @intFromFloat(255.999 * (h_float / (IMG_HEIGHT - 1)));
            const b: u8 = 0;

            try out.print("{d} {d} {d}\n", .{ r, g, b });
        }
    }

    try out.flush();
}
