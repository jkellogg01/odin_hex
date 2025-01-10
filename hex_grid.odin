package main

import "core:math"

import rl "vendor:raylib"

// no need to support point-topped hexes bc i don't want to use them
Hex_Grid :: struct {
	origin: [2]f32,
	hex_width: f32,
	hex_height: f32,
}

hex_grid_projection :: proc(origin: [2]f32, hex_width, angle: f32) -> Hex_Grid {
	angle_rad := math.to_radians(angle)
	hex_height := (math.sqrt_f32(3)/2) * hex_width * math.cos(angle_rad)
	return {
		origin,
		hex_width,
		hex_height,
	}
}

hg_world_to_coord :: proc(grid: Hex_Grid, point: [2]f32) -> [2]int {
	point_dist := point - grid.origin
	x_tile_dist := int(math.round(point_dist.x / (0.75 * grid.hex_width)))
	if x_tile_dist % 2 != 0 {
		point_dist.y -= 0.5 * grid.hex_height
	}
	y_tile_dist := int(math.round(point_dist.y / grid.hex_height))
	return {
		x_tile_dist,
		y_tile_dist,
	}
}

hg_tile_rect :: proc(grid: Hex_Grid, rect: rl.Rectangle, color: rl.Color) {
	tl_coord := hg_world_to_coord(grid, {rect.x, rect.y})
	br_coord := hg_world_to_coord(grid, {rect.x + rect.width, rect.y + rect.height})

	for col in tl_coord.x..=br_coord.x {
		for row in tl_coord.y..=br_coord.y {
			hg_draw_hex_lines(grid, {col, row}, color)
		}
	}
}

hg_draw_hex :: proc(grid: Hex_Grid, coords: [2]int, color: rl.Color) {
	hex_center := [2]f32{
		f32(coords.x) * 0.75 * grid.hex_width,
		f32(coords.y) * grid.hex_height,
	}

	if coords.x % 2 != 0 {
		hex_center.y += 0.5 * grid.hex_height
	}

	draw_hex(hex_center, grid.hex_width, grid.hex_height, color)
}

hg_draw_hex_lines :: proc(grid: Hex_Grid, coords: [2]int, color: rl.Color) {
	hex_center := [2]f32{
		f32(coords.x) * 0.75 * grid.hex_width,
		f32(coords.y) * grid.hex_height,
	}

	if coords.x % 2 != 0 {
		hex_center.y += 0.5 * grid.hex_height
	}

	draw_hex_lines(hex_center, grid.hex_width, grid.hex_height, color)
}

draw_hex :: proc(center: [2]f32, width, height: f32, color: rl.Color) {
	vertex_offsets := [?][2]f32{
		{0, 0},
		{0.5 * width, 0},
		{0.25 * width, -0.5 * height},
		{-0.25 * width, -0.5 * height},
		{-0.5 * width, 0},
		{-0.25 * width, 0.5 * height},
		{0.25 * width, 0.5 * height},
	}

	tris := [?]int{
		0, 1, 2,
		0, 2, 3,
		0, 3, 4,
		0, 4, 5,
		0, 5, 6,
		0, 6, 1,
	}

	for i := 0; i < len(tris); i += 3 {
		v1 := center + vertex_offsets[tris[i]]
		v2 := center + vertex_offsets[tris[i + 1]]
		v3 := center + vertex_offsets[tris[i + 2]]
		rl.DrawTriangle(v1, v2, v3, color)
	}
}

draw_hex_lines :: proc(center: [2]f32, width, height: f32, color: rl.Color) {
	vertex_offsets := [?][2]f32{
		{0.5 * width, 0},
		{0.25 * width, -0.5 * height},
		{-0.25 * width, -0.5 * height},
		{-0.5 * width, 0},
		{-0.25 * width, 0.5 * height},
		{0.25 * width, 0.5 * height},
	}

	for _, i in vertex_offsets {
		j := (i + 1) % len(vertex_offsets)
		v1 := center + vertex_offsets[i]
		v2 := center + vertex_offsets[j]
		rl.DrawLineV(v1, v2, color)
	}
}