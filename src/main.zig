const std = @import("std");
const Progress = std.Progress;

const color = @import("color.zig");
const Color = color.Color;
const Ray = @import("ray.zig").Ray;
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const camera_center: Vec3 = vec.zero;

const ASPECT_RATIO = 16.0 / 9.0;
const IMG_WIDTH = 400;
const IMG_HEIGHT = blk: {
    const width_float: comptime_float = @floatFromInt(IMG_WIDTH);
    const height: comptime_int = @intFromFloat(width_float / ASPECT_RATIO);
    break :blk if (height < 1) 1 else height;
};

const VIEWPORT_HEIGHT = 2.0;
const VIEWPORT_WIDTH = blk: {
    const ratio = (IMG_WIDTH + 0.0) / (IMG_HEIGHT + 0.0);
    // const ratio: comptime_float = @floatFromInt(IMG_WIDTH / IMG_HEIGHT);
    break :blk ratio * VIEWPORT_HEIGHT;
};

// Camera
const focal_length = 1.0;
// Calculate vectors accross the horizonttal and down the vertical viewport edges
const viewport_u: Vec3 = .{ VIEWPORT_WIDTH, 0.0, 0.0 };
const viewport_v: Vec3 = .{ 0.0, -VIEWPORT_HEIGHT, 0.0 };
// Calculate the horizontal and vertical delta vectors from pixel to pixel.
const pixel_delta_u = viewport_u / vec.splat(IMG_WIDTH);
const pixel_delta_v = viewport_v / vec.splat(IMG_HEIGHT);
// Calculate the location of the upper left pixel.
const viewport_upper_left: Vec3 = blk: {
    const focal: Vec3 = .{ 0.0, 0.0, focal_length };
    break :blk camera_center - focal - viewport_u / vec.splat(2.0) - viewport_v / vec.splat(2.0);
};
const pixel_origin_location: Vec3 = viewport_upper_left + (pixel_delta_u + pixel_delta_v) / vec.splat(2.0);

pub fn main() !void {
    var wbuffer: [4096]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&wbuffer);
    const out = &file_writer.interface;

    var progress_buffer: [1024]u8 = undefined;
    const progress = Progress.start(.{
        .draw_buffer = &progress_buffer,
        .estimated_total_items = IMG_HEIGHT * IMG_WIDTH,
        .root_name = "Rendering",
    });
    defer progress.end();

    try out.print("P3\n{d} {d}\n255\n", .{ IMG_WIDTH, IMG_HEIGHT });

    for (0..IMG_HEIGHT) |h| {
        progress.completeOne();
        for (0..IMG_WIDTH) |w| {
            const pixel_center = pixel_origin_location + (vec.splat(w) * pixel_delta_u) + (vec.splat(h) * pixel_delta_v);
            const ray_direction = pixel_center - camera_center;
            const ray: Ray = .{
                ._origin = camera_center,
                ._direction = vec.unit(ray_direction),
            };

            const pixel_color = rayColor(ray);

            try out.print("{f}", .{pixel_color});
        }
    }

    try out.flush();
}

fn rayColor(r: Ray) Color {
    const sphere_center: Vec3 = .{ 0.0, 0.0, -1.0 };
    const radius = 0.5;
    if (hitSphere(sphere_center, radius, r)) {
        return color.fromVec3(.{ 1.0, 0.0, 0.0 });
    }

    const unit_direction = vec.unit(r.direction());
    const a = 0.5 * (vec.y(unit_direction) + 1.0);
    const blue: Vec3 = .{ 0.5, 0.7, 1.0 };
    return color.fromVec3(vec.splat(1.0 - a) * vec.one + vec.splat(a) * blue);
}

fn hitSphere(center: Vec3, radius: f64, r: Ray) bool {
    const oc = center - r.origin();
    const a = vec.dot(r.direction(), r.direction());
    const b = -2.0 * vec.dot(r.direction(), oc);
    const c = vec.dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4 * a * c;
    return (discriminant >= 0);
}
