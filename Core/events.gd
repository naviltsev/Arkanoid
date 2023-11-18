extends Node

# ball goes out of screen
signal ball_out_of_screen

# Glue power-up is active and ball hits the paddle
signal ball_attaches_to_paddle(coords: Vector2)

# player catches powerup
signal enable_powerup(powerup_type: int)

# heavy ball power-up has been equipped
# triggers adjustments to ball sprite and collision shape in player.gd
signal heavy_ball_equipped()

# heavy ball has been dismantled
# triggers adjustments to ball sprite and collision shape in player.gd
signal heavy_ball_dismantled()

# multiple balls power-up has been equipped
signal multiple_balls_equipped()

# wide paddle power-up equipped
signal wide_paddle_equipped()
