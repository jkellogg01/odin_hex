package main

Hex_Map :: struct {
	tiles: map[[2]int]Tile,
	min_cost: int,
	max_cost: int,
}

Tile :: union {
	Floor_Tile,
	Wall_Tile,
}

Floor_Tile :: struct {
	cost: int,
}

Wall_Tile :: struct {}

map_heuristic :: proc(m: Hex_Map, a, b: [2]int) -> int {
	dist := axial_distance(a, b)
	return dist * m.min_cost
}

map_cost :: proc(m: Hex_Map, coord: [2]int) -> (int, bool) {
	if !(coord in m.tiles) do return -1, false
	floor_tile, ok := m.tiles[coord].(Floor_Tile)
	if !ok do return -1, false
	return floor_tile.cost, true
}

map_set_tile :: proc(m: ^Hex_Map, coord: [2]int, tile: Tile) {
	tile := tile
	if floor_tile, ok := tile.(Floor_Tile); ok{
		if floor_tile.cost < m.min_cost {
			floor_tile.cost = m.min_cost
		} else if floor_tile.cost > m.max_cost {
			floor_tile.cost = m.max_cost
		}
	}
	m.tiles[coord] = tile
}

map_remove_tile :: proc(m: ^Hex_Map, coord: [2]int) {
	delete_key(&m.tiles, coord)
}