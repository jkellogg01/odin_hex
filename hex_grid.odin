package main

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:slice"

import rl "vendor:raylib"

axial_directions :: [6][2]int{
	{1, -1},
	{0, -1},
	{-1, 0},
	{-1, 1},
	{0, 1},
	{1, 0},
}

Hex_Grid :: struct {
	hex_width: f32,
	hex_height: f32,
	obstacles: [dynamic][2]int,
}

hex_grid_projection :: proc(radius, angle: f32) -> Hex_Grid {
	hex_width := 2 * radius
	angle_rad := math.to_radians(angle)
	hex_height := math.sqrt_f32(3) * radius * math.cos(angle_rad)
	return {
		hex_width,
		hex_height,
		nil,
	}
}

axial_neighbors :: proc(coord: [2]int) -> [6][2]int {
	result: [6][2]int
	for dir, i in axial_directions {
		result[i] = coord + dir
	}
	return result
}

axial_distance :: proc(a, b: [2]int) -> int {
	vec := a - b
	return (abs(vec.x) + abs(vec.x + vec.y) + abs(vec.y)) / 2
}

axial_round :: proc(frac: [2]f32) -> [2]int {
	q_grid := math.round(frac[0])
	r_grid := math.round(frac[1])
	q := frac[0] - f32(q_grid)
	r := frac[1] - f32(r_grid)
	if abs(q) >= abs(r) {
		q_grid += math.round(q + 0.5 * r)
	} else {
		r_grid += math.round(r + 0.5 * q)
	}
	return {int(q_grid), int(r_grid)}
}

axial_lerp :: proc(a, b: [2]int, t: f32) -> [2]f32 {
	return {
		linalg.lerp(f32(a[0]), f32(b[0]), t),
		linalg.lerp(f32(a[1]), f32(b[1]), t),
	}
}

hg_hex_to_world :: proc(grid: Hex_Grid, coord: [2]int) -> [2]f32 {
	x := 0.75 * grid.hex_width * f32(coord.x)
	y := 0.5 * grid.hex_height * f32(coord.x) + grid.hex_height * f32(coord.y)
	return {x, y}
}

hg_world_to_hex :: proc(grid: Hex_Grid, coord: [2]f32) -> [2]int {
	q := 4 / (3 * grid.hex_width) * coord.x
	r := -2 / (3 * grid.hex_width) * coord.x + 1 / grid.hex_height * coord.y
	return axial_round({q, r})
}

hg_create_obstacle :: proc(grid: ^Hex_Grid, coord: [2]int) {
	idx := -1
	for obstacle, i in grid.obstacles {
		if obstacle != coord do continue
		idx = i
		break
	}
	if idx != -1 do return
	append(&grid.obstacles, coord)
}

hg_remove_obstacle :: proc(grid: ^Hex_Grid, coord: [2]int) {
	idx := -1
	for obstacle, i in grid.obstacles {
		if obstacle != coord do continue
		idx = i
		break
	}
	if idx == -1 do return
	unordered_remove(&grid.obstacles, idx)
}

hg_tile_grid_over_rect :: proc(grid: Hex_Grid, rect: rl.Rectangle) {
	hex_corner_tl := hg_world_to_hex(grid, {rect.x, rect.y})
	hex_corner_br := hg_world_to_hex(grid, {rect.x + rect.width, rect.y + rect.height})
	for q in hex_corner_tl.x..=hex_corner_br.x {
		for r in hex_corner_tl.y..=hex_corner_br.y {
			hg_draw_hex_lines(grid, {q, r}, rl.BLACK)
		}
	}

	hex_corner_tr := hg_world_to_hex(grid, {rect.x + rect.width, rect.y})
	for r := hex_corner_tr.y; r < hex_corner_tl.y; r += 1 {
		cols := 1 + (r - hex_corner_tr.y) * 2
		for q := hex_corner_tr.x; q > hex_corner_tr.x - cols; q -= 1 {
			hg_draw_hex_lines(grid, {q, r}, rl.BLACK)
		}
	}

	hex_corner_bl := hg_world_to_hex(grid, {rect.x, rect.y + rect.height})
	for r := hex_corner_bl.y; r > hex_corner_br.y; r -= 1 {
		cols := 1 + (hex_corner_bl.y - r) * 2
		for q := hex_corner_bl.x; q < hex_corner_bl.x + cols; q += 1 {
			hg_draw_hex_lines(grid, {q, r}, rl.BLACK)
		}
	}
}

hg_draw_obstacles :: proc(grid: Hex_Grid) {
	// we can probably afford to just draw every obstacle even if they aren't necessarily on screen
	for obstacle in grid.obstacles {
		hg_draw_hex(grid, obstacle, rl.DARKGRAY)
	}
}

hg_draw_hex :: proc(grid: Hex_Grid, coord: [2]int, color: rl.Color) {
	hex_center := hg_hex_to_world(grid, coord)
	draw_hex(hex_center, grid.hex_width, grid.hex_height, color)
}

hg_draw_hex_lines :: proc(grid: Hex_Grid, coord: [2]int, color: rl.Color) {
	hex_center := hg_hex_to_world(grid, coord)
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
		rl.DrawLineEx(v1, v2, 2, color)
	}
}