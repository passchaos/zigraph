//! # 10 - Rank Constraints
//!
//! Demonstrates rank hints and rank direction in Sugiyama layout:
//! nodes can be biased to boundaries, kept on the same rank, and laid out left-to-right.
//!
//! Run: `zig build run-svg_10_rank_constraints`

const std = @import("std");
const zigraph = @import("zigraph");

fn writeSvg(io: std.Io, name: []const u8, svg: []const u8) !void {
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "assets/gallery/{s}.svg", .{name}) catch return;
    var file = try std.Io.Dir.cwd().createFile(io, path, .{});
    defer file.close(io);
    var wbuf: [4096]u8 = undefined;
    var fw = std.Io.File.writer(file, io, &wbuf);
    try fw.interface.writeAll(svg);
    std.debug.print("  wrote {s} ({d} bytes)\n", .{ path, svg.len });
}

fn nodeStyle(ctx: zigraph.NodeStyleContext) zigraph.NodeStyle {
    var style = zigraph.shapes.rounded_rectangle(ctx);

    switch (ctx.node_id) {
        // rank=min/source examples
        1, 9 => {
            style.fill = "#dcfce7";
            style.stroke = "#16a34a";
        },
        // rank=same examples
        5, 6, 7, 11 => {
            style.fill = "#fef3c7";
            style.stroke = "#d97706";
        },
        // rank=sink example
        10 => {
            style.fill = "#fee2e2";
            style.stroke = "#dc2626";
        },
        else => {
            style.fill = "#f8fafc";
            style.stroke = "#64748b";
        },
    }

    return style;
}

fn edgeStyle(ctx: zigraph.EdgeStyleContext) zigraph.EdgeStyle {
    return .{
        .stroke = zigraph.color.get(&zigraph.color.radix, ctx.edge_index),
        .marker_end = if (ctx.directed) .arrow else .none,
    };
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    std.debug.print("\n-- 10: Rank Constraints --\n\n", .{});

    var g = zigraph.Graph.init(allocator);
    defer g.deinit();

    try g.addNode(1, "Request");
    try g.addNode(2, "Auth");
    try g.addNode(3, "Catalog");
    try g.addNode(4, "Price");
    try g.addNode(5, "Inventory");
    try g.addNode(6, "Quote");
    try g.addNode(7, "Audit");
    try g.addNode(8, "Response");
    try g.addNode(9, "Metrics");
    try g.addNode(10, "Archive");
    try g.addNode(11, "Risk");

    try g.addEdge(1, 2);
    try g.addEdge(1, 3);
    try g.addEdge(2, 4);
    try g.addEdge(3, 4);
    try g.addEdge(3, 5);
    try g.addEdge(4, 6);
    try g.addEdge(5, 6);
    try g.addEdge(6, 8);
    try g.addEdge(2, 7);
    try g.addEdge(8, 10);
    try g.addEdge(11, 6);

    const ranks = [_]zigraph.RankConstraint{
        .{ .kind = .min, .node_ids = &.{ 1, 9 } },
        .{ .kind = .same, .node_ids = &.{ 6, 7 } },
        .{ .kind = .same, .node_ids = &.{ 5, 11 } },
        .{ .kind = .sink, .node_ids = &.{10} },
    };

    // The LR image should read like the TB image with the rank axis rotated.
    const layout_config = zigraph.LayoutConfig{
        .layering = .network_simplex_fast,
        .positioning = .brandes_kopf,
        .routing = .direct,
        .rank_constraints = &ranks,
    };

    var ir_tb = try zigraph.layout(&g, allocator, layout_config);
    defer ir_tb.deinit();

    var ir_lr = try zigraph.layout(&g, allocator, .{
        .layering = layout_config.layering,
        .positioning = layout_config.positioning,
        .routing = layout_config.routing,
        .rank_constraints = layout_config.rank_constraints,
        .level_spacing = layout_config.level_spacing,
        .rankdir = .lr,
    });
    defer ir_lr.deinit();

    var ir_bt = try zigraph.layout(&g, allocator, .{
        .layering = layout_config.layering,
        .positioning = layout_config.positioning,
        .routing = layout_config.routing,
        .rank_constraints = layout_config.rank_constraints,
        .level_spacing = layout_config.level_spacing,
        .rankdir = .bt,
    });
    defer ir_bt.deinit();

    var ir_rl = try zigraph.layout(&g, allocator, .{
        .layering = layout_config.layering,
        .positioning = layout_config.positioning,
        .routing = layout_config.routing,
        .rank_constraints = layout_config.rank_constraints,
        .level_spacing = layout_config.level_spacing,
        .rankdir = .rl,
    });
    defer ir_rl.deinit();

    const svg_tb = try zigraph.svg.render(&ir_tb, allocator, .{
        .node_style_fn = &nodeStyle,
        .edge_style_fn = &edgeStyle,
    });
    defer allocator.free(svg_tb);
    try writeSvg(io, "10_rank_constraints_tb", svg_tb);

    const svg_lr = try zigraph.svg.render(&ir_lr, allocator, .{
        .node_style_fn = &nodeStyle,
        .edge_style_fn = &edgeStyle,
    });
    defer allocator.free(svg_lr);
    try writeSvg(io, "10_rank_constraints", svg_lr);

    const svg_bt = try zigraph.svg.render(&ir_bt, allocator, .{
        .node_style_fn = &nodeStyle,
        .edge_style_fn = &edgeStyle,
    });
    defer allocator.free(svg_bt);
    try writeSvg(io, "10_rank_constraints_bt", svg_bt);

    const svg_rl = try zigraph.svg.render(&ir_rl, allocator, .{
        .node_style_fn = &nodeStyle,
        .edge_style_fn = &edgeStyle,
    });
    defer allocator.free(svg_rl);
    try writeSvg(io, "10_rank_constraints_rl", svg_rl);
}
