# Configurable Stack Traces
This project shows two ways to use configurable stack traces:
* Independent root source file `free_main.zig` compiled without using build system.
* Build root with source directory and root source file `src/main.zig`, compiled using build system, defined by `build.zig`.

## Setup
The following script will clone the repository and demonstrate both forms of usage:
```sh
git clone --recursive "https://github.com/amp-59/user_stack_traces" user_stack_traces;
cd user_stack_traces;
zig run free_main.zig;
zig build --build-runner zig_lib/build_runner.zig run main;
```

## Optimisation

### Switching build runner

Using my library's build runner will allow significantly faster compile times for these reasons:
* Build programs (`build.zig`) using the standard library build runner require at least 4 seconds to recompile per edit. My build runner recompiles in 0.3 seconds per edit.
* Programs that require Zig stack traces (usually those with debugging symbols and build mode `Debug`) must have a panic message formatter, DWARF parser, and stack trace formatter in order to display the abort/error message. Using the standard library builder, these components will be recompiled every time the root source file or any dependency is modified. My builder compiles these components once per project, and the output object file is statically linked with all stack-trace-enabled binaries.

```sh
./zig_lib/support/switch_build_runner.sh;
```

Running the script `switch_build_runner.sh` will move the existing standard library build runner to a backup location in the Zig install directory and create a symbolic link to my Zig library's build runner.

Running the script a second time will remove this symbolic link and restore the standard library build runner. In case the script is run consecutively from two different repositories, the existing symbolic link will be removed and replaced with a symbolic link to the build runner in the second repository.

### Overriding panic handlers

A common pattern in the standard library is to check `@import("root")` for certain declarations to allow the user to override default behaviour. To customise stack traces, the following functions require override: `panic`, `panicInactiveUnionField`, `panicOutOfBounds`, `panicSentinelMismatch` `panicStartGreaterThanEnd` and `panicUnwrapError`. Out of these only `panic` currently permits override, but this property is easily extended to the remaining panic handlers by editing `lib/std/builtin.zig`.

The Zig code linked below contains declarations for all panic handlers listed above, each permitting user override. This can be pasted immediately after the declaration of `TestFn` in `lib/std/builtin.zig`, overwriting the rest of the file.

https://zigbin.io/d67223

## Examples

### Similar to standard library format
If all you want are the fast build times, the following configuration is close to the standard library.
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{ .show_line_no = false },
};
pub fn main() void {
    accessInactiveUnionField();
}
```
Output:
![alt text](images/case0.png?raw=true)

### Library default trace
The following `trace` declaration is redundant, because if the root module does not declare `trace` the library default will be used instead.
```zig
pub const trace: zl.builtin.Trace = .{};
pub fn main() void {
    startGreaterThanEnd();
}
```
Output:
![alt text](images/case1.png?raw=true)

### Write program counter address in sidebar
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{
        .show_line_no = true,
        .show_pc_addr = true,
    },
};
pub fn main() void {
    reachUnreachableCode();
}
```
Output:
![alt text](images/case2.png?raw=true)

But this is quite cluttered so adding a line break might assist readability:
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{
        .show_line_no = true,
        .show_pc_addr = true,
        .break_line_count = 1,
    },
};
pub fn main() void {
    reach_unreachable.reachUnreachableCode();
}
```
Output:
![alt text](images/case3.png?raw=true)

### No caret, line break
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{
        .show_line_no = true,
        .write_caret = false,
        .break_line_count = 1,
    },
};
pub fn main() void {
    causeOutOfBounds();
}
```
Output:
![alt text](images/case4.png?raw=true)

### No caret, some additional context
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{
        .show_line_no = true,
        .write_caret = false,
        .context_line_count = 1,
    },
};

pub fn main() void {
    causeSentinelMismatch();
}
```
Output:
![alt text](images/case5.png?raw=true)

### Using token preset
```zig
pub const trace: zl.builtin.Trace = .{
    .options = .{
        .show_line_no = true,
        .context_line_count = 1,
        .break_line_count = 1,
        .write_caret = false,
        .tokens = zl.builtin.my_trace.options.tokens,
    },
};
pub fn main() void {
    causeStackOverflow();
}
```
Output:
![alt text](images/case6.png?raw=true)

### Configuring tokens individually
```zig
pub const trace: zl.builtin.Trace = .{
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
pub fn main() void {
    causeAssertionFailed();
}
```
Output:
![alt text](images/case7.png?raw=true)

### Code referenced by the examples above
```zig
const zl = @import("./zig_lib/zig_lib.zig");
pub usingnamespace zl.proc.start;
fn accessInactiveUnionField() void {
    var u: union(enum) {
        a: u64,
        b: u32,
    } = .{ .a = 25 };
    u.a = u.b;
}
fn startGreaterThanEnd() void {
    var a: [4096]u8 = undefined;
    const b: [:0]u8 = a[@intFromPtr(&a)..512 :0];
    b[256] = 'b';
}
fn reachUnreachableCode() void {
    unreachable;
}
fn causeOutOfBounds() void {
    var idx: usize = 512;
    var a: [512]u8 = undefined;
    a[idx] = 'a';
}
fn causeSentinelMismatch() void {
    var a: [4096]u8 = undefined;
    const b: [:0]u8 = a[0..512 :0];
    b[256] = 'b';
}
fn causeStackOverflow() void {
    var a: [4096]u8 = undefined;
    a[0] = 'a';
    causeStackOverflow();
    unreachable;
}
fn causeAssertionFailed() void {
    var x: u64 = 0x10000;
    var y: u64 = 0x10010;
    zl.builtin.assertEqual(u64, x, y);
}
```
```zig
pub const Trace = struct {
    /// Show trace on alarm.
    Error: bool = false,
    /// Show trace on panic.
    Fault: bool = true,
    /// Show trace on signal.
    Signal: bool = true,
    options: Options = .{},
    pub const Options = struct {
        /// Unwind this many frames. max_depth = 0 is unlimited.
        max_depth: u8 = 0,
        /// Write this many lines of source code context.
        context_line_count: u8 = 0,
        /// Allow this many blank lines between source code contexts.
        break_line_count: u8 = 0,
        /// Show the source line number on source lines.
        show_line_no: bool = true,
        /// Show the program counter on the caret line.
        show_pc_addr: bool = false,
        /// Control sidebar inclusion and appearance.
        write_sidebar: bool = true,
        /// Write extra line to indicate column.
        write_caret: bool = true,
        /// Define composition of stack trace text.
        tokens: Tokens = .{},
        pub const Tokens = struct {
            /// Apply this style to the line number text.
            line_no: ?[]const u8 = null,
            /// Apply this style to the program counter address text.
            pc_addr: ?[]const u8 = null,
            /// Separate context information from sidebar with this text.
            sidebar: []const u8 = "|",
            /// Substitute absent `line_no` or `pc_addr` address with this text.
            sidebar_fill: []const u8 = " ",
            /// Indicate column number with this text.
            caret: []const u8 = tab.fx.color.fg.light_green ++ "^" ++ tab.fx.none,
            /// Fill text between `sidebar` and `caret` with this character.
            caret_fill: []const u8 = " ",
            /// Apply style for non-token text (comments)
            comment: ?[]const u8 = null,
            /// Apply `style` to every Zig token tag in `tags`.
            syntax: ?[]const Mapping = null,
            pub const Mapping = struct {
                style: []const u8 = "",
                tags: []const zig.Token.Tag = zig.Token.Tag.list,
            };
        };
    };
};
```
