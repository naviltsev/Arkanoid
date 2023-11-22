extends Node2D

@onready var bottom_wall_scene = preload("res://Levels/bottom_wall.tscn")

func _ready():
	Events.connect("powerup_clear_level", powerup_clear_level)
	Events.connect("bottom_wall_equipped", powerup_bottom_wall_enable)
	Events.connect("bottom_wall_dismantled", powerup_bottom_wall_disable)

func powerup_clear_level():
	get_tree().call_group("bricks", "take_full_damage")
	Globals.disable_powerup(null)

func powerup_bottom_wall_enable():
	var bottom_wall
	if has_node("BottomWall"):
		bottom_wall = get_node("BottomWall")
	else:
		bottom_wall = bottom_wall_scene.instantiate()

	add_child(bottom_wall)
	bottom_wall.equip()

func powerup_bottom_wall_disable():
	var bottom_wall = get_node("BottomWall")
	bottom_wall.dismantle()
