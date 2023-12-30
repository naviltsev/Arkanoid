extends Node2D

@onready var tile_map : TileMap = $BricksTileMap
@onready var particles : GPUParticles2D = $Particles
@onready var audio_equip : AudioStreamPlayer = $AudioEquip
@onready var audio_dismantle : AudioStreamPlayer = $AudioDismantle

# Coordinates of a tile the bottom wall consists of in tile map atlas.
const BRICK_ATLAS_COORDS = Vector2i(14, 0)

# total bricks in the wall
const TOTAL_BRICKS = 31

# after placing the brick in the wall, wait for this amount of time
const BRICK_TIME = 0.015 # sec

func _ready():
	# the following values are set in Inspector, but resetting them in case
	# Inspector value gets changed accidentally
	particles.one_shot = true
	particles.emitting = false
	particles.lifetime = TOTAL_BRICKS * BRICK_TIME + 0.25 # seconds

# animates the wall
# if tile_source_id set to a real source ID of tile map (eg. 0), the tile will be painted
# if tile_source_id set to -1, the tile will be erased
func animate(tile_source_id: int):
	particles.emitting = true
	for num in range(TOTAL_BRICKS): # 31 bricks in total in the wall
		# tile's local position on the scene
		var tile_local_pos = Vector2i(num + 1, 22)

		# particle's position on the scene
		var particles_pos = Vector2(72 + num * 48, 1080)

		tile_map.set_cell(0, tile_local_pos, tile_source_id, BRICK_ATLAS_COORDS)
		particles.position = particles_pos
		await get_tree().create_timer(0.015).timeout


# builds a bottom wall, brick by brick from left to right
func equip():
	audio_equip.play()
	animate(0)

# removes a bottom wall, brick by brick from left to right
func dismantle():
	audio_dismantle.play()
	animate(-1)
