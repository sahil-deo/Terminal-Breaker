extends Node2D

const POP_UP = preload("uid://q2a3umx2s1ny")
@onready var os: CanvasLayer = $os

@onready var terminalWindow: TextureRect = $os/Terminal/Window
@onready var game_overWindow: TextureRect = $os/GameOver/Window
@onready var game_overCross: Button = $os/GameOver/Window/menuBar/Button
@onready var game_overMessage: Label = $os/GameOver/Window/Message
@onready var startWindow: TextureRect = $os/Start/Window
@onready var settingsWindow: TextureRect = $os/Settings/Window
@onready var readmeWindow: TextureRect = $os/Readme/Window
@onready var progressWindow: TextureRect = $os/Progress/Window
@onready var chatWindow: TextureRect = $os/Chat/Window
@onready var chat: RichTextLabel = $os/Chat/Window/chat

@onready var successAudio: AudioStreamPlayer = $sfx/Success
@onready var beepAudio: AudioStreamPlayer = $sfx/Beep
@onready var glitchAudio: AudioStreamPlayer = $sfx/Glitch
@onready var breachedAudio: AudioStreamPlayer = $sfx/Breached
@onready var pingAudio: AudioStreamPlayer = $sfx/Ping
@onready var victoryAudio: AudioStreamPlayer = $"sfx/Victory"
@onready var bgm: AudioStreamPlayer = $bgm
@onready var progressBar: ProgressBar = $os/Progress/Window/Progress/BreachProgress

var popUpOpen: bool = false
var windowList 
var keyList
var isGameOver: bool = false

func _ready():
	windowList = [
		terminalWindow, 
		startWindow, 
		settingsWindow, 
		settingsWindow, 
		readmeWindow, 
		progressWindow, 
		chatWindow,
		game_overWindow
		]
	keyList = [$sfx/keystrokes/Key1, $sfx/keystrokes/Key2, $sfx/keystrokes/Key3, $sfx/keystrokes/Key4, $sfx/keystrokes/Key5, $sfx/keystrokes/Key6, $sfx/keystrokes/Key7]

func _process(delta: float) -> void:
	if(progressBar.value > 0 and progressBar.value < 100 and not isGameOver):
		progressBar.value += delta * 1;
	elif not isGameOver:
		isGameOver = true
		gameOver()

func showWindow(window) -> void:
	if(isGameOver): return
	if(window == startWindow):
		game_overWindow.visible = true
		game_overMessage.text = "FIREWALL UNDER ATTACK!!!"
		return
	for w in windowList:
		if(w == window):
			w.visible = true
			return
		
func hideWindow(window) -> void:
	if(isGameOver): return
	for w in windowList:
		if(w == window):
			w.visible = false
			return

func playAudio(case: String):
	match case: 
		"beep":
			beepAudio.play()
		"success":
			successAudio.play()
		"key":
			var i = randi_range(0, 5)
			keyList[i].play()
		"backspace":
			keyList[6].play()
		"enter":
			keyList[6].play()
		"glitch":
			glitchAudio.play()
		"ping":
			pingAudio.play()
		"breached":
			breachedAudio.play()
		"victory":
			victoryAudio.play()
	
func instantiatePopUp(message: String):
	popUpOpen = true
	var newPopup: Control = POP_UP.instantiate();
	os.add_child(newPopup);
	newPopup.setMessage(message)

func gameOver():
	game_overCross.visible = true
	game_overWindow.visible = true
	if(progressBar.value < 10):
		game_overMessage.text = "FIREWALL SECURED!"
		playAudio("victory")
	else:
		game_overMessage.text = "FIREWALL BREACHED!"
		playAudio("breached")

func getProgress():
	return progressBar.value

func setChatVisible():
	chatWindow.visible = true

func getChatWindow() -> RichTextLabel:
	return chat

func addProgress(progress: float):
	progressBar.value += progress
	
func restartGame():
	get_tree().reload_current_scene()
	
func closeGame():
	get_tree().quit()
