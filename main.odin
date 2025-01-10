package main

import "core:math"
import "core:fmt"

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(1920, 1080, "hexagons are the bestagons")
	rl.SetWindowState({ .WINDOW_RESIZABLE })

	rl.SetTargetFPS(144)

	grid := hex_grid_projection(0, 100, 60)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.RAYWHITE)

		camera := rl.Camera2D {
			offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
			target = {0, 0},
			rotation = 0,
			zoom = 1,
		}
		screen_mouse := rl.GetMousePosition()
		world_mouse := rl.GetScreenToWorld2D(screen_mouse, camera)
		mouse_grid_coord := hg_world_to_coord(grid, world_mouse)

		camera_rect := rl.Rectangle {
			(camera.target - camera.offset).x,
			(camera.target - camera.offset).y,
			f32(rl.GetScreenWidth()) / camera.zoom,
			f32(rl.GetScreenHeight()) / camera.zoom,
		}

		rl.BeginMode2D(camera)

		hg_tile_rect(grid, camera_rect, rl.BLUE)
		hg_draw_hex(grid, mouse_grid_coord, rl.RED)

		rl.EndMode2D()
		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}