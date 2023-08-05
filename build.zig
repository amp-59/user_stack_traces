pub const zl = @import("./zig_lib/zig_lib.zig");

pub const Node = zl.build.GenericNode(.{});

pub fn buildMain(allocator: *zl.build.Allocator, toplevel: *Node) void {
    const node: *Node = toplevel.addBuild(
        allocator,
        .{ .kind = .exe },
        "main",
        "src/main.zig",
    );
    node.descr = "Main binary";
    node.addConfig(allocator, "case", .{ .String = "stack_overflow" });
}
