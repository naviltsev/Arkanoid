TODO
====

CURRENT
-------


- bug - missiles are equipped if ball is out of screen and at the same time missiles powerup gets collected
- bug - if power-up gets caught when ball is out of screen, get_ball() returns NULL
  + queue_free() power up if ball is out of screen

PAST
----
+ finish double score and extra health power ups
+ mech - timer (10 seconds) between current power up ends and new releases

+ mech - allow simultaneous power ups (eg. bottom wall + 3x balls)

+ bug - add white contour in bottom wall powerup tile
+ bug fix clear level - colors of brick particles
+ enh - implement half/fully cracked coords in custom data layer of a tilemap
+ powerup - rocket
+ bug - bottom wall bugs

+ enh - explosion of bricks (Clear Level power-up) - use 1x1 brick of corresponding color as particle


+ heavy / regular ball switch - trail length bug
+ glue powerup doesn't work - bug

+ stop calculating paddle size and collision shape programmatically
	+ implement multiple scenes for each paddle type and switch between them
- save motion of ball when glue power up enabled and ball sticks to the paddle
+ ball sticks to the paddle on the sides
+ implement is_above_paddle() for correct collision detection if ball hits the side of the paddle
+ disable power up if global powerup timer is timed out

GLOBAL TASKS
- place paddle lower - ball should go off screen right below the paddle
