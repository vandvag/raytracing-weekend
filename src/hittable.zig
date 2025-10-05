const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");

const Ray = @import("ray.zig").Ray;
const sphr = @import("sphere.zig");
const Sphere = sphr.Sphere;
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

pub const HitRecord = struct {
    t: f64,
    point: Vec3,
    normal: Vec3,
    front_face: bool,

    const Self = @This();

    pub fn init(t: f64, r: Ray, point: Vec3, outward_normal: Vec3) Self {
        if (builtin.mode == .Debug) {
            // const one = vec.len2(outward_normal);
            // assert(std.math.approxEqAbs(f64, one, 1.0, std.math.floatEps(f64)));
        }

        const front_face = vec.dot(r.direction(), outward_normal) < 0.0;

        return .{
            .t = t,
            .point = point,
            .normal = if (front_face) outward_normal else -outward_normal,
            .front_face = front_face,
        };
    }
};

pub const Hittable = union(enum) {
    Sphere: Sphere,

    const Self = @This();
    pub fn hit(self: Self, r: Ray, ray_min: f64, ray_max: f64) ?HitRecord {
        return switch (self) {
            .Sphere => |s| s.hit(r, ray_min, ray_max),
        };
    }
};
