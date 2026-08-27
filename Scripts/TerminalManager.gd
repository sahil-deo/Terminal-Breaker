extends Node

# --- SIGNALS ---
signal progress_updated(current_progress: float, max_progress: float)
signal attack_mitigated()
signal system_compromised()

# --- ENUMS & EXPORTS ---
enum ChallengeType {
	SCRAMBLE_ONE_WORD,
	SCRAMBLE_TWO_WORDS,
	CUSTOM_RULE
}

@export_group("UI & Audio Nodes")
@export var terminal_display: RichTextLabel
@export var game_controller: Node
@export var deceptive_beep_chance: float = 0.3

@export_group("Progress Parameters")
@export var max_mitigation_points: float = 100.0
@export var points_per_success: float = 15.0

@export_group("Terminal Cursor")
@export var cursor_char: String = "█"
@export var cursor_blink_rate: float = 0.5 # seconds per on/off toggle

# --- STATE VARIABLES ---
var current_mitigation: float = 0.0
var current_challenge_type: ChallengeType

# Prompt Tracking
var base_prompt_text: String = ""  # The original word (e.g. "firewall")
var expected_answer: String = ""   # The required answer (can shift during Gaslight)
var current_display_prompt: String = "" # What is actively shown on screen
var gaslight_triggered: bool = false

# Input Tracking
var input_buffer: Array[Dictionary] = [] # Stores { "raw": "e", "bbcode": "[color=red]a[/color]" }
var terminal_history: String = ""
var is_game_active: bool = true

# Cursor Blink State
var cursor_visible: bool = true
var cursor_blink_timer: float = 0.0

# Sabotage States
var blocked_sticky_key: String = ""

# Hacking/Networking Fallback Pools
var pool_scramble_one: Array[String] = ["firewall", "payload", "kernel", "botnet", "proxy"]
var pool_scramble_two: Array[String] = ["bypass proxy", "inject script", "flush dns", "kill thread"]
var pool_custom_rules: Array[Dictionary] = [
	{"prompt": "chmod 777 root", "answer": "chmod 777 root"},
	{"prompt": "write sys_dump x 2", "answer": "sys_dumpsys_dump"}
]

func _ready() -> void:
	if terminal_display:
		terminal_display.focus_mode = Control.FOCUS_NONE
		terminal_display.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# FIX 3: without this, RichTextLabel treats "[color=red]..." as literal
		# text instead of markup, which is why the tags were showing on screen.
		terminal_display.bbcode_enabled = true

		# FIX 1: enables autoscroll so new lines push the view down like a
		# real terminal instead of staying pinned at the top.
		terminal_display.scroll_active = true
		terminal_display.scroll_following = true

	terminal_log("=================================================================")
	terminal_log(" [SYSTEM ALERT]: UNAUTHORIZED ACCESS DETECTED. ")
	terminal_log(" [ROOT DIRECTORY]: COMPROMISED. INITIATING COUNTERMEASURES.")
	terminal_log("=================================================================")
	generate_new_challenge()

# FIX 2: drives the blinking cursor independent of keystrokes/input events.
func _process(delta: float) -> void:
	if not is_game_active:
		return

	cursor_blink_timer += delta
	if cursor_blink_timer >= cursor_blink_rate:
		cursor_blink_timer = 0.0
		cursor_visible = not cursor_visible
		render_terminal()

# --- TERMINAL UI LOGGING ---
func terminal_log(text: String) -> void:
	terminal_history += text + "\n"
	render_terminal()

func render_terminal() -> void:
	if not terminal_display: return
	
	var progress_pct = (current_mitigation / max_mitigation_points) * 100.0
	var status_bar = "[color=green][DEFENSE INTEGRITY: %.1f%%][/color]" % progress_pct
	if progress_pct < 50.0:
		status_bar = "[color=red][DEFENSE INTEGRITY: %.1f%%][/color]" % progress_pct
	elif progress_pct < 85.0:
		status_bar = "[color=yellow][DEFENSE INTEGRITY: %.1f%%][/color]" % progress_pct
	
	var bbcode_input = ""
	var raw_input = ""
	for item in input_buffer:
		bbcode_input += item["bbcode"]
		raw_input += item["raw"]
		
	# Check for memory mechanic trigger
	check_gaslight_scramble(raw_input)

	# FIX 2 (cont.): render an actual blinking cursor glyph after the typed input.
	var cursor_bbcode = "[color=white]" + cursor_char + "[/color]" if cursor_visible else " "
	
	if is_game_active:
		terminal_display.text = terminal_history + "\n" + status_bar + "\n" + current_display_prompt + "\n> " + bbcode_input + cursor_bbcode
	else:
		terminal_display.text = terminal_history
	# scroll_following (set in _ready) handles autoscroll on its own; a manual
	# scroll_to_line() call here raced against RichTextLabel's internal line-
	# cache timing and intermittently hid the newest 1-2 lines, so it's gone.

# --- INPUT PROCESSING ALGORITHM ---
func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active: return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			var submitted_raw = ""
			var submitted_bbcode = ""
			for item in input_buffer:
				submitted_raw += item["raw"]
				submitted_bbcode += item["bbcode"]
				
			terminal_history += "\n" + current_display_prompt + "\n> " + submitted_bbcode
			input_buffer.clear()
			blocked_sticky_key = "" # Reset sticky key on enter
			verify_cipher(submitted_raw.strip_edges().to_lower())
			
		elif event.keycode == KEY_BACKSPACE:
			if input_buffer.size() > 0:
				input_buffer.pop_back()
				render_terminal()
				
		elif event.unicode >= 32:
			process_psychological_sabotage(String.chr(event.unicode).to_lower())
			render_terminal()

func process_psychological_sabotage(char_in: String) -> void:
	var pct = (current_mitigation / max_mitigation_points) * 100.0
	var actual_char = char_in
	var bbcode_char = char_in
	
	# CRITICAL TIER (86%+): The Sticky Key
	if pct >= 86.0 and randf() < 0.15 and blocked_sticky_key == "":
		blocked_sticky_key = char_in
		return # Swallows the keystroke silently
	if blocked_sticky_key == char_in:
		blocked_sticky_key = "" # Key released on double-tap
		
	# HARD TIER (61%+): Vowel Swaps
	if pct >= 61.0 and char_in in ["a", "e", "i", "o", "u"]:
		var swap_map = {"a":"e", "e":"i", "i":"o", "o":"u", "u":"a"}
		actual_char = swap_map[char_in]
		bbcode_char = "[color=red]" + actual_char + "[/color]"
		
	# MEDIUM TIER (31%+): Ghost Keys (Tunnel Vision exploit)
	if pct >= 31.0 and randf() < 0.08:
		var ghost = ["-", "_", "*", "0", "1"].pick_random()
		# Inject the ghost key BEFORE the typed key to disrupt muscle memory
		input_buffer.append({"raw": ghost, "bbcode": "[color=red]" + ghost + "[/color]"})
		
	# Add the actual typed (or swapped) key
	input_buffer.append({"raw": actual_char, "bbcode": bbcode_char})

# --- GASLIGHT SCRAMBLE (Muscle Memory Exploit) ---
func check_gaslight_scramble(current_raw_input: String) -> void:
	var pct = (current_mitigation / max_mitigation_points) * 100.0
	if pct < 31.0 or gaslight_triggered or current_challenge_type == ChallengeType.CUSTOM_RULE:
		return
		
	# Trigger exactly at the halfway point of typing the base word
	if current_raw_input.length() == int(base_prompt_text.length() / 2):
		gaslight_triggered = true
		
		var chars = base_prompt_text.split("")
		var indices = range(base_prompt_text.length())
		indices.shuffle()
		
		var changes_allowed = 1 if pct < 61.0 else 2
		var changes_made = 0
		
		for i in indices:
			if chars[i] != " " and i > current_raw_input.length(): # Only mutate letters AHEAD of the cursor
				chars[i] = ["0", "1", "3", "4", "7", "x", "z"].pick_random()
				changes_made += 1
				if changes_made >= changes_allowed: break
				
		expected_answer = "".join(chars)
		current_display_prompt = "[color=red][CORRUPTED]: " + expected_answer + "[/color]"
		
		# Revert visual after 1.5s, but expected_answer stays glitched
		await get_tree().create_timer(1.5).timeout
		if is_game_active:
			current_display_prompt = "[TARGET]: " + base_prompt_text
			render_terminal()

# --- VERIFICATION & PUNISHMENT ---
func get_dynamic_penalty() -> float:
	var pct = (current_mitigation / max_mitigation_points) * 100.0
	if pct >= 86.0: return 25.0
	if pct >= 51.0: return 15.0
	return 10.0

func verify_cipher(player_input: String) -> void:
	if player_input == expected_answer:
		current_mitigation = min(current_mitigation + points_per_success, max_mitigation_points)
		terminal_log("\n[STATUS: SUCCESS] Packet neutralized.")
		
		if game_controller and game_controller.has_method("playAudio"):
			if randf() <= deceptive_beep_chance: game_controller.playAudio("beep")
			else: game_controller.playAudio("success")
			
		if current_mitigation >= max_mitigation_points:
			complete_defense_sequence()
			return
	else:
		var penalty = get_dynamic_penalty()
		current_mitigation = max(current_mitigation - penalty, 0.0)
		terminal_log("\n[STATUS: BREACH] Command syntax rejected! Integrity dropped by %.0f. Target was: %s" % [penalty, expected_answer])
		
		if game_controller and game_controller.has_method("playAudio"):
			game_controller.playAudio("beep")
			
	generate_new_challenge()

func generate_new_challenge() -> void:
	gaslight_triggered = false
	var pct = (current_mitigation / max_mitigation_points) * 100.0
	var available_types: Array[ChallengeType] = [ChallengeType.SCRAMBLE_ONE_WORD]
	
	if pct >= 31.0: available_types.append(ChallengeType.SCRAMBLE_TWO_WORDS)
	if pct >= 86.0: available_types.append(ChallengeType.CUSTOM_RULE)
		
	current_challenge_type = available_types.pick_random()
	
	match current_challenge_type:
		ChallengeType.SCRAMBLE_ONE_WORD:
			base_prompt_text = pool_scramble_one.pick_random()
			current_display_prompt = "[PATCH TARGET]: " + base_prompt_text
		ChallengeType.SCRAMBLE_TWO_WORDS:
			base_prompt_text = pool_scramble_two.pick_random()
			current_display_prompt = "[ISOLATE]: " + base_prompt_text
		ChallengeType.CUSTOM_RULE:
			var rule = pool_custom_rules.pick_random()
			base_prompt_text = rule["prompt"]
			current_display_prompt = "[OVERRIDE RULE]: " + rule["prompt"]
			
	expected_answer = base_prompt_text if current_challenge_type != ChallengeType.CUSTOM_RULE else pool_custom_rules[0]["answer"] 
	# Note: In a full build, ensure the expected answer strictly maps to the pulled custom rule dict.
	
	render_terminal()

func complete_defense_sequence() -> void:
	is_game_active = false
	attack_mitigated.emit()
	terminal_log("\n=================================================================")
	terminal_log(" [SUCCESS]: INTRUSION VECTOR FULLY NEUTRALIZED.                 ")
	terminal_log(" [LOG]: ALL MALICIOUS DAEMONS QUARANTINED. THREAT DEFENDED.     ")
	terminal_log("=================================================================")
	render_terminal()
