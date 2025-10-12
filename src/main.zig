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
const rtw = @import("rtweekend.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var world = try finalScene(allocator);
    defer world.deinit();

    try Camera.render(&world);
}

fn scene1(allocator: std.mem.Allocator) !HittableList {
    // World stuff
    var world = HittableList.init(allocator);

    const material_ground: mat.Lambertian = .{
        .albedo = .{ 0.8, 0.8, 0.0 },
    };
    const material_center: mat.Lambertian = .{
        .albedo = .{ 0.1, 0.2, 0.5 },
    };
    const material_left: mat.Dielectric = .{
        .refraction_index = 1.50,
    };
    const material_bubble: mat.Dielectric = .{
        .refraction_index = 1.00 / 1.50,
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
                .Dielectric = material_left,
            },
        },
    };
    try world.add(sph3);

    const sph4: Hittable = .{
        .Sphere = .{
            .center = .{ -1.0, 0.0, -1.0 },
            .radius = 0.4,
            .material = .{
                .Dielectric = material_bubble,
            },
        },
    };
    try world.add(sph4);

    const sph5: Hittable = .{
        .Sphere = .{
            .center = .{ 1.0, 0.0, -1.0 },
            .radius = 0.5,
            .material = .{
                .Metal = material_right,
            },
        },
    };
    try world.add(sph5);

    return world;
}

fn scene2(allocator: std.mem.Allocator) !HittableList {
    const R = std.math.cos(std.math.pi / 4.0);

    var world = HittableList.init(allocator);

    const material_left: mat.Lambertian = .{
        .albedo = .{ 0.0, 0.0, 1.0 },
    };
    const material_right: mat.Lambertian = .{
        .albedo = .{ 1.0, 0.0, 0.0 },
    };

    const sph1: Hittable = .{
        .Sphere = .{
            .center = .{ -R, 0.0, -1.0 },
            .radius = R,
            .material = .{
                .Lambertian = material_left,
            },
        },
    };

    try world.add(sph1);

    const sph2: Hittable = .{
        .Sphere = .{
            .center = .{ R, 0.0, -1.0 },
            .radius = R,
            .material = .{
                .Lambertian = material_right,
            },
        },
    };

    try world.add(sph2);

    return world;
}

fn finalScene(allocator: std.mem.Allocator) !HittableList {
    var world = HittableList.init(allocator);

    const ground_material: mat.Lambertian = .{ .albedo = .{ 0.5, 0.5, 0.5 } };

    const ground: Sphere = .{
        .center = .{ 0.0, -1000.0, 0.0 },
        .radius = 1000.0,
        .material = .{ .Lambertian = ground_material },
    };
    try world.add(.{ .Sphere = ground });

    var i: i8 = -11;
    while (i < 11) {
        const a: f64 = @floatFromInt(i);
        var j: i8 = -11;
        while (j < 11) {
            const b: f64 = @floatFromInt(j);
            const choose_mat = rtw.getRandom(f64);
            const center: Vec3 = .{ a + 0.9 * rtw.getRandom(f64), 0.2, b + 0.9 * rtw.getRandom(f64) };

            const v: Vec3 = .{ 4.0, 0.2, 0.0 };
            if (vec.len(center - v) > 0.9) {
                var sphere_mat: mat.Material = undefined;

                if (choose_mat < 0.8) {
                    sphere_mat = .{ .Lambertian = .{ .albedo = vec.random() * vec.random() } };
                } else if (choose_mat < 0.95) {
                    sphere_mat = .{
                        .Metal = .{
                            .albedo = vec.random() * vec.random(),
                            .fuzz = rtw.getRandomInRange(f64, 0.0, 0.5),
                        },
                    };
                } else {
                    sphere_mat = .{
                        .Dielectric = .{ .refraction_index = 1.5 },
                    };
                }

                try world.add(.{
                    .Sphere = .{
                        .center = center,
                        .radius = 0.2,
                        .material = sphere_mat,
                    },
                });
            }
            j += 1;
        }
        i += 1;
    }

    const mat1: mat.Material = .{ .Dielectric = .{ .refraction_index = 1.5 } };
    try world.add(.{
        .Sphere = .{
            .center = .{ 0.0, 1.0, 0.0 },
            .radius = 1.0,
            .material = mat1,
        },
    });

    const mat2: mat.Material = .{ .Lambertian = .{ .albedo = .{ 0.4, 0.2, 0.1 } } };
    try world.add(.{
        .Sphere = .{
            .center = .{ -4.0, 1.0, 0.0 },
            .radius = 1.0,
            .material = mat2,
        },
    });

    const mat3: mat.Material = .{ .Metal = .{ .albedo = .{ 0.7, 0.6, 0.5 }, .fuzz = 0.0 } };
    try world.add(.{
        .Sphere = .{
            .center = .{ -4.0, 1.0, 0.0 },
            .radius = 1.0,
            .material = mat3,
        },
    });

    return world;
}
