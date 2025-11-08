const std = @import("std");
const vec = @import("vec.zig");
const hlist = @import("hittableList.zig");
const HittableList = hlist.HittableList;
const Interval = @import("interval.zig").Interval;

pub const Ray = struct {
    _origin: vec.Vec3,
    _direction: vec.Vec3,

    pub fn origin(self: *const Ray) vec.Vec3 {
        return self._origin;
    }

    pub fn direction(self: *const Ray) vec.Vec3 {
        return self._direction;
    }

    pub fn at(self: *const Ray, t: f64) vec.Vec3 {
        return self._origin + vec.splat(t) * self._direction;
    }

    pub fn color(self: Ray, depth: usize, world: *HittableList) vec.Vec3 {
        if (depth <= 0) {
            return vec.zero;
        }

        const init: Interval = .{ .min = 0.001, .max = std.math.inf(f64) };
        if (world.hit(self, init)) |hr| {
            if (hr.material.scatter(self, hr)) |scatter| {
                return scatter.attenuation * scatter.ray.color(depth - 1, world);
            }
            return vec.zero;
        }

        const unit_direction = vec.unit(self.direction());
        const a = 0.5 * (vec.y(unit_direction) + 1.0);
        const blue: vec.Vec3 = .{ 0.5, 0.7, 1.0 };

        return vec.splat(1.0 - a) * vec.one + vec.splat(a) * blue;
    }
};
