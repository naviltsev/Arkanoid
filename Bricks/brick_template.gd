class_name Brick extends StaticBody2D

@onready var tile_map : TileMap = %TileMap
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var collision_shape : CollisionShape2D = %CollisionShape
@onready var particles : GPUParticles2D = $ExplosionParticles

# Local brick coordinates of left and right sides
const BRICK_LEFT_COORDS = Vector2i(0, 0)
const BRICK_RIGHT_COORDS = Vector2i(1, 0)


# Brick max health.
# It is set in "health" custom data layer of a tile.
# Max brick health is 3 to accommodate 3 brick sprite
# types - whole, half-cracked and fully cracked
# Health value of -1 is for indescructible bricks.
var health

# Coordinates of tiles in atlas specific to half-cracked
# and fully cracked brick.
# These coordinates are stored in "half_cracked_coords" and
# "fully_cracked_coords" custom data layers in a tile map.
var half_cracked_coords
var fully_cracked_coords

func _ready():
	# set brick health
	health = tile_map.get_cell_tile_data(0, BRICK_LEFT_COORDS).get_custom_data("health")

	if health > 3:
		push_error("misconfiguration in brick health (shouldn't be greater than 3)")
		health = 3

	# set coordinates of half- and fully-cracked brick tiles
	half_cracked_coords = [
		tile_map.get_cell_tile_data(0, BRICK_LEFT_COORDS).get_custom_data("half_cracked_coords"),
		tile_map.get_cell_tile_data(0, BRICK_RIGHT_COORDS).get_custom_data("half_cracked_coords"),
	]
	fully_cracked_coords = [
		tile_map.get_cell_tile_data(0, BRICK_LEFT_COORDS).get_custom_data("fully_cracked_coords"),
		tile_map.get_cell_tile_data(0, BRICK_RIGHT_COORDS).get_custom_data("fully_cracked_coords"),
	]

	# if tile has a non-empty array of alternate tiles of the current tile in "alternate_tile" custom data layer,
	# randomly choose one of alternate tiles as a default brick tile
	var alternate_tiles_left = tile_map.get_cell_tile_data(0, BRICK_LEFT_COORDS).get_custom_data("alternate_tile")
	var alternate_tiles_right = tile_map.get_cell_tile_data(0, BRICK_RIGHT_COORDS).get_custom_data("alternate_tile")
	
	# length of both arrays should be equal
	# otherwise it is considered a misconfiguration - an error will be thrown and the game continue
	# with the set of default tiles
	if alternate_tiles_left.size() != alternate_tiles_right.size():
		push_error("misconfiguration in coords of alternate tiles of left/right pieces of brick - both pieces should have equal amount of alternate tiles")
		return

	# doesn't matter what array we use for checking it is not empty
	if alternate_tiles_left.size() > 0:
		# replace defaul brick tiles with one of alternatives
		# "index" is the random number between 0 and array_size
		# if 0 is chosen, default tile won't get changed
		# otherwise, the number indicates the index from alternate_tiles array minus 1 of what alternate tile to use
		var index = randi() % (alternate_tiles_left.size() + 1)

		if index > 0:
			tile_map.set_cell(0, BRICK_LEFT_COORDS, 0, alternate_tiles_left[index-1])
			tile_map.set_cell(0, BRICK_RIGHT_COORDS, 0, alternate_tiles_right[index-1])

func enable_collision_shape():
	collision_shape.disabled = false

func disable_collision_shape():
	if is_indestructible():
		return
	collision_shape.disabled = true

# a brick takes damage
func take_damage():
	if !is_indestructible():
		health -= 1

	# if heavy ball power-up is active - remove brick collision shape
	# immediately to avoid brick collision shapes slow down the ball.
	if Globals.is_powerup_active(Globals.POWERUP_HEAVY_BALL):
		disable_collision_shape()

	animation_player.play("hit")

	# check if level is finished
	is_level_cleared()

	# indestructible bricks are indestructible
	if is_indestructible():
		return

	Globals.player_score += 1
	Events.player_score_increment.emit(1)

	# wait for hit animation to finish
	await animation_player.animation_finished

	if Globals.is_powerup_active(Globals.POWERUP_HEAVY_BALL):
		queue_free()
		return

	# if after taking the damage brick has 1 or 2 health,
	# update the brick sprite types to half-cracked or
	# fully cracked
	if health >= 2:
		tile_map.set_cell(0, BRICK_LEFT_COORDS, 0, half_cracked_coords[0])
		tile_map.set_cell(0, BRICK_RIGHT_COORDS, 0, half_cracked_coords[1])
	elif health == 1:
		tile_map.set_cell(0, BRICK_LEFT_COORDS, 0, fully_cracked_coords[0])
		tile_map.set_cell(0, BRICK_RIGHT_COORDS, 0, fully_cracked_coords[1])
	else:
		queue_free()

# destroy brick completely disregarding its health value
func take_full_damage():
	# add as many points as how much health left in the brick
	Globals.player_score += health
	Events.player_score_increment.emit(health)

	# TODO ??? this function gets called multiple times from level.gd, why pausing the ball every time?
	Events.pause_ball.emit()

	particles.emitting = true

	animation_player.play("hit")
	await animation_player.animation_finished

	tile_map.visible = false

	await get_tree().create_timer(3.0).timeout

	queue_free()

func is_indestructible():
	return health < 0

# checks how many (destructible) bricks left on the level
func is_level_cleared():
	var is_live_bricks = get_tree().get_nodes_in_group("bricks").any(func(brick): return brick.health > 0)
	if !is_live_bricks:
		Events.level_cleared.emit()
