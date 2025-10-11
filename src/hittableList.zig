const std = @import("std");

const hit = @import("hittable.zig");
const Hittable = hit.Hittable;
const HitRecord = hit.HitRecord;

const Ray = @import("ray.zig").Ray;

const Interval = @import("interval.zig").Interval;

pub const HittableList = struct {
    objects: std.ArrayList(Hittable),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .objects = std.ArrayList(Hittable).empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.objects.deinit(self.allocator);
    }

    pub fn add(self: *Self, obj: Hittable) !void {
        try self.objects.append(self.allocator, obj);
    }

    pub fn hit(self: *Self, r: Ray, interval: Interval) ?HitRecord {
        var closest_so_far = interval.max;
        var hit_record: ?HitRecord = null;

        for (self.objects.items) |obj| {
            const hr = obj.hit(r, .{ .min = interval.min, .max = closest_so_far }) orelse continue;

            hit_record = hr;
            closest_so_far = hr.t;
        }

        return hit_record;
    }
};
