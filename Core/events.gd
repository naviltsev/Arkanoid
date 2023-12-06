extends Node

# ball goes out of screen
signal ball_out_of_screen

# Glue power-up is active and ball hits the paddle
signal ball_attaches_to_paddle(coords: Vector2)

# player catches powerup
signal enable_powerup(powerup_type: int)

# powerup time ended
signal disable_powerup(powerup_type: int)

# heavy ball power-up has been equipped
# triggers adjustments to ball sprite and collision shape in player.gd
signal heavy_ball_equipped()

# heavy ball power-up has been dismantled
# triggers adjustments to ball sprite and collision shape in player.gd
signal heavy_ball_dismantled()

# multiple balls power-up has been equipped
signal multiple_balls_equipped()

# multiple balls power-up has been dismantled
signal multiple_balls_dismantled()

# wide paddle power-up has been equipped
signal wide_paddle_equipped()

# wide paddle power-up has been dismantled
signal wide_paddle_dismantled()

# clear level power-up
signal powerup_clear_level()

# bottom wall power-up has been equipped
signal bottom_wall_equipped()

# bottom wall power-up has been dismantled
signal bottom_wall_dismantled()

# missiles power-up has been equipped
signal missiles_equipped()

# missiles power-up has been dismantled
signal missiles_dismantled()

# stop ball
signal pause_ball()

# display power-up icon on info panel if power-up was taken
signal info_panel_powerup_icon_display(powerup_type: int)

# on power-up get caught, initialize a progress bar displaying time left
# before power-up times out
signal info_panel_powerup_timer_init(powerup_type: int)
