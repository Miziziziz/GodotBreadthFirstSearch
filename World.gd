extends Node2D

onready var tilemap = $TileMap
onready var player = $Player

func _ready():
	pass # Replace with function body.

func _process(delta):
	if Input.is_action_just_pressed("click"):
		mouse_pos = global_position_to_tilemap_pos(get_global_mouse_position())
		var player_pos = global_position_to_tilemap_pos(player.global_position)
		path = []
		path = yield(get_path_bfs(player_pos, mouse_pos), "completed")
		#path = get_path_bfs(player_pos, mouse_pos)
		update()
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

var path = []
var mouse_pos = Vector2()
var path_display = []
var reached_end = false
func _draw():
	for cell_info in visited_data_for_display:
		var cell_pos = tilemap.map_to_world(Vector2(cell_info.pos.x, cell_info.pos.y)) + Vector2(8, 8)
		if reached_end:
			draw_circle(cell_pos, 5, Color.lightsalmon)
		else:
			draw_circle(cell_pos, 5, Color.red)
		if cell_info.last_pos != null:
			var last_cell_pos = tilemap.map_to_world(Vector2(cell_info.last_pos.x, cell_info.last_pos.y)) + Vector2(8, 8)
			if reached_end:
				draw_line(cell_pos, last_cell_pos, Color.lightgreen, 2)
			else:
				draw_line(cell_pos, last_cell_pos, Color.green, 2)
	draw_circle(tilemap.map_to_world(Vector2(mouse_pos.x, mouse_pos.y)) + Vector2(8, 8), 5, Color.yellow)
	var last_cell_pos = null
	if len(path_display) > 0:
		last_cell_pos = tilemap.map_to_world(Vector2(path_display[0].x, path_display[0].y)) + Vector2(8, 8)
#	var t_path = path.duplicate()
#	t_path.invert()
	for cell in path_display:
		var cell_pos = tilemap.map_to_world(Vector2(cell.x, cell.y)) + Vector2(8, 8)
		#draw_rect(Rect2(cell_pos - Vector2(8, 8), Vector2(16,16)), Color.blue)
		draw_line(cell_pos, last_cell_pos, Color.blue, 2)
		last_cell_pos = cell_pos


func global_position_to_tilemap_pos(pos):
	var t_pos = tilemap.world_to_map(pos)
	return {"x": int(round(t_pos.x)), "y": int(round(t_pos.y))}

func can_move_to_spot(cell_pos):
	return tilemap.get_cell(cell_pos.x, cell_pos.y) < 0

const DISPLAY_RATE = 0.01
const PATH_DISPLAY_RATE = 0.1
const MAX_ITERS = 10000
var queue = []
var visited = {}
var visited_data_for_display = []
func get_path_bfs(start_pos, goal_pos):
	queue = [{"pos": start_pos, "last_pos": null}]
	visited = {}
	visited_data_for_display = []
	path_display = []
	reached_end = false
	update()
	if !can_move_to_spot(goal_pos):
		yield(get_tree().create_timer(DISPLAY_RATE), "timeout") # I don't understand yield but this is required
		return []
	var iters = 0
	while queue.size() > 0:
		var cell_info = queue.pop_front()
		if check_cell(cell_info.pos, cell_info.last_pos, goal_pos):
			reached_end = true
			break
		iters += 1
		if iters >= MAX_ITERS:
			return []
		yield(get_tree().create_timer(DISPLAY_RATE), "timeout")
		update()
	var backtraced_path = []
	var cur_pos = goal_pos
	while str(cur_pos) in visited and visited[str(cur_pos)] != null:
		yield(get_tree().create_timer(PATH_DISPLAY_RATE), "timeout")
		update()
		if cur_pos != null:
			backtraced_path.append(cur_pos)
			path_display.append(cur_pos)
		cur_pos = visited[str(cur_pos)]
	path_display.append(start_pos)
	backtraced_path.invert()
	return backtraced_path

func check_cell(cur_pos, last_pos, goal_pos):
	if !can_move_to_spot(cur_pos):
		return false
	if str(cur_pos) in visited:
		return false
	
	visited[str(cur_pos)] = last_pos
	visited_data_for_display.append({"pos": cur_pos, "last_pos": last_pos})
	if cur_pos.x == goal_pos.x and cur_pos.y == goal_pos.y:
		return true
	
	queue.push_back({"pos": {"x": cur_pos.x, "y": cur_pos.y + 1}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x + 1, "y": cur_pos.y}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x, "y": cur_pos.y - 1}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x - 1, "y": cur_pos.y}, "last_pos": cur_pos})
	return false
