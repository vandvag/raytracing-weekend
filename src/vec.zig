const std = @import("std");

const rtw = @import("rtweekend.zig");

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

pub fn random() Vec3 {
    return .{
        rtw.getRandom(f64),
        rtw.getRandom(f64),
        rtw.getRandom(f64),
    };
}

pub fn randomRange(min: f64, max: f64) Vec3 {
    return .{
        rtw.getRandomInRange(f64, min, max),
        rtw.getRandomInRange(f64, min, max),
        rtw.getRandomInRange(f64, min, max),
    };
}

// TODO: Highly unlikely that it will be needed, but it would be good to add a max iteration limit here
pub fn randomUnitVector() Vec3 {
    while (true) {
        const p = random();
        const l = len2(p);
        if (1.0e-160 <= l and l <= 1.0) {
            return unit(p);
        }
    }
}

pub fn randomOnHemishere(normal: Vec3) Vec3 {
    const on_unit_shere = randomUnitVector();

    return if (dot(on_unit_shere, normal) > 0.0) on_unit_shere else -on_unit_shere;
}

/// Return true if the vector is close to zero in all dimensions
pub fn nearZero(v: Vec3) bool {
    const tol = 1e-8;
    return std.math.approxEqAbs(f64, v[0], 0.0, tol) and
        std.math.approxEqAbs(f64, v[1], 0.0, tol) and
        std.math.approxEqAbs(f64, v[2], 0.0, tol);
}

pub fn reflect(v: Vec3, n: Vec3) Vec3 {
    return v - splat(2.0 * dot(v, n)) * n;
}

pub fn refract(uv: Vec3, n: Vec3, etai_over_etat: f64) Vec3 {
    const cos_theta = @min(dot(-uv, n), 1.0);
    const r_out_perp = splat(etai_over_etat) * (uv + splat(cos_theta) * n);
    const r_out_parallel = -splat(std.math.sqrt(@abs(1.0 - len2(r_out_perp)))) * n;

    return r_out_perp + r_out_parallel;
}

pub fn randomInUnitDisk() Vec3 {
    while (true) {
        const p: Vec3 = .{ rtw.getRandomInRange(f64, -1.0, 1.0), rtw.getRandomInRange(f64, -1.0, 1.0), 0.0 };
        if (len2(p) < 1.0) {
            return p;
        }
    }
}
