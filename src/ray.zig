const vec = @import("vec.zig");

pub const Ray = struct {
    _origin: vec.Vec3,
    _direction: vec.Vec3,

    pub fn origin(self: *const Ray) vec.Vec3 {
        return self._origin;
    }

    pub fn direction(self: *const Ray) vec.Vec3 {
        return self._direction;
    }

    pub fn at(self: *const Ray, t: f64) vec.Vec3 {
        return self._origin + t * self._direction;
    }
};
