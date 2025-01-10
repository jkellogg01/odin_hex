package main

import "core:math"
import "core:fmt"

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(1920, 1080, "hexagons are the bestagons")
	rl.SetWindowState({ .WINDOW_RESIZABLE })

	rl.SetTargetFPS(144)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.BLACK)


		tile_hex_grid_projection(0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight()), 100, 45, rl.RAYWHITE)

		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}

tile_hex_grid_projection :: proc(origin: [2]f32, width, height, hex_width, angle: f32, color: rl.Color) {
	angle_rad := math.to_radians(angle)
	hex_height := (math.sqrt_f32(3)/2) * hex_width * math.cos(angle_rad)

	x_dist := 0.75 * hex_width
	y_dist := hex_height

	cols := int(math.ceil(width / x_dist)) + 1
	rows := int(math.ceil(height / y_dist)) + 1

	draw_hex_grid_projection(origin, cols, rows, hex_width, angle, color)
}

draw_hex_grid_projection :: proc(origin: [2]f32, cols, rows: int, hex_width, angle: f32, color: rl.Color) {
	angle_rad := math.to_radians(angle)
	hex_height := (math.sqrt_f32(3)/2) * hex_width * math.cos(angle_rad)

	// not really sure I understand why this coefficient makes this work
	x_dist := 0.75 * hex_width
	y_dist := hex_height

	for i := 0; i < rows * cols; i += 1 {
		col := i % cols
		row := i / cols
		y_offset := col % 2 != 0 ? 0.5 * y_dist : 0
		hex_center := origin + [2]f32{
			f32(col) * x_dist,
			f32(row) * y_dist + y_offset,
		}
		// fmt.printfln("hex (%d,%d) at (%4f,%4f)", col, row, hex_center.x, hex_center.y)

		draw_hex_wh(hex_center, hex_width - 1, hex_height - 1, color)
	}
}

draw_hex_projection :: proc(center: [2]f32, width, angle: f32, color: rl.Color) {
	angle_rad := math.to_radians(angle)
	height := (math.sqrt_f32(3)/2) * width * math.cos(angle_rad)
	draw_hex_wh(center, width, height, color)
}

draw_hex_wh :: proc(center: [2]f32, width, height: f32, color: rl.Color) {
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