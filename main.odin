package main

import "core:math"
import "core:fmt"

import rl "vendor:raylib"

main :: proc() {
	rl.InitWindow(1920, 1080, "hexagons are the bestagons")
	rl.SetWindowState({ .WINDOW_RESIZABLE })

	rl.SetTargetFPS(60)

	grid := hex_grid_projection(0, 64, 60)
	obstacles := make([dynamic][2]int, 0)
	defer delete(obstacles)
	grid.obstacles = obstacles[:]

	start := [2]int{-10, -10}
	goal := [2]int{10, 10}

	for !rl.WindowShouldClose() {
		camera := rl.Camera2D {
			offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
			target = {0, 0},
			rotation = 0,
			zoom = 1,
		}
		screen_mouse := rl.GetMousePosition()
		world_mouse := rl.GetScreenToWorld2D(screen_mouse, camera)
		mouse_grid_coord := hg_world_to_coord(grid, world_mouse)
		mouse_coord_string := fmt.caprintf("(%d,%d)", mouse_grid_coord.x, mouse_grid_coord.y)
		defer delete(mouse_coord_string)

		grid_rect := rl.Rectangle {
			(camera.target - camera.offset).x,
			(camera.target - camera.offset).y,
			f32(rl.GetScreenWidth()) / camera.zoom,
			f32(rl.GetScreenHeight()) / camera.zoom,
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.BeginMode2D(camera)
		hg_tile_rect(grid, grid_rect)
		hg_draw_hex(grid, start, rl.BLUE)
		hg_draw_hex(grid, goal, rl.RED)
		hg_draw_hex(grid, mouse_grid_coord, {255, 255, 0, 100})
		rl.DrawText(mouse_coord_string, i32(math.round(world_mouse.x + 5)), i32(math.round(world_mouse.y + 5)), 24, rl.BLACK)

		rl.EndMode2D()
		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}