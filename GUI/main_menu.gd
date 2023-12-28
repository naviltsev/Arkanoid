extends Node2D

#@onready var transitioner : SceneTransitioner = $Transitioner

# Called when the node enters the scene tree for the first time.
#func _ready():
#	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#	%StartButton.grab_focus()

func _on_start_button_pressed():
	Globals.start_game()
	
	# work-around - wait for 1 sec before removing main menu
	# to give scene transitioner some time to fade in
	await get_tree().create_timer(1).timeout
	queue_free()

func _on_exit_button_pressed():
	get_tree().quit()
