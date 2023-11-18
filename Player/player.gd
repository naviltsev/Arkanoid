extends CharacterBody2D

var ball_scene = preload("res://Balls/ball.tscn")

@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var collision_shape : CollisionShape2D = $CollisionShape

# Ball coords in relation to paddle coords
# Effectively, this is a ball cordinates in paddle coord system
var ball_paddle_diff

# Paddle init position
var PADDLE_INIT_POSITION = Vector2(832, 1008)

# Ball offset relative to paddle position (places the ball in the center of the paddle)
var BALL_OFFSET = Vector2(0, -32)

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

	_connect_signals()
	restart()

func _connect_signals():
	Events.connect("ball_attaches_to_paddle", attach_ball_to_paddle)
	Events.connect("ball_out_of_screen", restart)
	Events.connect("heavy_ball_equipped", switch_to_heavy_ball)
	Events.connect("heavy_ball_dismantled", switch_to_regular_ball)
	Events.connect("multiple_balls_equipped", switch_to_multiple_balls)
	Events.connect("wide_paddle_equipped", switch_to_wide_paddle)
	Events.connect("wide_paddle_dismantled", switch_to_regular_paddle)

func _physics_process(delta):
	motion.x = Input.get_axis("ui_left", "ui_right")

	move_and_collide(motion * SPEED * delta)
	
	# move ball along with the paddle
	if _state == STATE_BALL_ATTACHED:
		get_ball().position.x = position.x + ball_paddle_diff.x

	if Input.is_action_just_pressed("ui_accept"):
		set_state(STATE_BALL_DETACHED)
		get_ball().launch(Vector2.ZERO)

	if Input.is_action_just_pressed("ui_down"):
		switch_to_wide_paddle()

	if Input.is_action_just_pressed("ui_up"):
		switch_to_regular_paddle()


func set_state(state: int):
	_state = state

func get_ball():
	return get_tree().get_nodes_in_group("balls")[0]

# Init ball scene and attach it to the paddle
# The ball will be detached when the game begins with SPACE press
func init_ball_on_paddle() -> void:
	var ball = ball_scene.instantiate()
	ball.position = position + ball_paddle_diff
	add_child(ball)

func attach_ball_to_paddle(coords: Vector2) -> void:
	set_state(STATE_BALL_ATTACHED)
	ball_paddle_diff.x = coords.x - position.x

	var ball = get_ball()

	# fix ball's Y position so that ball doesn't get stuck in the paddle
	if ball.position.y != position.y + BALL_OFFSET.y:
		ball.position.y = position.y + BALL_OFFSET.y

# Ball is reported as below the paddle if ball.Y coordinate at collision time is below
# ball's idle position on the paddle (which is essentially 966px)
func is_ball_above_paddle() -> bool:
	if (get_ball().position.y - 2) <= (PADDLE_INIT_POSITION.y + BALL_OFFSET.y):
		return true
	return false

# Restart the paddle by placing it in the middle of the screen
# with the ball attached
func restart():
	set_state(STATE_BALL_ATTACHED)

	ball_paddle_diff = BALL_OFFSET
	init_ball_on_paddle()

	# deactivate power-up
	Globals.disable_powerup(null)

# replaces ball sprite to heavy ball
func switch_to_heavy_ball():
	get_ball().switch_to_heavy_ball()

# replaces ball sprite to regular ball
func switch_to_regular_ball():
	get_ball().switch_to_regular_ball()

# adds 2 extra balls upon POWERUP_MULTIPLE_BALLS
# TODO set position of extra balls based on whether the main ball is close to screen edge
# TODO so that an extra ball doesn't appear inside the wall or something
func switch_to_multiple_balls():
	var ball = get_ball()

	var extra_ball_1 = ball_scene.instantiate()
	extra_ball_1.position = ball.position + Vector2(25, 0)
	var extra_ball_2 = ball_scene.instantiate()
	extra_ball_2.position = ball.position + Vector2(-25, 0)

	add_child(extra_ball_1)
	add_child(extra_ball_2)

	extra_ball_1.launch(Vector2(1, -2).normalized())
	extra_ball_2.launch(Vector2(-1, -2).normalized())

# turns on wide paddle as a result of POWERUP_WIDE_PADDLE
func switch_to_wide_paddle():
	collision_shape.shape.set_height(192)
	animation_player.play("switch_to_wide_paddle")

	# shift paddle to the safe place if it's too close to the wall
	if position.x <= 145:
		position.x = 145
	if position.x >= 1440:
		position.x = 1440

func switch_to_regular_paddle():
	collision_shape.shape.set_height(128)
	animation_player.play("switch_to_regular_paddle")
