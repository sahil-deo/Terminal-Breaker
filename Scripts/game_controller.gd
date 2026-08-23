extends Node2D

@onready var terminalWindow: TextureRect = $os/Terminal/Window
@onready var terminalTaskbarIcon: TextureRect = $os/Terminal/TaskbarIcon

@onready var startWindow: TextureRect = $os/Start/Window
@onready var startTaskbarIcon: TextureRect = $os/Start/TaskbarIcon

@onready var settingsWindow: TextureRect = $os/Settings/Window
@onready var settinsTaskbarIcon: TextureRect = $os/Settings/TaskbarIcon

@onready var readmeWindow: TextureRect = $os/Readme/Window
@onready var readmeTaskbarIcon: TextureRect = $os/Readme/TaskbarIcon

var windowList 

func _ready():
	windowList = [terminalWindow, terminalTaskbarIcon, startWindow, startTaskbarIcon, settingsWindow, settinsTaskbarIcon, settingsWindow, settinsTaskbarIcon, readmeWindow, readmeTaskbarIcon]
	pass

func showWindow(window, icon) -> void:
	for w in windowList:
		if(w == window or w == icon):
			w.visible = true
			continue
		w.visible=false

func playAudio(case: String):
	print(case)
	
