extends AIController2D

var move = {"left": false, "right": false, "idle": false}
var jump = {"yes": false, "no": false}
var shoot = false

func get_obs() -> Dictionary: 
	var obs = []	
	
	var map_width = 1920.0
	var map_height = 1080.0
	var max_speed = 300.0
	var position = _player.global_position
	var velocity = _player.velocity
	var has_gun = false
	if _player.weapon_holder.get_child_count() > 0:
		var gun = _player.weapon_holder.get_child(0)
		if gun and gun.ammo > 0:
			has_gun = true
			
	var health = float(_player.hp)
	var max_health = float(_player.MAX_HP)
	
	# Self
	obs.append(position.x / map_width)
	obs.append(position.y / map_height)
	obs.append(velocity.x / max_speed)
	obs.append(velocity.y / max_speed)
	obs.append(1.0 if has_gun else 0.0)
	obs.append(health / max_health)
	
	# Find Enemy
	var enemy = null
	for node in get_tree().get_nodes_in_group("Player"):
		var p = node if node is CharacterBody2D else node.get_parent()
		if p != _player and p != null and "hp" in p:
			enemy = p
			break
			
	# Enemy
	if enemy:
		var e_has_gun = false
		if enemy.weapon_holder.get_child_count() > 0:
			var e_gun = enemy.weapon_holder.get_child(0)
			if e_gun and e_gun.ammo > 0:
				e_has_gun = true
				
		obs.append(enemy.global_position.x / map_width)
		obs.append(enemy.global_position.y / map_height)
		obs.append(float(enemy.hp) / max_health)
		obs.append(1.0 if e_has_gun else 0.0)
	else:
		obs.append(0.0)
		obs.append(0.0)
		obs.append(0.0)
		obs.append(0.0)
		
	# Find Gun Pickup
	var gun_pickup = null
	var min_dist = INF
	if _player.get_parent():
		for child in _player.get_parent().get_children():
			if "Drop" in child.name and not child.is_queued_for_deletion():
				var dist = position.distance_to(child.global_position)
				if gun_pickup == null or dist < min_dist:
					gun_pickup = child
					min_dist = dist
					
	# Gun pickup (if not held)
	if gun_pickup:
		obs.append(gun_pickup.global_position.x / map_width)
		obs.append(gun_pickup.global_position.y / map_height)
	else:
		obs.append(0.0)
		obs.append(0.0)
		
	# Direction to key targets
	var to_gun = Vector2.ZERO
	if gun_pickup:
		to_gun = (gun_pickup.global_position - position).normalized()
	
	var to_enemy = Vector2.ZERO
	if enemy:
		to_enemy = (enemy.global_position - position).normalized()
		
	obs.append(to_gun.x)
	obs.append(to_gun.y)
	obs.append(to_enemy.x)
	obs.append(to_enemy.y)
	
	return {"obs": obs}

func get_reward() -> float:	
	return reward
	
func get_action_space() -> Dictionary:
	return {
		"move" : {
			"size": 3,
			"action_type": "discrete"
		},
		"jump" : {
			"size": 2,
			"action_type": "discrete"
		},
		"shoot" : {
			"size": 2,
			"action_type": "discrete"
		},
		}
	
func set_action(action) -> void:	
	move.left = action["move"] == 0
	move.right = action["move"] == 1
	move.idle = action["move"] == 2
	
	jump.yes = action["jump"] == 0
	jump.no = action["jump"] == 1
	
	shoot = action["shoot"] == 1
	
	if control_mode == ControlModes.TRAINING:
		# Tiny penalties for spamming jump and shoot
		if jump.yes:
			reward -= 0.01
		if shoot:
			reward -= 0.01
