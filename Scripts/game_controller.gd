extends Node2D

const POP_UP = preload("uid://q2a3umx2s1ny")
@onready var os: CanvasLayer = $os

@onready var terminalWindow: TextureRect = $os/Terminal/Window

@onready var startWindow: TextureRect = $os/Start/Window

@onready var settingsWindow: TextureRect = $os/Settings/Window

@onready var readmeWindow: TextureRect = $os/Readme/Window

@onready var progressWindow: TextureRect = $os/Progress/Window

@onready var chatWindow: TextureRect = $os/Chat/Window
@onready var chat: RichTextLabel = $os/Chat/Window/chat

@onready var successAudio: AudioStreamPlayer = $sfx/Success
@onready var beepAudio: AudioStreamPlayer = $sfx/Beep
@onready var glitchAudio: AudioStreamPlayer = $sfx/Glitch
@onready var progressBar: ProgressBar = $os/Progress/Window/Progress/BreachProgress

var popUpOpen: bool = false
var windowList 
var keyList

func _ready():
	windowList = [
		terminalWindow, 
		startWindow, 
		settingsWindow, 
		settingsWindow, 
		readmeWindow, 
		progressWindow, 
		chatWindow
		]
	keyList = [$sfx/keystrokes/Key1, $sfx/keystrokes/Key2, $sfx/keystrokes/Key3, $sfx/keystrokes/Key4, $sfx/keystrokes/Key5, $sfx/keystrokes/Key6, $sfx/keystrokes/Key7]

func _process(delta: float) -> void:
	if(progressBar.value < 100):
		progressBar.value += delta * 1;
	else:
		gameOver()

func showWindow(window) -> void:
	for w in windowList:
		if(w == window):
			w.visible = true
		
func hideWindow(window) -> void:
	for w in windowList:
		if(w == window):
			w.visible = false

func playAudio(case: String):
	match case: 
		"beep":
			beepAudio.play()
			instantiatePopUp("WRONG!!!")
		"success":
			successAudio.play()
			instantiatePopUp("CORRECT!!!")
		"key":
			var i = randi_range(0, 5)
			keyList[i].play()
		"backspace":
			keyList[6].play()
		"enter":
			keyList[6].play()
		"glitch":
			glitchAudio.play()
	
func instantiatePopUp(message: String):
	popUpOpen = true
	var newPopup: Control = POP_UP.instantiate();
	os.add_child(newPopup);
	newPopup.setMessage(message)

func gameOver():
	pass

func getProgress():
	progressBar.value

func setChatVisible():
	chatWindow.visible = true
	
func getChatWindow() -> RichTextLabel:
	return chat

func addProgress(progress: float):
	progressBar.value += progress
