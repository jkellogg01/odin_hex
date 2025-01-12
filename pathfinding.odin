package main

import "core:container/queue"
import "core:slice"
import "core:fmt"

find_path :: proc(start, target: [2]int, obstacles: [][2]int) -> ([][2]int, bool) {
	frontier: queue.Queue([2]int)
	err := queue.init(&frontier)
	assert(err == nil) // TODO: something other than this
	defer queue.destroy(&frontier)
	queue.push_back(&frontier, start)

	came_from := make(map[[2]int]Maybe([2]int))
	came_from[start] = nil

	for queue.len(frontier) > 0 {
		current := queue.pop_front(&frontier)
		in_obstacles: bool
		for obstacle in obstacles {
			if obstacle != current do continue
			came_from[current] = nil
			in_obstacles = true
			break
		}
		if in_obstacles do continue
		if current == target {
			// fmt.println("found target!")
			break
		}
		for neighbor in axial_neighbors(current) {
			if neighbor in came_from do continue
			queue.push_back(&frontier, neighbor)
			came_from[neighbor] = current
		}
	}

	path := make([dynamic][2]int)
	current, ok := came_from[target].?
	if !ok do return nil, false
	for current != start {
		append(&path, current)
		current, ok = came_from[current].?
		if !ok do return nil, false
	}
	result := path[:]
	slice.reverse(result)
	return result, true
}