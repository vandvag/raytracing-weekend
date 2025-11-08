const std = @import("std");
const builder = @import("builder.zig");
const CameraBuilder = builder.CameraBuilder;
const color = @import("../color.zig");
const Color = color.Color;
const hitlist = @import("../hittableList.zig");
const HittableList = hitlist.HittableList;
const Ray = @import("../ray.zig").Ray;
const vec = @import("../vec.zig");
const rtw = @import("../rtweekend.zig");

pub const Camera = struct {
    /// Ratio of image width over height
    aspect_ratio: f64,
    /// Rendered image width in pixel count
    img_width: u32,
    /// Rendered image height in pixel count
    img_height: u32,
    /// Center of the camera
    center: vec.Vec3,
    /// Location of pixel 0, 0
    pixel00_location: vec.Vec3,
    /// Offset to pixel to the right
    pixel_delta_u: vec.Vec3,
    /// Offset to pixel below
    pixel_delta_v: vec.Vec3,
    /// Count of random samples for each pixel
    samples_per_pixel: u32,
    /// Maximum number of ray bounces into scene
    max_depth: u32,
    /// Vertical view angle (field of view, degrees)
    vfov: f64,
    /// Point camera is looking from
    look_from: vec.Vec3,
    /// Point camera is looking at
    look_at: vec.Vec3,
    /// Camera relative "up" direction
    vup: vec.Vec3,
    /// X axis basis vector
    u: vec.Vec3,
    /// Y axis basis vector
    v: vec.Vec3,
    /// Z axis basis vector
    w: vec.Vec3,
    /// Variation angle of rays through each pixel (degrees)
    defocus_angle: f64,
    /// Distance from camera lookfrom point to plane of perfect focus
    focus_distance: f64,
    /// Defocus disk horizontal radius
    defocus_disk_u: vec.Vec3,
    /// Defocus disk vertical radius
    defocus_disk_v: vec.Vec3,

    pub fn init() CameraBuilder {
        return CameraBuilder.default();
    }

    pub fn render(self: Camera, world: *HittableList) !void {
        var wbuffer: [4096]u8 = undefined;
        var file_writer = std.fs.File.stdout().writer(&wbuffer);
        const out = &file_writer.interface;

        var progress_buffer: [1024]u8 = undefined;
        const progress = std.Progress.start(.{
            .draw_buffer = &progress_buffer,
            .estimated_total_items = self.img_height,
            .root_name = "Rendering",
        });
        defer progress.end();

        try out.print("P3\n{d} {d}\n255\n", .{ self.img_width, self.img_height });

        for (0..self.img_height) |height| {
            defer progress.completeOne();
            for (0..self.img_width) |width| {
                var pixel_color = vec.zero;
                for (0..self.samples_per_pixel) |_| {
                    const ray = self.getRay(width, height);
                    pixel_color += ray.color(self.max_depth, world);
                }

                pixel_color /= vec.splat(self.samples_per_pixel);
                try out.print("{f}", .{color.fromVec3(pixel_color)});
            }
        }

        try out.flush();
    }

    /// Construct a camera ray originating from the defocus disk and directed at a randomly
    /// sampled point around the pixel location (width, height)
    fn getRay(self: Camera, width: usize, height: usize) Ray {
        const wd: f64 = @floatFromInt(width);
        const hd: f64 = @floatFromInt(height);
        const offset = sampleSquare();
        const pixel_sample = self.pixel00_location +
            vec.splat(wd + vec.x(offset)) * self.pixel_delta_u +
            vec.splat(hd + vec.y(offset)) * self.pixel_delta_v;

        const ray_origin = if (self.defocus_angle <= 0.0) self.center else self.defocusDiskSample();
        const ray_direction = pixel_sample - ray_origin;

        return .{
            ._origin = ray_origin,
            ._direction = ray_direction,
        };
    }

    fn defocusDiskSample(self: Camera) vec.Vec3 {
        const p = vec.randomInUnitDisk();
        return self.center + (vec.splat(vec.x(p)) * self.defocus_disk_u) + (vec.splat(vec.y(p)) * self.defocus_disk_v);
    }
};

fn sampleSquare() vec.Vec3 {
    return .{
        rtw.getRandom(f64) - 0.5,
        rtw.getRandom(f64) - 0.5,
        0.0,
    };
}
