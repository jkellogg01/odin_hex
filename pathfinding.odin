package main

import "core:slice"
import "core:fmt"
import pq "core:container/priority_queue"

Path_Step :: struct {
	coord: [2]int,
	g_cost: int,
	h_cost: int,
}

find_path :: proc(start, target: [2]int, obstacles: [][2]int) -> ([][2]int, bool) {
	frontier: pq.Priority_Queue(Path_Step)
	pq.init(&frontier, frontier_less, pq.default_swap_proc(Path_Step))
	defer pq.destroy(&frontier)
	pq.push(&frontier, Path_Step{start, 0, axial_distance(start, target)})

	came_from := make(map[[2]int]Maybe(Path_Step))
	came_from[start] = nil

	for pq.len(frontier) > 0 {
		current := pq.pop(&frontier)
		in_obstacles: bool
		for obstacle in obstacles {
			if obstacle != current.coord do continue
			came_from[current.coord] = nil
			in_obstacles = true
			break
		}
		if in_obstacles do continue
		if current.coord == target {
			// fmt.println("found target!")
			break
		}
		for neighbor in axial_neighbors(current.coord) {
			ncf, ok := came_from[neighbor].?
			new_cost := current.g_cost + 1
			if ok && new_cost >= current.g_cost do continue
			pq.push(&frontier, Path_Step{ neighbor, new_cost, axial_distance(neighbor, target) })
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