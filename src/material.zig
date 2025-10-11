const std = @import("std");

const vec = @import("vec.zig");

const ray = @import("ray.zig");

const hit = @import("hittable.zig");

pub const Scatter = struct {
    ray: ray.Ray,
    attenuation: vec.Vec3,
};

pub const Material = union(enum) {
    Lambertian: Lambertian,
    Metal: Metal,

    const Self = @This();
    pub fn scatter(self: Self, r_in: ray.Ray, hr: hit.HitRecord) ?Scatter {
        return switch (self) {
            .Lambertian => |l| l.scatter(hr),
            .Metal => |m| m.scatter(r_in, hr),
        };
    }
};

pub const Lambertian = struct {
    albedo: vec.Vec3,

    const Self = @This();
    pub fn scatter(self: Self, hr: hit.HitRecord) ?Scatter {
        var scatter_direction = hr.normal + vec.randomUnitVector();

        if (vec.nearZero(scatter_direction)) {
            scatter_direction = hr.normal;
        }

        return .{
            .ray = .{
                ._origin = hr.point,
                ._direction = scatter_direction,
            },
            .attenuation = self.albedo,
        };
    }
};

pub const Metal = struct {
    albedo: vec.Vec3,
    fuzz: f64,

    const Self = @This();

    pub fn scatter(self: Self, r_in: ray.Ray, hr: hit.HitRecord) ?Scatter {
        const reflected = vec.unit(vec.reflect(r_in.direction(), hr.normal)) + (vec.splat(self.fuzz) * vec.randomUnitVector());

        return .{
            .ray = .{
                ._origin = hr.point,
                ._direction = reflected,
            },
            .attenuation = self.albedo,
        };
    }
};
