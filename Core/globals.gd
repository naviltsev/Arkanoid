extends Node

var scene_transitioner = preload("res://GUI/scene_transitioner.tscn")

# how frequently does power-up release
const POWERUP_RELEASE_CHANCE = 0.1

# Powerup Timer node name
const POWERUP_TIMER_NAME = "PowerupTimer"

# Power-up types
enum {
	POWERUP_NONE,
	POWERUP_MISSILES,
	POWERUP_DOUBLE_SCORE,
	POWERUP_HEAVY_BALL,
	POWERUP_MULTIPLE_BALLS,
	POWERUP_EXTRA_HEALTH,
	POWERUP_WIDE_PADDLE,
	POWERUP_GLUE_PADDLE,
	POWERUP_CLEAR_LEVEL,
	POWERUP_BOTTOM_WALL,
}

# Coordinates of a power-up tile in a tilemap to be displayed in info panel
const POWERUP_COORDS = {
	POWERUP_MISSILES: Vector2i(0, 0),
	POWERUP_DOUBLE_SCORE: Vector2i(1, 0),
	POWERUP_MULTIPLE_BALLS: Vector2i(2, 0),
	POWERUP_EXTRA_HEALTH: Vector2i(3, 0),
	POWERUP_HEAVY_BALL: Vector2i(4, 0),
	POWERUP_GLUE_PADDLE: Vector2i(5, 0),
	POWERUP_WIDE_PADDLE: Vector2i(6, 0),
	POWERUP_CLEAR_LEVEL: Vector2i(7, 0),
	POWERUP_BOTTOM_WALL : Vector2i(8, 0),
}

# One-off power-ups
# These won't be added to the list of active power-ups
# if they get caught by the paddle
const POWERUP_ONE_OFF = [POWERUP_CLEAR_LEVEL, POWERUP_EXTRA_HEALTH]

# Power-up timers, in seconds.
# While timer is on, power-up is active.
# Some power-ups don't have timer and they are active while ball is on the screen.
# Such power-ups don't have their timers set here.
const POWERUP_TIMER = {
	POWERUP_MISSILES: 10,
	POWERUP_DOUBLE_SCORE: 40,
	POWERUP_HEAVY_BALL: 10,
	POWERUP_MULTIPLE_BALLS: 20,
	POWERUP_WIDE_PADDLE: 30,
	POWERUP_GLUE_PADDLE: 40,
	POWERUP_BOTTOM_WALL: 30,
}

# Power-up human readable name for debugging purposes
var POWERUP_NAME = {
	POWERUP_NONE: "None",
	POWERUP_MISSILES: "Missiles",
	POWERUP_DOUBLE_SCORE: "Double Score",
	POWERUP_HEAVY_BALL: "Heavy Ball",
	POWERUP_MULTIPLE_BALLS: "Multi Balls",
	POWERUP_EXTRA_HEALTH: "Extra Health",
	POWERUP_GLUE_PADDLE: "Glue Paddle",
	POWERUP_WIDE_PADDLE: "Wide Paddle",
	POWERUP_CLEAR_LEVEL: "Boomstick",
	POWERUP_BOTTOM_WALL: "Bottom Wall",
}

# Setup for concurrent power ups.
# Key is first powerup caught by the paddle,
# value is a list of power-ups allowed to be active at the same time.
var CONCURRENT_POWERUP = {
	POWERUP_BOTTOM_WALL: [
		POWERUP_MISSILES,
		POWERUP_MULTIPLE_BALLS,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	],
	POWERUP_MISSILES: [
		POWERUP_MULTIPLE_BALLS,
		POWERUP_BOTTOM_WALL,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	],
	POWERUP_MULTIPLE_BALLS: [
		POWERUP_BOTTOM_WALL,
		POWERUP_MISSILES,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	],
	POWERUP_HEAVY_BALL: [
		POWERUP_BOTTOM_WALL,
		POWERUP_MULTIPLE_BALLS,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	],
	POWERUP_WIDE_PADDLE: [
		POWERUP_GLUE_PADDLE,
		POWERUP_BOTTOM_WALL,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	],
	POWERUP_GLUE_PADDLE: [
		POWERUP_HEAVY_BALL,
		POWERUP_DOUBLE_SCORE,
		POWERUP_EXTRA_HEALTH,
	]
}

# if power up is released and is visible on screen
var is_powerup_on_screen = false

# currently active power ups
var active_powerup = []

# Player lives counter resides here in globals.gd
var lives

# Player score resides here in globals.gd
var player_score = 0

# Current level
var current_level

func _ready():
	current_level = 0
	Events.connect("enable_powerup", enable_powerup)
	Events.connect("game_over", game_over)
	Events.connect("ball_out_of_screen", ball_out_of_screen)
	Events.connect("game_paused", game_paused)

# show/hide game paused screen
func game_paused():
	# toggle paused
	get_tree().paused = !get_tree().paused

	# paused screen on or off
	if get_tree().paused:
		var game_paused_scene = load("res://GUI/paused_screen.tscn").instantiate()
		get_tree().root.add_child(game_paused_scene)
	else:
		var game_paused_scene = get_tree().root.get_node("GamePaused")
		get_tree().root.remove_child(game_paused_scene)

func _activate_powerup(powerup_type: int):
	# do not to active power-ups if power-up is a one-off
	if powerup_type in POWERUP_ONE_OFF:
		return

	active_powerup.push_back(powerup_type)
	is_powerup_on_screen = false

func _deactivate_powerup(powerup_type: int):
	active_powerup.remove_at(active_powerup.find(powerup_type))

func is_powerup_active(powerup_type: int):
	return active_powerup.find(powerup_type) > -1

func debug(msgs: Array[String]) -> void:
	var debug_str = ""
	for m in msgs:
		debug_str += " " + m
	print("[debug] ", debug_str)

# Get current level scene node.
# All levels share the same node name "Level"
func get_current_level_node():
	return get_tree().root.get_node("Level")

# create a Timer node, add it to the current scene,
# start the timer based on power-up timer value
func setup_powerup_timer_node(powerup_type: int):
		var timer = Timer.new()

		timer.name = POWERUP_TIMER_NAME + str(powerup_type)
		timer.one_shot = true

		get_current_level_node().add_child(timer)
		timer.start(POWERUP_TIMER[powerup_type])

		timer.timeout.connect(disable_powerup.bind(powerup_type))

# gets the Timer node for specific power-up type
func get_powerup_timer_node(powerup_type: int):
	return get_current_level_node().get_node(POWERUP_TIMER_NAME + str(powerup_type))

func dismantle_powerup_timer_node(powerup_type: int):
	var timer = get_powerup_timer_node(powerup_type)
	if timer:
		get_current_level_node().remove_child(timer)

func enable_powerup(powerup_type: int):
	# Init Timer node, attach it to the main scene
	# and start the timer.
	# As long as timer is active, the powerup is active
	if POWERUP_TIMER.has(powerup_type):
		setup_powerup_timer_node(powerup_type)

	debug(["enabled powerup: ", POWERUP_NAME[powerup_type]])

	match powerup_type:
		POWERUP_HEAVY_BALL:
			Events.heavy_ball_equipped.emit()
		POWERUP_MULTIPLE_BALLS:
			Events.multiple_balls_equipped.emit()
		POWERUP_WIDE_PADDLE:
			Events.wide_paddle_equipped.emit()
		POWERUP_CLEAR_LEVEL:
			Events.powerup_clear_level.emit()
		POWERUP_BOTTOM_WALL:
			Events.bottom_wall_equipped.emit()
		POWERUP_MISSILES:
			Events.missiles_equipped.emit()
		POWERUP_EXTRA_HEALTH:
			lives += 1
			Events.player_lives_updated.emit(lives)
			
			# return after extra health power-up
			# extra-health is not a usual power-up, it only bumps lives counter
			# and doesn't get added as a power-up in power-ups stack
			return

	_activate_powerup(powerup_type)

func disable_powerup(powerup_type: int):
	dismantle_powerup_timer_node(powerup_type)

	# start power-up cooldown timer
	get_current_level_node().get_node("PowerupCooldownTimer").start()

	match powerup_type:
		POWERUP_HEAVY_BALL:
			Events.heavy_ball_dismantled.emit()

			# re-enable collision shapes on all bricks - this is a workaround
			# for a bug: if heavy ball is inside a brick and power-up gets disabled,
			# the collision shape for the brick that the ball is inside of
			# doesn't turn on back
			get_tree().call_group("bricks", "enable_collision_shape")
		POWERUP_WIDE_PADDLE:
			Events.wide_paddle_dismantled.emit()
		POWERUP_BOTTOM_WALL:
			Events.bottom_wall_dismantled.emit()
		POWERUP_MISSILES:
			Events.missiles_dismantled.emit()
		POWERUP_MULTIPLE_BALLS:
			Events.multiple_balls_dismantled.emit()

	_deactivate_powerup(powerup_type)

	Events.disable_powerup.emit(powerup_type)

	debug(["disabled powerup"])

func disable_all_powerups():
	for p in active_powerup:
		disable_powerup(p)

# Checks if power up should be released based on the list of criteria.
# Returns power-up type to be activated.
# Returns 0 if power-up shouldn't be released.
func should_release_powerup_type() -> int:
	if active_powerup.size() >= 3:
		return POWERUP_NONE

	# never release a power-up if 1 destructible brick left
	var total_bricks = get_tree().get_nodes_in_group("bricks").size()
	var indestructible_bricks = get_tree().get_nodes_in_group("indestructible_bricks").size()
	if total_bricks - indestructible_bricks <= 1:
		return POWERUP_NONE

	# if power-up cooldown timer is ticking
	if not get_current_level_node().get_node("PowerupCooldownTimer").is_stopped():
		return POWERUP_NONE

	var should_release = false
	if randf() < POWERUP_RELEASE_CHANCE and \
		not is_powerup_on_screen:
		should_release = true

	if !should_release:
		return POWERUP_NONE

	# Figure out power-up type to be released
	var release_powerup = POWERUP_NONE

	# If no active power-ups...
	if active_powerup.is_empty():
		# Choose power-up to release
		var p = randf()
		if p < 0.1: # in 10% of cases
			release_powerup = POWERUP_DOUBLE_SCORE
		elif p < 0.2: # in 10% of cases
			release_powerup = POWERUP_EXTRA_HEALTH
		elif p < 0.3: # in 10% of cases
			release_powerup = POWERUP_WIDE_PADDLE
		elif p < 0.45: # in 15% of cases
			release_powerup = POWERUP_GLUE_PADDLE
		elif p < 0.6: # in 15% of cases
			release_powerup = POWERUP_HEAVY_BALL
		elif p < 0.7: # in 10% of cases
			release_powerup = POWERUP_MULTIPLE_BALLS
		elif p < 0.8: # in 10% of cases
			release_powerup = POWERUP_BOTTOM_WALL
		elif p < 0.9: # in 10% of cases
			release_powerup = POWERUP_MISSILES
		else: # in 10% of cases
			release_powerup = POWERUP_CLEAR_LEVEL

	# or if there's an active power-up already...
	else:
		var first_active = active_powerup[0]

		# if currently active power-up can have a concurrent power-up...
		if first_active not in CONCURRENT_POWERUP:
			return POWERUP_NONE

		var allowed_concurrent_powerups = CONCURRENT_POWERUP[first_active]
		
		# shuffle allowed concurrent powerups
		allowed_concurrent_powerups.shuffle()
		for concur in allowed_concurrent_powerups:

			# return if potential concurrent power-up isn't active yet
			if !is_powerup_active(concur):
				release_powerup = concur
				break

	return release_powerup

func ball_out_of_screen():
	lives -= 1
	Events.player_lives_updated.emit(lives)

func load_next_level():
	current_level += 1

	# start inter-level transition scene
	var transitioner_scene = scene_transitioner.instantiate()
	get_tree().root.add_child(transitioner_scene)

	# set transition scene text
	transitioner_scene.set_text("Round %s" % current_level)
	await transitioner_scene.fade_in()

	# delete current level if needed
	# all level scenes has same name - "Level"
	var cur_level = get_current_level_node()
	if cur_level:
		# TODO if queue_free() used, next level don't get "Level" name
		# TODO this is possibly because queue_free() unloads the node after
		# TODO processing the frame, and when we're setting "Level" node name below,
		# TODO previous level is still unloaded (with "Level" name) and thus
		# TODO new level node can't get "Level" name
		cur_level.free()

	# load next level scene
	var level_scene = load("res://Levels/level_%s.tscn" % current_level).instantiate()
	level_scene.name = "Level"

	get_tree().root.add_child(level_scene)

	get_tree().current_scene = level_scene

	# wait a second
	await get_tree().create_timer(1).timeout

	await transitioner_scene.fade_out()
	transitioner_scene.queue_free()

func start_game():
	# reset stats
	current_level = 0
	lives = 0
	player_score = 0

	load_next_level()

func game_over():
	var transitioner_scene = scene_transitioner.instantiate()
	get_current_level_node().add_child(transitioner_scene)
	transitioner_scene.fade_in()

func main_menu():
	var main_menu_scene = load("res://GUI/main_menu.tscn").instantiate()
	get_tree().root.add_child(main_menu_scene)

	# delete level
	var level_node = get_current_level_node()
	if level_node:
		level_node.queue_free()
