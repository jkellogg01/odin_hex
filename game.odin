package main

import "core:fmt"

import rl "vendor:raylib"

Holding :: enum {
	None,
	Start,
	Goal,
}

State :: struct {
	grid: Hex_Grid,
	tiles: Hex_Map,
	start: [2]int,
	goal: [2]int,
	user_holding: Holding,
	camera: rl.Camera2D, // need this for screen to world coordinates, even if it's not changing the viewport at all
}

main :: proc() {
	s: State
	init(&s)

	for !rl.WindowShouldClose() {
		update(&s)
	}

	shutdown(&s)
}

init :: proc(d: ^State) {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "hex grid pathfinding")

	rl.SetTargetFPS(60)

	d.grid = hex_grid_projection(32, 45)

	d.start = [2]int{-8, 0}
	d.goal = [2]int{8, 0}

	d.camera = {
		offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
		target = {0, 0},
		rotation = 0,
		zoom = 1,
	}
}

update :: proc(s: ^State) {
	s.camera.offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2}

	screen_mouse := rl.GetMousePosition()
	world_mouse := rl.GetScreenToWorld2D(screen_mouse, s.camera)
	mouse_grid_coord := hg_world_to_hex(s.grid, world_mouse)

	grid_rect := rl.Rectangle {
		(s.camera.target - s.camera.offset).x,
		(s.camera.target - s.camera.offset).y,
		f32(rl.GetScreenWidth()) / s.camera.zoom,
		f32(rl.GetScreenHeight()) / s.camera.zoom,
	}

	if s.user_holding == .None && rl.IsMouseButtonPressed(.LEFT) {
		switch mouse_grid_coord {
			case s.start:
			s.user_holding = .Start
			case s.goal:
			s.user_holding = .Goal
			case:
			map_set_tile(&s.tiles, mouse_grid_coord, Floor_Tile{5})
		}
	} else if s.user_holding == .None && rl.IsMouseButtonDown(.LEFT) {
		map_set_tile(&s.tiles, mouse_grid_coord, Floor_Tile{5})
	} else if s.user_holding == .None && rl.IsMouseButtonDown(.RIGHT) {
		map_remove_tile(&s.tiles, mouse_grid_coord)
	}

	#partial switch s.user_holding {
		case .Start:
			s.start = mouse_grid_coord
		case .Goal:
			s.goal = mouse_grid_coord
	}

	if s.user_holding != .None && rl.IsMouseButtonReleased(.LEFT) {
		s.user_holding = .None
	}

	pf_time := rl.GetTime()
	path, path_found := find_path(s.start, s.goal, s.tiles)
	pf_duration := rl.GetTime() - pf_time

	rl.BeginDrawing()
	rl.ClearBackground(rl.RAYWHITE)
	rl.BeginMode2D(s.camera)
	hg_draw_map(s.grid, s.tiles, rl.PURPLE)
	hg_draw_hex(s.grid, s.start, rl.BLUE)
	hg_draw_hex(s.grid, s.goal, rl.RED)
	if s.user_holding == .None {
		hg_draw_hex(s.grid, mouse_grid_coord, {255, 255, 0, 100})
	}
	if path_found {
		for path_space in path {
			hg_draw_hex(s.grid, path_space, {255, 0, 255, 100})
		}
	}
	hg_draw_map_lines(s.grid, s.tiles)
	rl.EndMode2D()
	rl.DrawRectangle(0, 0, path_found ? 225 : 100, path_found ? 75 : 25, rl.BLACK)
	rl.DrawFPS(5, 5)
	if path_found {
		rl.DrawText(fmt.ctprintf("Path Length: %d Tiles\nFound In: %4fms", len(path), pf_duration * 1000), 5, 25, 20, rl.WHITE)
	}
	rl.EndDrawing()
	free_all(context.temp_allocator)
}

shutdown :: proc(s: ^State) {
	rl.CloseWindow()
	delete(s.tiles.tiles)
}