const std = @import("std");

const vec = @import("vec.zig");

const Interval = @import("interval.zig").Interval;

pub const Color = std.fmt.Alt(vec.Vec3, colorFormat);

fn linearToGamma(linear_component: f64) f64 {
    if (linear_component > 0.0) {
        return std.math.sqrt(linear_component);
    }

    return 0;
}

const intensity: Interval = .{ .min = 0.000, .max = 0.999 };

fn colorFormat(pixel_color: vec.Vec3, writer: *std.Io.Writer) !void {
    const r = linearToGamma(pixel_color[0]);
    const g = linearToGamma(pixel_color[1]);
    const b = linearToGamma(pixel_color[2]);

    const rbyte: u8 = @intFromFloat(256.0 * intensity.clamp(r));
    const gbyte: u8 = @intFromFloat(256.0 * intensity.clamp(g));
    const bbyte: u8 = @intFromFloat(256.0 * intensity.clamp(b));
    try writer.print("{d} {d} {d}\n", .{ rbyte, gbyte, bbyte });
}

pub fn fromVec3(v: vec.Vec3) Color {
    return Color{ .data = v };
}
