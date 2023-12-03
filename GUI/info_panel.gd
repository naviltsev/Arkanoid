extends Node2D

# VBox container where powerup container is going to be instantiated
@onready var bottom_container : VBoxContainer = $PanelContainer/MarginContainer/VBoxContainerBottom

# powerup container scene
var powerup_container_scene = preload("res://GUI/h_box_powerup_container.tscn")

# a base name of powerup container
const POWERUP_CONTAINER_NAME = "HBoxPowerupContainer"

func _ready():
	Events.connect("enable_powerup", enable_powerup)
	Events.connect("disable_powerup", disable_powerup)

func enable_powerup(powerup_type: int):
	# no need to instantiate a UI for Clear Level powerup
	# as such power-up would immediately proceed to the next level
	if powerup_type == Globals.POWERUP_CLEAR_LEVEL:
		return

	var powerup_container = powerup_container_scene.instantiate()
	
	# set power-up type of new power-up container as metadata
	# powerup_type metadata is used by power-up container instances
	# in order to react to signals related to particular power-up
	powerup_container.set_meta("powerup_type", powerup_type)

	powerup_container.name = POWERUP_CONTAINER_NAME + str(powerup_type)
	bottom_container.add_child(powerup_container)
	
	# send signal to powerup_icon.gd to display icon
	Events.info_panel_powerup_icon_display.emit(powerup_type)
	
	# ... and to powerup_timer_progress_bar to display timer progressbar
	Events.info_panel_powerup_timer_init.emit(powerup_type)

func disable_powerup(powerup_type: int):
	var powerup_container = bottom_container.get_node(POWERUP_CONTAINER_NAME + str(powerup_type))
	if !powerup_container:
		return
	powerup_container.queue_free()
