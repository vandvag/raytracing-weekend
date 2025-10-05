const std = @import("std");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Ray = @import("ray.zig").Ray;
const hittable = @import("hittable.zig");
const HitRecord = hittable.HitRecord;

pub const Sphere = struct {
    center: Vec3,
    radius: f64,

    const Self = @This();

    pub fn hit(self: *const Self, r: Ray, ray_tmin: f64, ray_tmax: f64) ?HitRecord {
        const oc = self.center - r.origin();
        const a = vec.len2(r.direction());
        const h = vec.dot(r.direction(), oc);
        const c = vec.len2(oc) - self.radius * self.radius;
        const discriminant = h * h - a * c;

        if (discriminant < 0) {
            return null;
        }

        const discr_sqrt = std.math.sqrt(discriminant);

        var root = (h - discr_sqrt) / a;
        if (root <= ray_tmin or root >= ray_tmax) {
            root = (h + discr_sqrt) / a;
            if (root <= ray_tmin or root >= ray_tmax) {
                return null;
            }
        }

        const point = r.at(root);
        const outward_normal = (point - self.center) / vec.splat(self.radius);
        return HitRecord.init(root, r, point, outward_normal);
    }
};
