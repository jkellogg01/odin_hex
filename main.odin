package main

import "core:math"
import "core:fmt"
import "core:slice"

import rl "vendor:raylib"

Holding :: enum {
	None,
	Start,
	Goal,
}

main :: proc() {
	rl.InitWindow(1920, 1080, "hexagons are the bestagons")
	rl.SetWindowState({ .WINDOW_RESIZABLE })

	rl.SetTargetFPS(60)

	grid := hex_grid_projection(64, 45)
	grid.obstacles = make([dynamic][2]int, 0)
	defer delete(grid.obstacles)

	start := [2]int{-8, 0}
	goal := [2]int{8, 0}

	user_holding: Holding

	for !rl.WindowShouldClose() {
		camera := rl.Camera2D {
			offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
			target = {0, 0},
			rotation = 0,
			zoom = 1,
		}
		screen_mouse := rl.GetMousePosition()
		world_mouse := rl.GetScreenToWorld2D(screen_mouse, camera)
		mouse_grid_coord := hg_world_to_hex(grid, world_mouse)
		mouse_grid_to_world := hg_hex_to_world(grid, mouse_grid_coord)
		// mouse_coord_string := fmt.caprintf("(%d,%d)", mouse_grid_coord.x, mouse_grid_coord.y)
		// defer delete(mouse_coord_string)

		grid_rect := rl.Rectangle {
			(camera.target - camera.offset).x,
			(camera.target - camera.offset).y,
			f32(rl.GetScreenWidth()) / camera.zoom,
			f32(rl.GetScreenHeight()) / camera.zoom,
		}

		if user_holding == .None && rl.IsMouseButtonPressed(.LEFT) {
			switch mouse_grid_coord {
			case start:
				user_holding = .Start
			case goal:
				user_holding = .Goal
			case:
				if hg_obstacle_index(grid, mouse_grid_coord) == -1 {
					fmt.eprintfln("place obstacle: %d,%d", mouse_grid_coord.x, mouse_grid_coord.y)
					append(&grid.obstacles, mouse_grid_coord)
				}
			}
		} else if user_holding == .None && rl.IsMouseButtonDown(.LEFT) {
			if hg_obstacle_index(grid, mouse_grid_coord) == -1 {
				fmt.eprintfln("place obstacle: %d,%d", mouse_grid_coord.x, mouse_grid_coord.y)
				append(&grid.obstacles, mouse_grid_coord)
			}
		} else if user_holding == .None && rl.IsMouseButtonDown(.RIGHT) {
			idx := hg_obstacle_index(grid, mouse_grid_coord)
			if idx != -1 {
				fmt.eprintfln("remove obstacle: %d,%d", mouse_grid_coord.x, mouse_grid_coord.y)
				unordered_remove(&grid.obstacles, idx)
			}
		} else if user_holding == .Start {
			start = mouse_grid_coord
		} else if user_holding == .Goal {
			goal = mouse_grid_coord
		}

		if user_holding != .None && rl.IsMouseButtonReleased(.LEFT) {
			user_holding = .None
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RAYWHITE)
		rl.BeginMode2D(camera)
		hg_draw_obstacles(grid)
		hg_draw_hex(grid, start, rl.BLUE)
		hg_draw_hex(grid, goal, rl.RED)
		if user_holding == .None {
			hg_draw_hex(grid, mouse_grid_coord, {255, 255, 0, 100})
		}
		hg_tile_grid_over_rect(grid, grid_rect)
		// rl.DrawText(mouse_coord_string, i32(math.round(world_mouse.x + 5)), i32(math.round(world_mouse.y + 5)), 24, rl.BLACK)

		rl.EndMode2D()
		rl.DrawFPS(5, 5)
		rl.EndDrawing()
	}

	rl.CloseWindow()
}