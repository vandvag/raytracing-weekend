const std = @import("std");
const assert = std.debug.assert;
const builtin = @import("builtin");

const Ray = @import("ray.zig").Ray;

const sphr = @import("sphere.zig");
const Sphere = sphr.Sphere;

const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

const intrv = @import("interval.zig");
const Interval = intrv.Interval;

const mat = @import("material.zig");

pub const HitRecord = struct {
    t: f64,
    point: Vec3,
    normal: Vec3,
    front_face: bool,
    material: mat.Material,

    const Self = @This();

    pub fn init(t: f64, r: Ray, point: Vec3, outward_normal: Vec3, material: mat.Material) Self {
        if (builtin.mode == .Debug) {
            const one = vec.len2(outward_normal);
            assert(std.math.approxEqAbs(f64, one, 1.0, 0.0000000001));
        }

        const front_face = vec.dot(r.direction(), outward_normal) < 0.0;

        return .{
            .t = t,
            .point = point,
            .normal = if (front_face) outward_normal else -outward_normal,
            .front_face = front_face,
            .material = material,
        };
    }
};

pub const Hittable = struct {
    impl: *anyopaque,
    hit_fn: *const fn (*anyopaque, Ray, Interval) ?HitRecord,

    const Self = @This();

    pub fn init(impl_obj: anytype) Self {
        const T = @TypeOf(impl_obj);

        const gen = struct {
            fn hit(impl: *anyopaque, r: Ray, interval: Interval) ?HitRecord {
                const self: T = @ptrCast(@alignCast(impl));
                return self.hit(r, interval);
            }
        };

        return Self{
            .impl = @constCast(impl_obj),
            .hit_fn = gen.hit,
        };
    }

    pub fn hit(self: Self, r: Ray, interval: Interval) ?HitRecord {
        return self.hit_fn(self.impl, r, interval);
    }
};
