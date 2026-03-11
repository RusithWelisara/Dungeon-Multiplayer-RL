class_name PickupDetector
extends Area2D

signal picked_up(_name: String, weapon: bool)

var player: String
var total_items: Array = []
var current_available_item: PickupItem

func _ready() -> void:
	collision_layer = 0
	collision_mask = 8
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if owner.IS_P1: player = "Player 1"
	else: player = "Player 2"


func _on_area_entered(pickup: PickupItem):
	print("AREA ENTERED")
	if not is_instance_valid(pickup): return
	if not pickup.IS_WEAPON:
		picked_up.emit(pickup.ITEM_NAME, false)
	else:
		var valid_items = []
		for item in total_items:
			if is_instance_valid(item):
				valid_items.append(item)
		total_items = valid_items
		
		total_items.append(pickup)
		current_available_item = pickup
		picked_up.emit(current_available_item.ITEM_NAME, true)

func _on_area_exited(pickup: PickupItem) -> void:
	if not is_instance_valid(pickup) or not pickup.IS_WEAPON: return
	total_items.erase(pickup)
	
	# Clean up any dead references that might have been queue_free'd
	var valid_items = []
	for item in total_items:
		if is_instance_valid(item):
			valid_items.append(item)
	total_items = valid_items
	
	if total_items.size() != 0:
		current_available_item = total_items[total_items.size() - 1]
		if is_instance_valid(current_available_item):
			picked_up.emit(current_available_item.ITEM_NAME, true)
#			print("Current Available_Item is " + current_available_item.ITEM_NAME)
		else:
			picked_up.emit("Nothing", true)
	else:
		print("NOthing HERE LEFT ;-;")
		picked_up.emit("Nothing", true)
