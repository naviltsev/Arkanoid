extends Node2D

@onready var bottom_wall_scene = preload("res://Levels/bottom_wall.tscn")

func _ready():
	Events.connect("powerup_clear_level", powerup_clear_level)
	Events.connect("bottom_wall_equipped", powerup_bottom_wall_enable)
	Events.connect("bottom_wall_dismantled", powerup_bottom_wall_disable)

func powerup_clear_level():
	Globals.disable_powerup(null)

	var bricks = get_tree().get_nodes_in_group("bricks")
	bricks.shuffle()

	# destroy bricks in groups of 10
	var iterations = ceil(bricks.size() / 10.0)
	for i in iterations:
		for b in bricks.slice(i*10, i*10 + 10):
			if b:
				b.take_full_damage()

		# wait for 0.05 seconds before destroying next group of bricks
		await get_tree().create_timer(0.05).timeout

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
