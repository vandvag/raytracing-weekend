const std = @import("std");
const builtin = @import("builtin");

const rwt = @import("rtweekend.zig");

const hittable = @import("hittable.zig");
const Hittable = hittable.Hittable;

const hitlist = @import("hittableList.zig");
const HittableList = hitlist.HittableList;

const color = @import("color.zig");
const Color = color.Color;

const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

const Ray = @import("ray.zig").Ray;

const Interval = @import("interval.zig").Interval;

// TODO: Later, these should be input for the cli
const img_width = if (builtin.mode == .ReleaseFast) 1000 else 400;
const aspect_ratio = 16.0 / 9.0;
const samples_per_pixel = if (builtin.mode == .ReleaseFast) 100 else 10;
const max_depth = if (builtin.mode == .ReleaseFast) 50 else 10;

const width_float: comptime_float = @floatFromInt(img_width);
const img_height = blk: {
    const height = (img_width + 0.0) / aspect_ratio;
    const height_int: comptime_int = @intFromFloat(height);
    break :blk if (height_int < 1) 1 else height_int;
};
const center = vec.zero;
const focal_length = 1.0;
const viewport_height = 2.0;
const viewport_width = blk: {
    const img_width_f64: comptime_float = @floatFromInt(img_width);
    const img_height_f64: comptime_float = @floatFromInt(img_height);
    const ratio: comptime_float = img_width_f64 / img_height_f64;
    break :blk ratio * viewport_height;
};
const viewport_u: Vec3 = .{ viewport_width, 0.0, 0.0 };
const viewport_v: Vec3 = .{ 0.0, -viewport_height, 0.0 };
const pixel_delta_u = viewport_u / vec.splat(img_width);
const pixel_delta_v = viewport_v / vec.splat(img_height);
const viewport_upper_left: Vec3 = blk: {
    const focal: Vec3 = .{ 0.0, 0.0, focal_length };
    break :blk center - focal - viewport_u / vec.splat(2.0) - viewport_v / vec.splat(2.0);
};
const origin_pixel_location = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * vec.splat(0.5);

pub fn render(world: *HittableList) !void {
    var wbuffer: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuffer);
    const out = &file_writer.interface;

    var progress_buffer: [1024]u8 = undefined;
    const progress = std.Progress.start(.{
        .draw_buffer = &progress_buffer,
        .estimated_total_items = img_height,
        .root_name = "Rendering",
    });
    defer progress.end();

    try out.print("P3\n{d} {d}\n255\n", .{ img_width, img_height });

    for (0..img_height) |h| {
        defer progress.completeOne();
        for (0..img_width) |w| {
            var pixel_color = vec.zero;
            for (0..samples_per_pixel) |_| {
                const ray = getRay(w, h);
                pixel_color += rayColor(ray, max_depth, world);
            }

            pixel_color /= vec.splat(samples_per_pixel);
            try out.print("{f}", .{color.fromVec3(pixel_color)});
        }
    }

    try out.flush();
}

fn rayColor(r: Ray, depth: usize, world: *HittableList) Vec3 {
    if (depth <= 0) {
        return vec.zero;
    }

    const init: Interval = .{ .min = 0.001, .max = std.math.inf(f64) };
    if (world.hit(r, init)) |hr| {
        const direction = vec.randomOnHemishere(hr.normal);
        return vec.splat(0.5) * rayColor(.{ ._origin = hr.point, ._direction = direction }, depth - 1, world);
    }

    const unit_direction = vec.unit(r.direction());
    const a = 0.5 * (vec.y(unit_direction) + 1.0);
    const blue: Vec3 = .{ 0.5, 0.7, 1.0 };
    const v = vec.splat(1.0 - a) * vec.one + vec.splat(a) * blue;
    return v;
}

fn getRay(w: usize, h: usize) Ray {
    const wd: f64 = @floatFromInt(w);
    const hd: f64 = @floatFromInt(h);
    const offset = sampleSquare();
    const pixel_sample = origin_pixel_location +
        vec.splat(wd + vec.x(offset)) * pixel_delta_u +
        vec.splat(hd + vec.y(offset)) * pixel_delta_v;

    const ray_origin = center;
    const ray_direction = pixel_sample - ray_origin;

    return .{
        ._origin = ray_origin,
        ._direction = ray_direction,
    };
}

fn sampleSquare() Vec3 {
    return .{
        rwt.getRandom(f64) - 0.5,
        rwt.getRandom(f64) - 0.5,
        0.0,
    };
}
