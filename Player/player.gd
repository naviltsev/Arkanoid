extends CharacterBody2D

@onready var tile_map : TileMap = %TileMap
@onready var collision_shape : CollisionShape2D = %CollisionShape

var ball_scene = preload("res://Balls/ball.tscn")

# A reference to an instantiated ball scene
var ball

# Ball coords in relation to paddle coords
# Effectively, this is a ball cordinates in paddle coord system
var ball_paddle_diff

# Paddle tiles (in "paddle" tileset)
# Each tile is 16x16 px, scale is 4
var PADDLE_TILE_LEFT_COORDS = Vector2i(4, 0)
var PADDLE_TILE_RIGHT_COORDS = Vector2i(5, 0)

# Paddle tiles (in "paddle_shifted" tiles - its X margin is shifted by 8 px
# in order to be able to pick the middle paddle part
var PADDLE_TILE_MIDDLE_COORDS = Vector2i(4, 0)

# Paddle init position
var PADDLE_INIT_POSITION = Vector2(864, 960)

# Length of the paddle.
# Length is amount of srites the paddle consists of
# - left sprite
# - middle sprite
# - right sprite
var PADDLE_LENGTH = 3

# Multiply any paddle related widths/heights by this scale
var PADDLE_SCALE = 4

# 16 pixels is the length of the sprite of paddle's piece
var PADDLE_INDIVIDUAL_SPRITE_WIDTH = 16

# Paddle width in pixels
var PADDLE_WIDTH = PADDLE_LENGTH * PADDLE_INDIVIDUAL_SPRITE_WIDTH * PADDLE_SCALE

# Paddle height in pixels
var PADDLE_HEIGHT = PADDLE_INDIVIDUAL_SPRITE_WIDTH * PADDLE_SCALE

# Ball offset relative to paddle position (places the ball in the center of the paddle)
var BALL_OFFSET = Vector2(96, 6)

# Paddle speed
var SPEED = 700

# State enum
enum {
	STATE_BALL_ATTACHED, # ball is detached from the paddle
	STATE_BALL_DETACHED, # ball is on the paddle
}

var _state
var motion

func _ready():
	# init local ball coords
	ball_paddle_diff = BALL_OFFSET

	# place the paddle
	motion = Vector2.ZERO
	position = PADDLE_INIT_POSITION

	connect_signals()
	restart()

func connect_signals():
	Events.connect("ball_attaches_to_paddle", attach_ball_to_paddle)
	Events.connect("ball_out_of_screen", restart)
	Events.connect("enable_powerup", enable_powerup)

func _physics_process(delta):
	motion.x = Input.get_axis("ui_left", "ui_right")
	
	move_and_collide(motion * SPEED * delta)
	
	# move ball along with the paddle
	if _state == STATE_BALL_ATTACHED:
		ball.position.x = position.x + ball_paddle_diff.x

	if Input.is_action_just_pressed("ui_accept"):
		set_state(STATE_BALL_DETACHED)
		ball.launch()

func set_state(state: int):
	_state = state

# Init ball scene and attach it to the paddle
# The ball will be detached when the game begins with SPACE press
func init_ball_on_paddle() -> void:
	ball = ball_scene.instantiate()
	ball.position = position + ball_paddle_diff
	add_child(ball)

func attach_ball_to_paddle(coords: Vector2) -> void:
	set_state(STATE_BALL_ATTACHED)
	ball_paddle_diff.x = coords.x - position.x

	# fix ball's Y position so that ball doesn't get stuck in the paddle
	if ball.position.y != position.y + BALL_OFFSET.y:
		ball.position.y = position.y + BALL_OFFSET.y

# Ball is reported as below the paddle if ball.Y coordinate at collision time is below
# ball's idle position on the paddle (which is essentially 966px)
func is_ball_above_paddle() -> bool:
	if ball.position.y <= (PADDLE_INIT_POSITION.y + BALL_OFFSET.y):
		return true
	return false

# Draw paddle using tiles
func init_paddle() -> void:
	# draw 3 tiles from atlas coords PADDLE_*_COORDS
	tile_map.set_cell(0, Vector2i(0, 0), 0, PADDLE_TILE_LEFT_COORDS)
	tile_map.set_cell(0, Vector2i(1, 0), 1, PADDLE_TILE_MIDDLE_COORDS)
	tile_map.set_cell(0, Vector2i(2, 0), 0, PADDLE_TILE_RIGHT_COORDS)

	setup_paddle_collision()

# Setup paddle's collision shape
func setup_paddle_collision() -> void:
	# set collision shape global position to a global position of the player
	collision_shape.global_position = global_position
	
	# set collision shape
	# offset_y is how far down should the top left corner of collision shape shifted
	# even though player tile is 16x16, its visible height is 9 px - top 7 px are transparent
	# and shouldn't be covered by collision shape
	# offset_y defines the offset - 7px * 4 (scale)
	# height is 16px * 4 (scale) minus offset_y
	var offset_y = 7 * PADDLE_SCALE
	var height = PADDLE_HEIGHT - offset_y
	collision_shape.position = Vector2(PADDLE_WIDTH / 2, height / 2 + offset_y)

	# set collision shape size in real pixels
	collision_shape.shape.set_size(Vector2(PADDLE_WIDTH, height))

# Restart the paddle by placing it in the middle of the screen
# with the ball attached
func restart():
	set_state(STATE_BALL_ATTACHED)
	init_paddle()
	
	if ball:
		ball.queue_free()

	ball_paddle_diff = BALL_OFFSET
	init_ball_on_paddle()

func disable_powerup(powerup_timer: Timer):
	Globals.deactivate_powerup()
	powerup_timer.queue_free()

func enable_powerup(powerup_type: int):
	# init and start powerup timer
	# while timer is on, the powerup is active, no other powerups are
	# getting released
	var powerup_timer = Timer.new()
	get_tree().get_root().add_child(powerup_timer)
	powerup_timer.connect("timeout", disable_powerup.bind(powerup_timer))
	powerup_timer.start(Globals.POWERUP_TIMER[powerup_type])

	# Globals.is_powerup_enabled = true
	Globals.activate_powerup(powerup_type)
