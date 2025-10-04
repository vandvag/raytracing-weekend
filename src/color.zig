const std = @import("std");

const vec = @import("vec.zig");

pub const Color = std.fmt.Alt(vec.Vec3, colorFormat);
fn colorFormat(pixel_color: vec.Vec3, writer: *std.Io.Writer) !void {
    const r: u8 = @intFromFloat(255.999 * pixel_color[0]);
    const g: u8 = @intFromFloat(255.999 * pixel_color[1]);
    const b: u8 = @intFromFloat(255.999 * pixel_color[2]);

    try writer.print("{d} {d} {d}\n", .{ r, g, b });
}

pub fn fromVec3(v: vec.Vec3) Color {
    return Color{ .data = v };
}
