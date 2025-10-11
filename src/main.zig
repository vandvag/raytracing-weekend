const std = @import("std");
const Progress = std.Progress;
const builtin = @import("builtin");

const Camera = @import("camera.zig");
const color = @import("color.zig");
const Color = color.Color;
const hitlist = @import("hittableList.zig");
const HittableList = hitlist.HittableList;
const ht = @import("hittable.zig");
const Hittable = ht.Hittable;
const Interval = @import("interval.zig").Interval;
const Ray = @import("ray.zig").Ray;
const Sphere = @import("sphere.zig").Sphere;
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const mat = @import("material.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // World stuff
    var world = HittableList.init(allocator);
    defer world.deinit();

    const material_ground: mat.Lambertian = .{
        .albedo = .{ 0.8, 0.8, 0.0 },
    };
    const material_center: mat.Lambertian = .{
        .albedo = .{ 0.1, 0.2, 0.5 },
    };
    const material_left: mat.Metal = .{
        .albedo = .{ 0.8, 0.8, 0.8 },
        .fuzz = 0.3,
    };
    const material_right: mat.Metal = .{
        .albedo = .{ 0.8, 0.6, 0.2 },
        .fuzz = 1.0,
    };

    const sph1: Hittable = .{
        .Sphere = .{
            .center = .{ 0.0, -100.5, -1.0 },
            .radius = 100.0,
            .material = .{
                .Lambertian = material_ground,
            },
        },
    };
    try world.add(sph1);

    const sph2: Hittable = .{
        .Sphere = .{
            .center = .{ 0.0, 0.0, -1.2 },
            .radius = 0.5,
            .material = .{
                .Lambertian = material_center,
            },
        },
    };
    try world.add(sph2);

    const sph3: Hittable = .{
        .Sphere = .{
            .center = .{ -1.0, 0.0, -1.0 },
            .radius = 0.5,
            .material = .{
                .Metal = material_left,
            },
        },
    };
    try world.add(sph3);

    const sph4: Hittable = .{
        .Sphere = .{
            .center = .{ 1.0, 0.0, -1.0 },
            .radius = 0.5,
            .material = .{
                .Metal = material_right,
            },
        },
    };
    try world.add(sph4);

    try Camera.render(&world);
}
