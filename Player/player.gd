extends CharacterBody2D

@onready var tile_map : TileMap = %TileMap
@onready var collision_shape : CollisionShape2D = %CollisionShape

var ball_scene = preload("res://Balls/ball.tscn")

# A reference to an instantiated ball scene
var ball

# Paddle tiles (in "paddle" tileset)
# Each tile is 16x16 px, scale is 4
var PADDLE_LEFT_COORDS = Vector2i(4, 0)
var PADDLE_RIGHT_COORDS = Vector2i(5, 0)

# Paddle tiles (in "paddle_shifted" tiles - its X margin is shifted by 8 px
# in order to be able to pick the middle paddle part
var PADDLE_MIDDLE_CORRDS = Vector2i(4, 0)

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
var SPEED = 1000

# State enum
enum {
	STATE_BALL_ATTACHED, # ball is detached from the paddle
	STATE_BALL_DETACHED, # ball is on the paddle
}

var _state

func _connect_signals():
	Events.connect("ball_attaches_to_paddle", set_state.bind(STATE_BALL_ATTACHED))
	Events.connect("ball_out_of_screen", restart)
	Events.connect("enable_powerup", enable_powerup)

func _ready():
	_connect_signals()
	restart()

func _physics_process(delta):
	var movement = Vector2.ZERO
	movement.x = Input.get_axis("ui_left", "ui_right")
	
	var collision = move_and_collide(movement * SPEED * delta)
	
	# move ball along with the paddle
	if _state == STATE_BALL_ATTACHED:
		ball.global_position.x = global_position.x + PADDLE_WIDTH / 2

	if Input.is_action_just_pressed("ui_accept"):
		set_state(STATE_BALL_DETACHED)
		ball.launch()

func set_state(state: int):
	print("set paddle state - ", state)
	_state = state

# Init ball scene and attach it to the paddle
# The ball will be detached when the game begins with SPACE press
func init_ball_on_paddle():
	ball = ball_scene.instantiate()
	ball.position = position + BALL_OFFSET
	ball.top_level = true
	add_child(ball)

# Draw paddle using tiles
func init_paddle():
	# draw 3 tiles from atlas coords PADDLE_*_COORDS
	tile_map.set_cell(0, Vector2i(0, 0), 0, PADDLE_LEFT_COORDS)
	tile_map.set_cell(0, Vector2i(1, 0), 1, PADDLE_MIDDLE_CORRDS)
	tile_map.set_cell(0, Vector2i(2, 0), 0, PADDLE_RIGHT_COORDS)
	setup_paddle_collision()

# Setup paddle's collision shape
func setup_paddle_collision():
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

	init_ball_on_paddle()

func disable_powerup(powerup_timer: Timer):
	print("stopping powerup timer")
	# Globals.is_powerup_enabled = false
	Globals.deactivate_powerup()
	powerup_timer.queue_free()

func enable_powerup(powerup_type: int):
	# init and start powerup timer
	# while timer is on, the powerup is active, no other powerups are
	# getting released
	var powerup_timer = Timer.new()
	get_tree().get_root().add_child(powerup_timer)
	powerup_timer.connect("timeout", disable_powerup.bind(powerup_timer))
	powerup_timer.start(30)

	# Globals.is_powerup_enabled = true
	Globals.activate_powerup(powerup_type)
