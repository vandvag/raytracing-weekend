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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // World stuff
    var world = HittableList.init(allocator);
    defer world.deinit();
    const sph1: Hittable = .{
        .Sphere = .{
            .center = .{ 0.0, 0.0, -1.0 },
            .radius = 0.5,
        },
    };
    try world.add(sph1);

    const sph2: Hittable = .{
        .Sphere = .{
            .center = .{ 0.0, -100.5, -1.0 },
            .radius = 100,
        },
    };
    try world.add(sph2);

    try Camera.render(&world);
}
