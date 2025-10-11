const std = @import("std");

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

const img_width = 400;
const aspect_ratio = 16.0 / 9.0;
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
            const pixel_center = origin_pixel_location + (vec.splat(w) * pixel_delta_u) + (vec.splat(h) * pixel_delta_v);
            const ray_direction = pixel_center - center;
            const ray: Ray = .{
                ._origin = center,
                ._direction = ray_direction,
            };

            const pixel_color = rayColor(ray, world);

            try out.print("{f}", .{pixel_color});
        }
    }

    try out.flush();
}

pub fn rayColor(r: Ray, world: *HittableList) Color {
    const init: Interval = .{.min = 0.0, .max = std.math.inf(f64)};
    if (world.hit(r, init)) |hr| {
        const v = vec.splat(0.5) * (hr.normal + vec.one);
        return color.fromVec3(v);
    }

    const unit_direction = vec.unit(r.direction());
    const a = 0.5 * (vec.y(unit_direction) + 1.0);
    const blue: Vec3 = .{ 0.5, 0.7, 1.0 };
    const v = vec.splat(1.0 - a) * vec.one + vec.splat(a) * blue;
    return color.fromVec3(v);
}
