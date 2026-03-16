extends Node2D

@export var map_width_tiles: int = 56
@export var map_height_tiles: int = 24
@export var tile_size: int = 8 # 16 * 0.5 scale
@export var floor_count: int = 4

var rng = RandomNumberGenerator.new()
var tilemap: TileMap

var p1_spawn_pos = Vector2()
var p2_spawn_pos = Vector2()
var pistol_pos = Vector2()
var revolver_pos = Vector2()

func _ready():
	tilemap = $TileMap
	generate()

func generate():
	rng.randomize()
	if not tilemap:
		tilemap = $TileMap
	
	var verified = false
	var attempts = 0
	while not verified and attempts < 100:
		tilemap.clear_layer(0)
		_generate_border()
		_generate_floors()
		_place_spawns()
		_place_gun()
		if _verify_connectivity():
			verified = true
		else:
			attempts += 1
			
	if not verified:
		print("Failed to generate a connected map after many attempts!")
	else:
		print("Map generated and verified in ", attempts, " attempts.")

func _generate_border():
	var left = int(-map_width_tiles / 2)
	var right = int(map_width_tiles / 2)
	var top = int(-map_height_tiles / 2)
	var bottom = int(map_height_tiles / 2)
	
	for y in range(top, bottom + 1):
		tilemap.set_cell(0, Vector2i(left, y), 0, Vector2i(1, 1))
		tilemap.set_cell(0, Vector2i(right, y), 0, Vector2i(1, 1))
	for x in range(left, right + 1):
		tilemap.set_cell(0, Vector2i(x, top), 0, Vector2i(1, 1))

func _generate_floors():
	var left = int(-map_width_tiles / 2) + 1
	var right = int(map_width_tiles / 2) - 1
	var top = int(-map_height_tiles / 2)
	var bottom = int(map_height_tiles / 2)
	
	# Always solid bottom floor
	for x in range(left, right + 1):
		tilemap.set_cell(0, Vector2i(x, bottom), 0, Vector2i(1, 1))
		
	var usable_height = bottom - top - 3
	var floor_spacing = usable_height / floor_count
	
	for i in range(1, floor_count):
		var y = bottom - (i * floor_spacing)
		_generate_platform_row(y, left, right)

func _generate_platform_row(y: int, left: int, right: int):
	var x = left
	while x <= right:
		var plat_len = rng.randi_range(6, 12)
		var gap_len = rng.randi_range(3, 6)
		
		# Prevent tiny unjumpable platforms at the very right edge
		if right - (x + plat_len + gap_len) < 4:
			plat_len = right - x + 1
			gap_len = 0
			
		for k in range(plat_len):
			if x + k <= right:
				tilemap.set_cell(0, Vector2i(x + k, y), 0, Vector2i(1, 1))
				
		x += plat_len + gap_len

func _place_spawns():
	var bottom = int(map_height_tiles / 2) - 1
	var left_spawn_x = int(-map_width_tiles / 2) + 5
	var right_spawn_x = int(map_width_tiles / 2) - 5
	
	p1_spawn_pos = Vector2(left_spawn_x * tile_size, bottom * tile_size)
	p2_spawn_pos = Vector2(right_spawn_x * tile_size, bottom * tile_size)
	
	var players = get_node_or_null("../Players")
	if players:
		for p in players.get_children():
			if "GreenBoii" in p.name:
				p.global_position = p1_spawn_pos
				p.set_meta("start_pos", p1_spawn_pos)
			elif "PinkBoii" in p.name:
				p.global_position = p2_spawn_pos
				p.set_meta("start_pos", p2_spawn_pos)

func _place_gun():
	var top = int(-map_height_tiles / 2)
	var bottom = int(map_height_tiles / 2)
	var usable_height = bottom - top - 3
	var floor_spacing = usable_height / floor_count
	var top_fl_y = bottom - ((floor_count - 1) * floor_spacing)
	
	pistol_pos = Vector2(-15 * tile_size, (top_fl_y - 1) * tile_size)
	revolver_pos = Vector2(15 * tile_size, (top_fl_y - 1) * tile_size)
	
	var gm = get_node_or_null("../../../GameManager")
	if gm:
		gm.pistol_spawn_pos = pistol_pos
		gm.revolver_spawn_pos = revolver_pos
		
	var players = get_node_or_null("../Players")
	if players:
		for node in players.get_children():
			if "PistolDrop" in node.name:
				node.global_position = pistol_pos
			elif "RevolverDrop" in node.name:
				node.global_position = revolver_pos

func _verify_connectivity() -> bool:
	var bottom = int(map_height_tiles / 2) - 1
	
	var p1_t = Vector2i(int(p1_spawn_pos.x / tile_size), int(p1_spawn_pos.y / tile_size))
	var p2_t = Vector2i(int(p2_spawn_pos.x / tile_size), int(p2_spawn_pos.y / tile_size))
	var g1_t = Vector2i(int(pistol_pos.x / tile_size), int(pistol_pos.y / tile_size))
	var g2_t = Vector2i(int(revolver_pos.x / tile_size), int(revolver_pos.y / tile_size))
	
	var reachable = _get_all_reachable(p1_t)
	var g1_box = _get_cell_variants(g1_t)
	var g2_box = _get_cell_variants(g2_t)
	var p2_box = _get_cell_variants(p2_t)
	
	var reach_g1 = false
	for g in g1_box:
		if reachable.has(g): reach_g1 = true
	var reach_g2 = false
	for g in g2_box:
		if reachable.has(g): reach_g2 = true
	var reach_p2 = false
	for p in p2_box:
		if reachable.has(p): reach_p2 = true

	if not reach_g1 or not reach_g2 or not reach_p2:
		return false
		
	return true

func _get_cell_variants(center: Vector2i) -> Array:
	return [
		center,
		center + Vector2i(0, 1),
		center + Vector2i(0, -1),
		center + Vector2i(1, 0),
		center + Vector2i(-1, 0)
	]

func _get_all_reachable(start: Vector2i) -> Dictionary:
	var visited = {}
	var queue = [start]
	var max_jump_x = 8
	var max_jump_y = 6
	
	var left = int(-map_width_tiles / 2)
	var right = int(map_width_tiles / 2)
	var top = int(-map_height_tiles / 2)
	var bottom = int(map_height_tiles / 2)
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if visited.has(current): continue
		visited[current] = true
		
		for dx in [-1, 1]:
			var nx = current.x + dx
			var ny = current.y
			if nx > left and nx < right:
				# Drop down
				var is_free = true
				var check_y = ny
				while check_y <= bottom and tilemap.get_cell_source_id(0, Vector2i(nx, check_y)) == -1:
					check_y += 1
				if check_y <= bottom:
					var target = Vector2i(nx, check_y - 1)
					if not visited.has(target):
						queue.append(target)
		
		# Jumping to reachable platforms
		for jx in range(-max_jump_x, max_jump_x + 1):
			for jy in range(-max_jump_y, max_jump_y + 1):
				var nx = current.x + jx
				var ny = current.y + jy
				if nx > left and nx < right and ny > top and ny <= bottom:
					if tilemap.get_cell_source_id(0, Vector2i(nx, ny)) == -1 and tilemap.get_cell_source_id(0, Vector2i(nx, ny + 1)) != -1:
						var target = Vector2i(nx, ny)
						if not visited.has(target):
							queue.append(target)
							
	return visited

func _process(delta: float) -> void:
	if Input.is_action_pressed("Reset"):
		generate()
