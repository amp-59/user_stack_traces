const decls = @cImport({});
const zl = @import("../zig_lib/zig_lib.zig");

pub usingnamespace zl.start;

const access_inactive: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{ .show_line_no = false },
    };
    fn accessInactiveUnionField() void {
        var u: union(enum) {
            a: u64,
            b: u32,
        } = .{ .a = 25 };
        u.a = u.b;
    }
    pub fn main() void {
        accessInactiveUnionField();
    }
};

const start_gt_end: type = struct {
    pub const trace: zl.debug.Trace = .{};
    fn startGreaterThanEnd() void {
        var a: [4096]u8 = undefined;
        const b: [:0]u8 = a[@intFromPtr(&a)..512 :0];
        b[256] = 'b';
    }
    pub fn main() void {
        startGreaterThanEnd();
    }
};

const reach_unreachable: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{
            .show_line_no = true,
            .show_pc_addr = true,
        },
    };
    fn reachUnreachableCode() void {
        unreachable;
    }
    pub fn main() void {
        reachUnreachableCode();
    }
};
const reach_unreachable2: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{
            .show_line_no = true,
            .show_pc_addr = true,
            .break_line_count = 1,
        },
    };
    pub fn main() void {
        reach_unreachable.reachUnreachableCode();
    }
};
const out_of_bounds: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{
            .show_line_no = true,
            .write_caret = false,
            .break_line_count = 1,
        },
    };
    fn causeOutOfBounds() void {
        var idx: usize = 512;
        var a: [512]u8 = undefined;
        a[idx] = 'a';
    }
    pub fn main() void {
        causeOutOfBounds();
    }
};
const sentinel_mismatch: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{
            .show_line_no = true,
            .write_caret = false,
            .context_line_count = 1,
        },
    };
    fn causeSentinelMismatch() void {
        var a: [4096]u8 = undefined;
        const b: [:0]u8 = a[0..512 :0];
        b[256] = 'b';
    }
    pub fn main() void {
        causeSentinelMismatch();
    }
};
const assertion_failed: type = struct {
    pub const trace: zl.debug.Trace = .{
        .options = .{
            .show_line_no = true,
            .write_caret = true,
            .tokens = .{
                .sidebar_fill = ": ",
                .sidebar = "│",
                .syntax = &.{.{ .tags = &.{.identifier}, .style = "\x1b[96m" }},
            },
        },
    };
    fn causeAssertionFailed() void {
        var x: u64 = 0x10000;
        var y: u64 = 0x10010;
        zl.builtin.assertEqual(u64, x, y);
    }
    pub fn main() void {
        causeAssertionFailed();
    }
};
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .context_line_count = 1,
        .break_line_count = 1,
        .write_caret = false,
        .tokens = zl.builtin.my_trace.options.tokens,
    },
};
fn causeStackOverflow() void {
    var a: [4096]u8 = undefined;
    a[0] = 'a';
    causeStackOverflow();
    unreachable;
}
pub fn main() void {
    causeStackOverflow();
}
