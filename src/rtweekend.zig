const std = @import("std");

pub var random_state = std.Random.DefaultPrng.init(1);

pub fn getRandom(comptime T: type) T {
    const random = random_state.random();

    return switch(@typeInfo(T)) {
        .comptime_float, .float => random.float(T),
        .comptime_int, .int => random.int(T),
        else => @compileError("getRandom is supported only for integers and floats")
    };
}

pub fn getRandomInRange(comptime T: type, min: T, max: T) T {
    return min + (max - min) * getRandom(T);
}
