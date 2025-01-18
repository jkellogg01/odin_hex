package main

import "core:fmt"
import "core:math"

import rl "vendor:raylib"

Holding :: enum {
	None,
	Start,
	Goal,
}

Placing_Tile :: struct {
	name: string,
	tile: Tile,
}

State :: struct {
	grid: Hex_Grid,
	tiles: Hex_Map,
	start: [2]int,
	goal: [2]int,
	user_holding: Holding,
	user_placing_idx: int,
	camera: rl.Camera2D, // need this for screen to world coordinates, even if it's not changing the viewport at all
}

placeable_tiles := [?]Placing_Tile {
	{ "floor", Floor_Tile {5} },
	{ "wall", Wall_Tile {} },
}

main :: proc() {
	s: State
	init(&s)

	for !rl.WindowShouldClose() {
		update(&s)
	}

	shutdown(&s)
}

init :: proc(s: ^State) {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "hex grid pathfinding")

	rl.SetTargetFPS(60)

	s.grid = hex_grid_projection(32, 45)
	s.tiles.min_cost = 5
	s.tiles.max_cost = 8

	s.start = [2]int{-8, 0}
	s.goal = [2]int{8, 0}

	s.camera = {
		offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2},
		target = {0, 0},
		rotation = 0,
		zoom = 1,
	}
}

update :: proc(s: ^State) {
	s.camera.offset = {f32(rl.GetScreenWidth())/2, f32(rl.GetScreenHeight())/2}

	if rl.IsMouseButtonDown(.MIDDLE) {
		s.camera.target -= rl.GetMouseDelta()
	}

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
			map_set_tile(&s.tiles, mouse_grid_coord, placeable_tiles[s.user_placing_idx].tile)
		}
	} else if s.user_holding == .None && rl.IsMouseButtonDown(.LEFT) {
		map_set_tile(&s.tiles, mouse_grid_coord, placeable_tiles[s.user_placing_idx].tile)
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

	scroll := rl.GetMouseWheelMove()
	if scroll > 0 {
		s.user_placing_idx += 1
	} else if scroll < 0 {
		s.user_placing_idx -= 1
		if s.user_placing_idx < 0 {
			s.user_placing_idx = len(placeable_tiles) - 1
		}
	}
	s.user_placing_idx %= len(placeable_tiles)

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
			hg_draw_hex(s.grid, path_space, rl.DARKGREEN)
		}
	}
	hg_draw_map_lines(s.grid, s.tiles)
	placing_tooltip := fmt.ctprintf("Currently Placing: %s", placeable_tiles[s.user_placing_idx].name)
	tooltip_pos := [2]i32{ i32(math.round(world_mouse.x) + 5), i32(math.round(world_mouse.y) + 5)}
	rl.DrawRectangle(tooltip_pos.x, tooltip_pos.y, rl.MeasureText(placing_tooltip, 20) + 10, 30, rl.BLACK)
	rl.DrawText(placing_tooltip, tooltip_pos.x + 5, tooltip_pos.y + 5, 20, rl.WHITE)
	rl.EndMode2D()
	if path_found {
		path_length_cstr := fmt.ctprintf("Path Length: %d Tiles", len(path))
		found_in_cstr := fmt.ctprintf("Found In: %4fms", pf_duration * 1000)
		rec_width := max(rl.MeasureText(path_length_cstr, 20), rl.MeasureText(found_in_cstr, 20)) + 10
		rl.DrawRectangle(0, 0, rec_width, 70, rl.BLACK)
		rl.DrawText(path_length_cstr, 5, 25, 20, rl.WHITE)
		rl.DrawText(found_in_cstr, 5, 45, 20, rl.WHITE)
	} else {
		rl.DrawRectangle(0, 0, 85, 30, rl.BLACK)
	}
	rl.DrawFPS(5, 5)
	rl.EndDrawing()
	free_all(context.temp_allocator)
}

shutdown :: proc(s: ^State) {
	rl.CloseWindow()
	delete(s.tiles.tiles)
}