class_name Brick extends StaticBody2D

@onready var tile_map : TileMap = %TileMap
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var collision_shape : CollisionShape2D = %CollisionShape

# Local brick coordinates of left and right sides
# Coords don't start in (0, 0) because brick's top left corner
# is shifted to the left to be centered on the scene.
const BRICK_LEFT_COORDS = Vector2i(-1, -1)
const BRICK_RIGHT_COORDS = Vector2i(0, -1)


# Brick max health.
# Redefine in inherited class _ready() to set brick health
# max brick health is 3 to accommodate 3 brick sprite
# types - whole, half-cracked and fully cracked
var health = 1

# Coordinates of tiles in atlas specific to half-cracked
# and fully cracked brick.
# Redefine in inherited brick classes if brick has max health >= 2.
# If brick has health=1, it gets destroyed after being hit.
var half_cracked_coords
var fully_cracked_coords

func _ready():
	# just a safeguard against health > 3
	if health > 3:
		health = 3

# a brick takes damage
func take_damage():
	health -= 1
	animation_player.play("hit")

	# TODO remove collision from all bricks in the group from Globals?
	# if heavy ball power-up is active - remove brick collision shape
	# immediately to avoid brick collision shapes slow down the ball.
	# Remove the brick afterwards once animation is finished.
	if Globals.get_active_powerup() == Globals.POWERUP_HEAVY_BALL:
		collision_shape.disabled = true

	await animation_player.animation_finished

	if Globals.get_active_powerup() == Globals.POWERUP_HEAVY_BALL:
		queue_free()
		return

	# if after taking the damage brick has 1 or 2 health,
	# update the brick sprite types to half-cracked or
	# fully cracked
	# TODO doesn't work - continue
	if health >= 2:
		tile_map.set_cell(0, BRICK_LEFT_COORDS, 0, half_cracked_coords[0])
		tile_map.set_cell(0, BRICK_RIGHT_COORDS, 0, half_cracked_coords[1])
	elif health == 1:
		tile_map.set_cell(0, BRICK_LEFT_COORDS, 0, fully_cracked_coords[0])
		tile_map.set_cell(0, BRICK_RIGHT_COORDS, 0, fully_cracked_coords[1])
	else:
		queue_free()
