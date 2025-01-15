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

Game_State :: struct {
	grid: Hex_Grid,
	start: [2]int,
	goal: [2]int,
	user_holding: Holding,
	camera: rl.Camera2D, // need this for screen to world coordinates, even if it's not changing the viewport at all
}

init :: proc(g: ^Game_State) {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1920, 1080, "hex grid pathfinding")

	rl.SetTargetFPS(60)

	g.grid = hex_grid_projection(32, 45)
	g.grid.obstacles = make([dynamic][2]int, 0)

	g.start = [2]int{-8, 0}
	g.goal = [2]int{8, 0}

	g.camera = {
		offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
		target = {0, 0},
		rotation = 0,
		zoom = 1,
	}
}

update :: proc(g: ^Game_State) {
	g.camera.offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2}

	screen_mouse := rl.GetMousePosition()
	world_mouse := rl.GetScreenToWorld2D(screen_mouse, g.camera)
	mouse_grid_coord := hg_world_to_hex(g.grid, world_mouse)

	grid_rect := rl.Rectangle {
		(g.camera.target - g.camera.offset).x,
		(g.camera.target - g.camera.offset).y,
		f32(rl.GetScreenWidth()) / g.camera.zoom,
		f32(rl.GetScreenHeight()) / g.camera.zoom,
	}

	if g.user_holding == .None && rl.IsMouseButtonPressed(.LEFT) {
		switch mouse_grid_coord {
			case g.start:
			g.user_holding = .Start
			case g.goal:
			g.user_holding = .Goal
			case:
			hg_create_obstacle(&g.grid, mouse_grid_coord)
		}
	} else if g.user_holding == .None && rl.IsMouseButtonDown(.LEFT) {
		hg_create_obstacle(&g.grid, mouse_grid_coord)
	} else if g.user_holding == .None && rl.IsMouseButtonDown(.RIGHT) {
		hg_remove_obstacle(&g.grid, mouse_grid_coord)
	}

	#partial switch g.user_holding {
		case .Start:
			g.start = mouse_grid_coord
		case .Goal:
			g.goal = mouse_grid_coord
	}

	if g.user_holding != .None && rl.IsMouseButtonReleased(.LEFT) {
		g.user_holding = .None
	}

	path, path_found := find_path(g.start, g.goal, g.grid.obstacles[:])

	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)
	rl.BeginMode2D(g.camera)
	hg_draw_obstacles(g.grid)
	hg_draw_hex(g.grid, g.start, rl.BLUE)
	hg_draw_hex(g.grid, g.goal, rl.RED)
	if g.user_holding == .None {
		hg_draw_hex(g.grid, mouse_grid_coord, {255, 255, 0, 100})
	}
	if path_found {
		for path_space in path {
			hg_draw_hex(g.grid, path_space, {255, 0, 255, 100})
		}
	}
	hg_tile_grid_over_rect(g.grid, grid_rect)
	rl.EndMode2D()
	rl.DrawFPS(5, 5)
	rl.EndDrawing()
	free_all(context.temp_allocator)
}

shutdown :: proc(g: ^Game_State) {
	rl.CloseWindow()
	delete(g.grid.obstacles)
}

main :: proc() {
	g: Game_State
	init(&g)

	for !rl.WindowShouldClose() {
		update(&g)
	}

	shutdown(&g)
}