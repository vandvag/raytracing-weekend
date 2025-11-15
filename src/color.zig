const std = @import("std");

const vec = @import("vec.zig");

const Interval = @import("interval.zig").Interval;

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    const intensity: Interval = .{ .min = 0.000, .max = 0.999 };

    pub fn fromVec3(v: vec.Vec3) Color {
        const r = linearToGamma(v[0]);
        const g = linearToGamma(v[1]);
        const b = linearToGamma(v[2]);

        const rbyte: u8 = @intFromFloat(256.0 * intensity.clamp(r));
        const gbyte: u8 = @intFromFloat(256.0 * intensity.clamp(g));
        const bbyte: u8 = @intFromFloat(256.0 * intensity.clamp(b));

        return .{
            .r = rbyte,
            .g = gbyte,
            .b = bbyte,
        };
    }

    fn linearToGamma(linear_component: f64) f64 {
        if (linear_component > 0.0) {
            return std.math.sqrt(linear_component);
        }

        return 0;
    }

    pub fn format(self: Color, writter: *std.Io.Writer) !void {
        return writter.print("{d} {d} {d}\n", .{ self.r, self.g, self.b });
    }
};
