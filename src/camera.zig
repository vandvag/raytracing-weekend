const std = @import("std");
const builtin = @import("builtin");

const color = @import("color.zig");
const Color = color.Color;
const hitlist = @import("hittableList.zig");
const HittableList = hitlist.HittableList;
const hittable = @import("hittable.zig");
const Hittable = hittable.Hittable;
const Interval = @import("interval.zig").Interval;
const mat = @import("material.zig");
const Ray = @import("ray.zig").Ray;
const rwt = @import("rtweekend.zig");
const vec = @import("vec.zig");
const Vec3 = vec.Vec3;

// TODO: Later, these should be input for the cli
/// Rendered image width in pixel count
const img_width = if (builtin.mode == .ReleaseFast) 1200 else 400;
/// Ratio of image width over height
const aspect_ratio = 16.0 / 9.0;
/// Count of random samples for each pixel
const samples_per_pixel = if (builtin.mode == .ReleaseFast) 500 else 10;
/// Maximum number of ray bounces into scene
const max_depth = if (builtin.mode == .ReleaseFast) 50 else 10;
/// Vertical view angle (field of view)
const vfov = 20;
/// Point camera is looking from
const look_from: vec.Vec3 = .{13.0, 2.0, 3.0};
/// Point camera is looking at
const look_at: vec.Vec3 = .{ 0.0, 0.0, 0.0 };
/// Camera relative "up" direction
const vup: vec.Vec3 = .{ 0.0, 1.0, 0.0 };
/// Variation angle of rays through each pixel
const defocus_angle = 0.6;
/// Distance from camera lookfrom point to plane of perfect focus
const focus_distance = 10.0;

const width_float: comptime_float = @floatFromInt(img_width);
const img_height = blk: {
    const height = (img_width + 0.0) / aspect_ratio;
    const height_int: comptime_int = @intFromFloat(height);
    break :blk if (height_int < 1) 1 else height_int;
};

const center = look_from;

// Determine viewport dimensions
const theta = rwt.deg2rad(vfov);
const h = std.math.tan(theta / 2);
const viewport_height = 2.0 * h * focus_distance;
const viewport_width = blk: {
    const img_width_f64: comptime_float = @floatFromInt(img_width);
    const img_height_f64: comptime_float = @floatFromInt(img_height);
    const ratio: comptime_float = img_width_f64 / img_height_f64;
    break :blk ratio * viewport_height;
};

/// Camera frame basis vectors
const w = vec.unit(look_from - look_at);
const u = vec.unit(vec.cross3(vup, w));
const v = vec.cross3(w, u);

// Calculate the vectors accross the horizontal and down the vertical viewport edges.
/// Vector across the viewport horizontal edge
const viewport_u = vec.splat(viewport_width) * u;
/// Vector down viewport vertical edge
const viewport_v = vec.splat(viewport_height) * (-v);

// Calculate horizontal and vertical delta vectors from pixel to pixel.
const pixel_delta_u = viewport_u / vec.splat(img_width);
const pixel_delta_v = viewport_v / vec.splat(img_height);

// Calculate the location of the upper left pixel.
const viewport_upper_left = center - vec.splat(focus_distance) * w - viewport_u / vec.splat(2.0) - viewport_v / vec.splat(2.0);
const origin_pixel_location = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * vec.splat(0.5);

// Calculate the camera defocus disk basis vectors.
const defocus_radius = focus_distance * std.math.tan(rwt.deg2rad(defocus_angle / 2.0));
const defocus_disk_u = u * vec.splat(defocus_radius);
const defocus_disk_v = v * vec.splat(defocus_radius);

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

    for (0..img_height) |height| {
        defer progress.completeOne();
        for (0..img_width) |width| {
            var pixel_color = vec.zero;
            for (0..samples_per_pixel) |_| {
                const ray = getRay(width, height);
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
        if (hr.material.scatter(r, hr)) |scatter| {
            return scatter.attenuation * rayColor(scatter.ray, depth - 1, world);
        }
        return vec.zero;
    }

    const unit_direction = vec.unit(r.direction());
    const a = 0.5 * (vec.y(unit_direction) + 1.0);
    const blue: Vec3 = .{ 0.5, 0.7, 1.0 };

    return vec.splat(1.0 - a) * vec.one + vec.splat(a) * blue;
}

/// Construct a camera ray originating from the defocus disk and directed at a randomly
/// sampled point around the pixel location (width, height)
fn getRay(width: usize, height: usize) Ray {
    const wd: f64 = @floatFromInt(width);
    const hd: f64 = @floatFromInt(height);
    const offset = sampleSquare();
    const pixel_sample = origin_pixel_location +
        vec.splat(wd + vec.x(offset)) * pixel_delta_u +
        vec.splat(hd + vec.y(offset)) * pixel_delta_v;

    const ray_origin = if (defocus_angle <= 0.0) center else defocusDiskSample();
    const ray_direction = pixel_sample - ray_origin;

    return .{
        ._origin = ray_origin,
        ._direction = ray_direction,
    };
}

fn defocusDiskSample() Vec3 {
    const p = vec.randomInUnitDisk();
    return center + (vec.splat(vec.x(p)) * defocus_disk_u) + (vec.splat(vec.y(p)) * defocus_disk_v);
}

fn sampleSquare() Vec3 {
    return .{
        rwt.getRandom(f64) - 0.5,
        rwt.getRandom(f64) - 0.5,
        0.0,
    };
}
