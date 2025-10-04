pub inline fn vsize(comptime T: type) comptime_int {
    _ = ensureVector(T);

    return @typeInfo(T).vector.len;
}

pub inline fn vtype(comptime T: type) type {
    _ = ensureVector(T);

    return @typeInfo(T).vector.child;
}

pub inline fn len2(v: anytype) vtype(@TypeOf(v)) {
    _ = ensureVector(v);
    return dot(v, v);
}

pub inline fn len(v: anytype) vtype(@TypeOf(v)) {
    return @sqrt(len2(v, v));
}

pub inline fn dot(v1: anytype, v2: anytype) vtype(@TypeOf(v1)) {
    const vt1 = ensureVector(v1);
    const vt2 = ensureVector(v2);

    if (vt1 != vt2) {
        @compileError("Vectors must be of the same type");
    }

    return @reduce(.Add, v1 * v2);
}

pub inline fn cross3(v1: anytype, v2: anytype) @TypeOf(v1) {
    const vt1 = ensureVector(v1);
    const vt2 = ensureVector(v2);

    if (vt1 != vt2) {
        @compileError("Vectors must be of the same type");
    }

    if (vsize(vt1) != 3) {
        @compileError("Cross product is only defined for 3D vectors");
    }

    const x = v1[1] * v2[2] - v1[2] * v2[1];
    const y = v1[2] * v2[0] - v1[0] * v2[2];
    const z = v1[0] * v2[1] - v1[1] * v2[0];

    return vt1{.{ x, y, z }};
}

pub inline fn unit(v: anytype) @TypeOf(v) {
    const vt = ensureVector(v);

    return v / @as(vt, @splat(len(v)));
}

inline fn ensureVector(comptime T: type) type {
    if (@typeInfo(T) != .Vector) {
        @compileError("Expected a vector type, got: " ++ @typeName(T));
    }

    return T;
}
