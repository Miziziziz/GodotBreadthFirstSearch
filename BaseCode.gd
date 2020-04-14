extends Node2D

onready var tilemap = $TileMap
onready var player = $Player

export var move_speed = 0.2
var move_time = 0.0
var path = []
var p_last_pos = Vector2()

func _process(delta):
	if Input.is_action_just_pressed("click"):
		var mouse_pos = global_position_to_tilemap_pos(get_global_mouse_position())
		var player_pos = global_position_to_tilemap_pos(player.global_position)
		path = []
		path = get_path_bfs(player_pos, mouse_pos)
		move_time = 0.0
		p_last_pos = player.global_position
	
	if path.size() > 0:
		move_time += delta
		var goal_pos = tilemap.map_to_world(Vector2(path[0].x, path[0].y)) + Vector2(8, 8)
		player.global_position = lerp(p_last_pos, goal_pos, move_time / move_speed)
		if move_time >= move_speed:
			move_time = 0.0
			path.pop_front()
			p_last_pos = goal_pos
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func global_position_to_tilemap_pos(pos):
	var t_pos = tilemap.world_to_map(pos)
	return {"x": int(round(t_pos.x)), "y": int(round(t_pos.y))}

func can_move_to_spot(cell_pos):
	return tilemap.get_cell(cell_pos.x, cell_pos.y) < 0

var queue = []
var visited = {}
const MAX_ITERS = 10000
func get_path_bfs(start_pos, goal_pos):
	if !can_move_to_spot(goal_pos):
		return []
	queue = []
	visited = {}
	queue.push_back({"pos": start_pos, "last_pos": null})
	var iters = 0
	while queue.size() > 0:
		var cell_info = queue.pop_front()
		if check_cell(cell_info.pos, cell_info.last_pos, goal_pos):
			break
		iters += 1
		if iters >= MAX_ITERS:
			return []
	var backtraced_path = []
	var cur_pos = goal_pos
	while str(cur_pos) in visited and visited[str(cur_pos)] != null:
		if cur_pos != null:
			backtraced_path.append(cur_pos)
		cur_pos = visited[str(cur_pos)]
	backtraced_path.invert()
	return backtraced_path

func check_cell(cur_pos, last_pos, goal_pos):
	if !can_move_to_spot(cur_pos):
		return false
	if str(cur_pos) in visited:
		return false
	
	visited[str(cur_pos)] = last_pos
	if cur_pos.x == goal_pos.x and cur_pos.y == goal_pos.y:
		return true
	queue.push_back({"pos": {"x": cur_pos.x, "y": cur_pos.y + 1}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x + 1, "y": cur_pos.y}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x, "y": cur_pos.y - 1}, "last_pos": cur_pos})
	queue.push_back({"pos": {"x": cur_pos.x - 1, "y": cur_pos.y}, "last_pos": cur_pos})
	return false
