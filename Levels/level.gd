extends Node2D

@onready var bottom_wall_scene = preload("res://Levels/bottom_wall.tscn")
@onready var audio_clear_level : AudioStreamPlayer = $AudioPowerupClearLevel

func _ready():
	Events.connect("powerup_clear_level", powerup_clear_level)
	Events.connect("bottom_wall_equipped", powerup_bottom_wall_enable)
	Events.connect("bottom_wall_dismantled", powerup_bottom_wall_disable)
	Events.connect("level_cleared", level_cleared)

func powerup_clear_level():
	Globals.disable_all_powerups()

	# kill ball(s) on the screen
	get_tree().call_group("balls", "kill_ball")
	get_tree().call_group("extra_balls", "kill_ball")

	audio_clear_level.play()

	var bricks = get_tree().get_nodes_in_group("bricks")
	bricks.shuffle()

	# destroy bricks in groups of 10
	var iterations = ceil(bricks.size() / 10.0)
	for i in iterations:
		for b in bricks.slice(i*10, i*10 + 10):
			if b:
				b.take_full_damage()

		# wait for 0.2 seconds before destroying next group of bricks
		await get_tree().create_timer(0.2).timeout

	# pause before advancing to the next level
	# to allow particles to complete
	await get_tree().create_timer(1.5).timeout

	Events.level_cleared.emit()

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
	if bottom_wall:
		bottom_wall.dismantle()

func level_cleared():
	# kill ball(s) on the screen
	get_tree().call_group("balls", "kill_ball")
	get_tree().call_group("extra_balls", "kill_ball")

	# wait a moment to allow transitioner to fade in before
	# advancing to the next level
	await get_tree().create_timer(1.5).timeout
	Globals.load_next_level()
