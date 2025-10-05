const std = @import("std");

pub const Vec3 = @Vector(3, f64);

pub const zero = Vec3{ 0, 0, 0 };
pub const one = Vec3{ 1, 1, 1 };

pub fn x(v: Vec3) f64 {
    return v[0];
}

pub fn y(v: Vec3) f64 {
    return v[1];
}

pub fn z(v: Vec3) f64 {
    return v[2];
}

pub inline fn len2(v: Vec3) f64 {
    return dot(v, v);
}

pub inline fn len(v: Vec3) f64 {
    return std.math.sqrt(len2(v));
}

pub inline fn dot(v1: Vec3, v2: Vec3) f64 {
    return @reduce(.Add, v1 * v2);
}

pub inline fn cross3(v1: Vec3, v2: Vec3) Vec3 {
    return .{
        v1[1] * v2[2] - v1[2] * v2[1],
        v1[2] * v2[0] - v1[0] * v2[2],
        v1[0] * v2[1] - v1[1] * v2[0],
    };
}

pub inline fn unit(v: Vec3) Vec3 {
    const length = len(v);

    if (length == 0) {
        return zero;
    }

    const splatted: Vec3 = @splat(length);
    return v / splatted;
}

pub fn splat(n: anytype) Vec3 {
    const nT = @TypeOf(n);

    return switch (@typeInfo(nT)) {
        .int, .comptime_int => blk: {
            const ret: f64 = @floatFromInt(n);
            break :blk @splat(ret);
        },
        .float, .comptime_float => @splat(n),
        else => @compileError("splat only works for int and float scalars"),
    };
}
