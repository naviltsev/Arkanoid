TODO
====

CURRENT
-------
- mech - allow simultaneous power ups (eg. bottom wall + 3x balls)
- mech - timer (~5 seconds) between current power up ends and new releases

- bug - if power-up gets caught when ball is out of screen, get_ball() returns NULL


PAST
----
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