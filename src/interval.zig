const std = @import("std");
const inf64 = std.math.inf(f64);

pub const Interval = struct {
    min: f64,
    max: f64,

    const Self = @This();

    pub const empty: Self = .{
        .min = inf64,
        .max = -inf64,
    };

    pub const universe: Self = .{
        .min = -inf64,
        .max = inf64,
    };

    pub fn size(self: *const Self) f64 {
        return self.max - self.min;
    }

    pub fn contains(self: *const Self, x: f64) bool {
        return self.min <= x and x <= self.max;
    }

    pub fn surrounds(self: *const Self, x: f64) bool {
        return self.min < x and x < self.max;
    }

    pub fn clamp(self: Self, x: f64) f64 {
        if (x >= self.max) {
            return self.max;
        }
        if (x <= self.min) {
            return self.min;
        }
        return x;
    }
};
