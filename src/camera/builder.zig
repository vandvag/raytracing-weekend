const std = @import("std");
const camera = @import("camera.zig");
const Camera = camera.Camera;
const vec = @import("../vec.zig");
const rtw = @import("../rtweekend.zig");

pub const CameraBuilder = struct {
    m_aspect_ratio: f64,
    m_image_width: u32,
    m_samples_per_pixel: u32,
    m_max_depth: u32,
    m_vfov: f64,
    m_look_from: vec.Vec3,
    m_look_at: vec.Vec3,
    m_vup: vec.Vec3,
    m_defocus_angle: f64,
    m_focus_distance: f64,

    pub fn default() CameraBuilder {
        return .{
            .m_aspect_ratio = 16.0 / 9.0,
            .m_image_width = 400,
            .m_samples_per_pixel = 10,
            .m_max_depth = 10,
            .m_vfov = 90.0,
            .m_look_from = vec.zero,
            .m_look_at = .{ 0.0, 0.0, -1.0 },
            .m_vup = .{ 0.0, 1.0, 0.0 },
            .m_defocus_angle = 0.0,
            .m_focus_distance = 10.0,
        };
    }

    pub fn build(self: *CameraBuilder) Camera {
        const width_float: f64 = @floatFromInt(self.m_image_width);
        const height = width_float / self.m_aspect_ratio;
        const height_int: u32 = @intFromFloat(height);
        const img_height: u32 = if (height_int < 1) 1 else height_int;
        const height_float: f64 = @floatFromInt(img_height);

        const center = self.m_look_from;

        // Determine viewport dimensions
        const theta = rtw.deg2rad(self.m_vfov);
        const h = std.math.tan(theta / 2.0);
        const viewport_height = 2.0 * h * self.m_focus_distance;
        const viewport_width = viewport_height * width_float / height_float;

        // Camera frame basis vectors
        const w = vec.unit(self.m_look_from - self.m_look_at);
        const u = vec.unit(vec.cross3(self.m_vup, w));
        const v = vec.cross3(w, u);

        // Calculate the vectors accross the horizontal and down the vertical viewport edges.
        // Vector across the viewport horizontal edge
        const viewport_u = vec.splat(viewport_width) * u;
        // Vector down viewport vertical edge
        const viewport_v = vec.splat(viewport_height) * (-v);

        // Calculate horizontal and vertical delta vectors from pixel to pixel.
        const pixel_delta_u = viewport_u / vec.splat(width_float);
        const pixel_delta_v = viewport_v / vec.splat(height_float);

        // Calculate the location of the upper left pixel.
        const viewport_upper_left = center - vec.splat(self.m_focus_distance) * w - viewport_u / vec.splat(2.0) - viewport_v / vec.splat(2.0);
        const origin_pixel_location = viewport_upper_left + (pixel_delta_u + pixel_delta_v) * vec.splat(0.5);

        // Calculate the camera defocus disk basis vectors.
        const defocus_radius = self.m_focus_distance * std.math.tan(rtw.deg2rad(self.m_defocus_angle / 2.0));
        const defocus_disk_u = u * vec.splat(defocus_radius);
        const defocus_disk_v = v * vec.splat(defocus_radius);

        return .{
            .aspect_ratio = self.m_aspect_ratio,
            .img_width = self.m_image_width,
            .img_height = img_height,
            .center = center,
            .pixel00_location = origin_pixel_location,
            .pixel_delta_u = pixel_delta_u,
            .pixel_delta_v = pixel_delta_v,
            .samples_per_pixel = self.m_samples_per_pixel,
            .max_depth = self.m_max_depth,
            .vfov = self.m_vfov,
            .look_from = self.m_look_from,
            .look_at = self.m_look_at,
            .vup = self.m_vup,
            .u = u,
            .v = v,
            .w = w,
            .defocus_angle = self.m_defocus_angle,
            .focus_distance = self.m_focus_distance,
            .defocus_disk_u = defocus_disk_u,
            .defocus_disk_v = defocus_disk_v,
        };
    }

    pub fn image_width(self: *CameraBuilder, width: u32) *CameraBuilder {
        self.m_image_width = width;
        return self;
    }

    pub fn aspect_ratio(self: *CameraBuilder, ratio: f64) *CameraBuilder {
        self.m_aspect_ratio = ratio;
        return self;
    }

    pub fn samples_per_pixel(self: *CameraBuilder, samples: u32) *CameraBuilder {
        self.m_samples_per_pixel = samples;
        return self;
    }

    pub fn max_depth(self: *CameraBuilder, depth: u32) *CameraBuilder {
        self.m_max_depth = depth;
        return self;
    }

    pub fn vfov(self: *CameraBuilder, fov: f64) *CameraBuilder {
        self.m_vfov = fov;
        return self;
    }

    pub fn look_from(self: *CameraBuilder, from: vec.Vec3) *CameraBuilder {
        self.m_look_from = from;
        return self;
    }

    pub fn look_at(self: *CameraBuilder, at: vec.Vec3) *CameraBuilder {
        self.m_look_at = at;
        return self;
    }

    pub fn vup(self: *CameraBuilder, up: vec.Vec3) *CameraBuilder {
        self.m_vup = up;
        return self;
    }

    pub fn defocus_angle(self: *CameraBuilder, angle: f64) *CameraBuilder {
        self.m_defocus_angle = angle;
        return self;
    }

    pub fn focus_distance(self: *CameraBuilder, distance: f64) *CameraBuilder {
        self.m_focus_distance = distance;
        return self;
    }
};
