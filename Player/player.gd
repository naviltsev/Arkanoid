extends CharacterBody2D

@onready var tile_map : TileMap = %TileMap
@onready var collision_shape : CollisionShape2D = %CollisionShape

var ball_scene = preload("res://Balls/ball.tscn")

# A reference to an instantiated ball scene
var ball

# Ball coords in relation to paddle coords
# Effectively, this is a ball cordinates in paddle coord system
var ball_paddle_diff

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

# Ball offset relative to paddle position (places the ball in the center of the paddle)
var BALL_OFFSET = Vector2(64, 10)

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

# Restart the paddle by placing it in the middle of the screen
# with the ball attached
func restart():
	set_state(STATE_BALL_ATTACHED)

	if ball:
		ball.queue_free()

	ball_paddle_diff = BALL_OFFSET
	init_ball_on_paddle()

