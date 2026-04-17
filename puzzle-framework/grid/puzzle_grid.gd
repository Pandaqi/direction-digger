class_name PuzzleGrid

var grid : Array
var cells : Array[PuzzleCell]
var size : Vector2i

var creation_callback : Callable = func(pos:Vector2i): return PuzzleCell.new(pos)

enum NeighborMode
{
	NONE,
	HORIZONTAL,
	VERTICAL,
	DIAGONAL,
	ORTHOGONAL,
	ALL
}

enum Direction
{
	NONE,
	RIGHT,
	BOTTOM_RIGHT,
	DOWN,
	BOTTOM_LEFT,
	LEFT,
	TOP_LEFT,
	UP,
	TOP_RIGHT
}

var neighbor_mode := NeighborMode.ORTHOGONAL
var neighbor_directions : Dictionary[NeighborMode, Array] = {
	NeighborMode.NONE: [],
	NeighborMode.HORIZONTAL: [Vector2i.LEFT, Vector2i.RIGHT],
	NeighborMode.VERTICAL: [Vector2i.UP, Vector2i.DOWN],
	NeighborMode.DIAGONAL: [Vector2i(-1,-1), Vector2i(1,-1), Vector2i(1,1), Vector2i(-1,1)],
	NeighborMode.ORTHOGONAL: [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP],
	NeighborMode.ALL: [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1,-1), Vector2i(1,-1), Vector2i(1,1), Vector2i(-1,1)],
}

static var direction_to_vector : Dictionary[Direction, Vector2i] = {
	Direction.NONE: Vector2i.ZERO,
	Direction.RIGHT: Vector2i.RIGHT,
	Direction.BOTTOM_RIGHT: Vector2i(1,1),
	Direction.DOWN: Vector2i.DOWN,
	Direction.BOTTOM_LEFT: Vector2i(-1,1),
	Direction.LEFT: Vector2i.LEFT,
	Direction.TOP_LEFT: Vector2i(-1,-1),
	Direction.UP: Vector2i.UP,
	Direction.TOP_RIGHT: Vector2i(1,-1)
}

static var vector_to_direction : Dictionary[String, Direction] = {
	"00": Direction.NONE,
	"10": Direction.RIGHT,
	"11": Direction.BOTTOM_RIGHT,
	"01": Direction.DOWN,
	"-11": Direction.BOTTOM_LEFT,
	"-10": Direction.LEFT,
	"-1-1": Direction.TOP_LEFT,
	"0-1": Direction.UP,
	"1-1": Direction.TOP_RIGHT
}

static func convert_direction_to_vector(dir:Direction) -> Vector2i:
	if not (dir in direction_to_vector): return Vector2i.ZERO
	return direction_to_vector[dir]

static func convert_vector_to_direction(vec:Vector2i) -> Direction:
	var key := str(vec.x) + str(vec.y)
	if not (key in vector_to_direction): return Direction.NONE
	return vector_to_direction[key]

static func get_opposite_direction_of(dir:Direction) -> Direction:
	return convert_vector_to_direction( -1 * convert_direction_to_vector(dir) )

static func get_orthogonal_directions() -> Array[Direction]:
	return [Direction.RIGHT, Direction.DOWN, Direction.LEFT, Direction.UP]

static func is_horizontal(dir:Direction) -> bool:
	return [Direction.RIGHT, Direction.LEFT].has(dir)

static func is_vertical(dir:Direction) -> bool:
	return [Direction.UP, Direction.DOWN].has(dir)

func create(new_size:Vector2i) -> void:
	size = new_size
	
	grid = []
	cells = []
	
	grid.resize(size.x)
	for x in range(size.x):
		grid[x] = []
		grid[x].resize(size.y)
		for y in range(size.y):
			var new_cell = creation_callback.call(Vector2i(x,y))
			grid[x][y] = new_cell
			cells.append(new_cell)
	
	create_neighbors()

func create_neighbors() -> void:
	if neighbor_mode == NeighborMode.NONE: return
	
	var dirs := get_neighbor_directions() 
	for cell in cells:
		cell.clear_neighbors()
		for dir in dirs:
			var pos := cell.pos + dir
			if is_out_of_bounds(pos): continue
			cell.add_neighbor(get_at(pos))

func get_neighbor_directions() -> Array[Vector2i]:
	var arr : Array[Vector2i] = []
	arr.assign(neighbor_directions[neighbor_mode])
	return arr

func get_at(pos:Vector2i) -> PuzzleCell:
	if is_out_of_bounds(pos): return null
	return grid[pos.x][pos.y]

func is_out_of_bounds(pos:Vector2i) -> bool:
	return pos.x < 0 or pos.x >= size.x or pos.y < 0 or pos.y >= size.y

func get_row(idx:int) -> Array[PuzzleCell]:
	var arr : Array[PuzzleCell] = []
	for x in range(size.x):
		arr.append(grid[x][idx])
	return arr

func get_column(idx:int) -> Array[PuzzleCell]:
	var arr : Array[PuzzleCell] = []
	arr.assign(grid[idx])
	return arr

func get_random_cell() -> PuzzleCell:
	return cells.pick_random()

func get_cells() -> Array[PuzzleCell]:
	return cells
