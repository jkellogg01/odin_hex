package main

import "core:slice"
import pq "core:container/priority_queue"

import rl "vendor:raylib"

Path_Step :: struct {
	using coord: [2]int,
	g_cost: int,
	h_cost: int,
}

find_path :: proc(start, target: [2]int, m: Hex_Map) -> ([][2]int, bool) {
	start_time := rl.GetTime()
	frontier: pq.Priority_Queue(Path_Step)
	pq.init(&frontier, frontier_less, pq.default_swap_proc(Path_Step))
	defer pq.destroy(&frontier)
	pq.push(&frontier, Path_Step{start, 0, map_heuristic(m, start, target)})

	came_from := make(map[[2]int]Maybe(Path_Step))
	came_from[start] = nil

	for pq.len(frontier) > 0 {
		if (rl.GetTime() - start_time) > 0.002 do return nil, false
		current := pq.pop(&frontier)
		if current.coord == target {
			// fmt.println("found target!")
			break
		}
		cost, traversible := map_cost(m, current)
		if !traversible do continue
		for neighbor in axial_neighbors(current.coord) {
			ok := came_from[neighbor] != nil
			new_cost := current.g_cost + cost
			if ok && new_cost >= current.g_cost do continue
			pq.push(&frontier, Path_Step{ neighbor, new_cost, map_heuristic(m, neighbor, target) })
			came_from[neighbor] = current
		}
	}

	path := make([dynamic][2]int)
	current, ok := came_from[target].?
	if !ok do return nil, false
	for current.coord != start {
		append(&path, current.coord)
		current, ok = came_from[current.coord].?
		if !ok do return nil, false
	}
	result := path[:]
	slice.reverse(result)
	return result, true
}

frontier_less :: proc(a, b: Path_Step) -> bool {
	a_f_cost := a.h_cost + a.g_cost
	b_f_cost := b.h_cost + b.g_cost
	if a_f_cost == b_f_cost {
		return a.g_cost < b.g_cost
	} else {
		return a_f_cost < b_f_cost
	}
}