extends Node

# --- SIGNALS ---
signal progress_updated(current_progress: float, max_progress: float)
signal attack_mitigated()
signal system_compromised()

# --- ENUMS & EXPORTS ---
enum ChallengeType {
	SCRAMBLE_ONE_WORD,
	SCRAMBLE_TWO_WORDS,
	CUSTOM_RULE,
	ANAGRAM
}

@export_group("Audio & Deception")
@export var game_controller: Node # Drag your GameController node here in the Inspector
@export var deceptive_beep_chance: float = 0.3 # 30% chance to play an error sound on a SUCCESSFUL input

@export_group("UI Node Reference")
@export var terminal_display: TextEdit # Assign your TextEdit node in the Inspector

@export_group("Progress & Defense Parameters")
@export var max_mitigation_points: float = 100.0
@export var points_per_success: float = 15.0
@export var points_lost_on_error: float = 10.0

@export_group("Difficulty Progression")
@export var medium_difficulty_threshold_pct: float = 33.0 # Unlocks medium challenges at 33%
@export var hard_difficulty_threshold_pct: float = 66.0 # Unlocks hard challenges at 66%

# Assign a difficulty integer to each challenge type (1 = Easy, 2 = Medium, 3 = Hard)
var challenge_difficulty_map: Dictionary = {
	ChallengeType.SCRAMBLE_ONE_WORD: 1,
	ChallengeType.SCRAMBLE_TWO_WORDS: 2,
	ChallengeType.ANAGRAM: 2,
	ChallengeType.CUSTOM_RULE: 3
}

@export_group("Sabotage Configuration")
@export var is_second_half: bool = false
@export var second_half_threshold_pct: float = 50.0

# Two-way key swaps for the second half
@export var key_swap_map: Dictionary = {
	"e": "a",
	"a": "e",
	"i": "o",
	"o": "i",
	"t": "r",
	"r": "t"
}

@export_group("Data File Paths")
@export_file("*.txt") var custom_rules_file: String = "res://data/custom_rules.txt"
@export_file("*.txt") var scramble_one_file: String = "res://data/scramble_one.txt"
@export_file("*.txt") var scramble_two_file: String = "res://data/scramble_two.txt"
@export_file("*.txt") var anagrams_file: String = "res://data/anagrams.txt"

# --- STATE VARIABLES ---
var current_mitigation: float = 0.0
var current_challenge_type: ChallengeType
var current_prompt_text: String = ""
var expected_answer: String = ""
var simulated_input: String = ""
var is_game_active: bool = true

# Terminal Output History Buffer
var terminal_history: String = ""

# Loaded data pools
var pool_custom_rules: Array[Dictionary] = []
var pool_scramble_one: Array[String] = []
var pool_scramble_two: Array[String] = []
var pool_anagrams: Array[String] = []

func _ready() -> void:
	if terminal_display:
		terminal_display.editable = false 
		terminal_display.selecting_enabled = false
		terminal_display.context_menu_enabled = false
		
		# --- NEW FIX: Prevent TextEdit from stealing inputs ---
		terminal_display.focus_mode = Control.FOCUS_NONE
		terminal_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		terminal_display.scroll_past_end_of_file = false
	
	load_all_data_files()
	
	terminal_log("=================================================================")
	terminal_log(" [SYSTEM ALERT]: INTRUSION DETECTED. INITIATING COUNTERMEASURES  ")
	terminal_log("=================================================================")
	
	generate_new_challenge()
	
# --- TERMINAL UI LOGGING ---
func terminal_log(text: String) -> void:
	terminal_history += text + "\n"
	render_terminal()

func render_terminal() -> void:
	if not terminal_display:
		return
		
	var progress_pct = (current_mitigation / max_mitigation_points) * 100.0
	var status_bar = "[DEFENSE: %.1f%%]" % progress_pct
	
	if is_game_active:
		terminal_display.text = terminal_history + "\n" + status_bar + "\n" + current_prompt_text + "\n> " + simulated_input
	else:
		terminal_display.text = terminal_history
		
	# --- FIX: Mathematically pin the view to the bottom ---
	var total_lines = terminal_display.get_line_count()
	var visible_lines = terminal_display.get_visible_line_count()
	
	# Scroll down just enough to show the bottom lines
	var target_scroll = total_lines - visible_lines
	if target_scroll < 0:
		target_scroll = 0
		
	terminal_display.scroll_vertical = target_scroll
		
	
# --- FILE LOADING ---
func load_all_data_files() -> void:
	pool_custom_rules = load_key_value_file(custom_rules_file)
	pool_scramble_one = load_line_by_line_file(scramble_one_file)
	pool_scramble_two = load_line_by_line_file(scramble_two_file)
	pool_anagrams = load_line_by_line_file(anagrams_file)
	
	terminal_log("[SYSTEM]: Loaded %d custom rules, %d single words, %d dual words, %d anagrams." % [
		pool_custom_rules.size(),
		pool_scramble_one.size(),
		pool_scramble_two.size(),
		pool_anagrams.size()
	])

func load_line_by_line_file(path: String) -> Array[String]:
	var result: Array[String] = []
	if not FileAccess.file_exists(path):
		push_warning("File not found: " + path)
		return result
		
	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "" and not line.begins_with("#"):
			result.append(line)
	file.close()
	return result

func load_key_value_file(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not FileAccess.file_exists(path):
		push_warning("File not found: " + path)
		return result
		
	var file = FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "" and not line.begins_with("#") and line.contains("|"):
			var parts = line.split("|")
			result.append({
				"prompt": parts[0].strip_edges(),
				"answer": parts[1].strip_edges()
			})
	file.close()
	return result

# --- INPUT HANDLING ---
func _unhandled_input(event: InputEvent) -> void:
	if not is_game_active:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			var submitted = simulated_input.strip_edges().to_lower()
			terminal_history += "\n" + current_prompt_text + "\n> " + simulated_input
			simulated_input = ""
			verify_cipher(submitted)
		elif event.keycode == KEY_BACKSPACE:
			if simulated_input.length() > 0:
				simulated_input = simulated_input.left(-1)
				_on_simulated_text_changed()
		elif event.unicode != 0 and event.unicode >= 32: # Printable ASCII / characters
			var typed_char = String.chr(event.unicode)
			typed_char = apply_bidirectional_swap(typed_char)
			simulated_input += typed_char
			_on_simulated_text_changed()

func apply_bidirectional_swap(char_in: String) -> String:
	var current_pct = (current_mitigation / max_mitigation_points) * 100.0
	if not is_second_half and current_pct < second_half_threshold_pct:
		return char_in
		
	var lower_char = char_in.to_lower()
	if key_swap_map.has(lower_char):
		return key_swap_map[lower_char]
		
	return char_in

func _on_simulated_text_changed() -> void:
	trigger_display_scramble()
	render_terminal()

# --- CHALLENGE GENERATION ---
func generate_new_challenge() -> void:
	# Calculate current defense progress as a percentage
	var progress_pct = (current_mitigation / max_mitigation_points) * 100.0
	
	# Determine the max allowed difficulty based on progress
	var max_allowed_difficulty = 1
	if progress_pct >= hard_difficulty_threshold_pct:
		max_allowed_difficulty = 3
	elif progress_pct >= medium_difficulty_threshold_pct:
		max_allowed_difficulty = 2
		
	var available_types: Array[ChallengeType] = []
	
	# Only add challenge types if they are loaded AND their difficulty is within the allowed limit
	if pool_scramble_one.size() > 0 and challenge_difficulty_map[ChallengeType.SCRAMBLE_ONE_WORD] <= max_allowed_difficulty:
		available_types.append(ChallengeType.SCRAMBLE_ONE_WORD)
		
	if pool_scramble_two.size() > 0 and challenge_difficulty_map[ChallengeType.SCRAMBLE_TWO_WORDS] <= max_allowed_difficulty:
		available_types.append(ChallengeType.SCRAMBLE_TWO_WORDS)
		
	if pool_anagrams.size() > 0 and challenge_difficulty_map[ChallengeType.ANAGRAM] <= max_allowed_difficulty:
		available_types.append(ChallengeType.ANAGRAM)
		
	if pool_custom_rules.size() > 0 and challenge_difficulty_map[ChallengeType.CUSTOM_RULE] <= max_allowed_difficulty:
		available_types.append(ChallengeType.CUSTOM_RULE)
	
	# Fallback: If no types are available (e.g., text files are missing), force add whatever is loaded
	if available_types.is_empty():
		if pool_scramble_one.size() > 0: available_types.append(ChallengeType.SCRAMBLE_ONE_WORD)
		elif pool_custom_rules.size() > 0: available_types.append(ChallengeType.CUSTOM_RULE)
		else:
			terminal_log("[ERROR]: Critical failure. No data pools loaded.")
			return
			
	current_challenge_type = available_types.pick_random()
	
	# Generate the specific challenge based on the chosen type
	match current_challenge_type:
		ChallengeType.SCRAMBLE_ONE_WORD:
			expected_answer = pool_scramble_one.pick_random()
			current_prompt_text = "[PATCH TARGET]: " + expected_answer
			
		ChallengeType.SCRAMBLE_TWO_WORDS:
			expected_answer = pool_scramble_two.pick_random()
			current_prompt_text = "[ISOLATE]: " + expected_answer
			
		ChallengeType.CUSTOM_RULE:
			var rule = pool_custom_rules.pick_random()
			current_prompt_text = "[RULE]: " + rule["prompt"]
			expected_answer = rule["answer"]
				
		ChallengeType.ANAGRAM:
			var base_word = pool_anagrams.pick_random()
			expected_answer = base_word
			current_prompt_text = "[DECRYPT ANAGRAM]: " + scramble_string(base_word)
			
	render_terminal()
	
# --- DISPLAY MUTATION ---
func trigger_display_scramble() -> void:
	if current_challenge_type in [ChallengeType.SCRAMBLE_ONE_WORD, ChallengeType.SCRAMBLE_TWO_WORDS]:
		if randf() > 0.90: # 25% chance per keystroke to alter prompt
			var char_index = randi() % expected_answer.length()
			if expected_answer[char_index] != " ":
				var random_char = String.chr(randi_range(97, 122))
				var char_array = expected_answer.split("")
				char_array[char_index] = random_char
				expected_answer = "".join(char_array)
				
				if current_challenge_type == ChallengeType.SCRAMBLE_ONE_WORD:
					current_prompt_text = "[PATCH TARGET]: " + expected_answer
				else:
					current_prompt_text = "[ISOLATE]: " + expected_answer

func scramble_string(word: String) -> String:
	var chars = word.split("")
	var scrambled = ""
	while chars.size() > 0:
		var index = randi() % chars.size()
		scrambled += chars[index]
		chars.remove_at(index)
	return scrambled

# --- VERIFICATION & PROGRESSION ---
func verify_cipher(player_input: String) -> void:
	var is_correct = false
	
	if current_challenge_type == ChallengeType.ANAGRAM:
		is_correct = verify_anagram(player_input, expected_answer)
	else:
		is_correct = (player_input == expected_answer)
		
	if is_correct:
		current_mitigation = min(current_mitigation + points_per_success, max_mitigation_points)
		progress_updated.emit(current_mitigation, max_mitigation_points)
		terminal_log("\n[STATUS: SUCCESS] Packet neutralized. Defense elevated.")
		
		# --- AUDIO MECHANIC: Correct Answer ---
		if game_controller and game_controller.has_method("playAudio"):
			if randf() <= deceptive_beep_chance:
				# Deceive the player! Play the error sound even though they were right
				game_controller.playAudio("beep")
			else:
				game_controller.playAudio("success")
		
		if current_mitigation >= max_mitigation_points:
			complete_defense_sequence()
			return
			
		generate_new_challenge()
	else:
		current_mitigation = max(current_mitigation - points_lost_on_error, 0.0)
		progress_updated.emit(current_mitigation, max_mitigation_points)
		terminal_log("\n[STATUS: BREACH] Command syntax rejected! Integrity penalized (-%.0f pts). Target was: %s" % [points_lost_on_error, expected_answer])
		
		# --- AUDIO MECHANIC: Wrong Answer ---
		if game_controller and game_controller.has_method("playAudio"):
			game_controller.playAudio("beep")
			
		generate_new_challenge()
		
func verify_anagram(input_str: String, target_str: String) -> bool:
	if input_str.length() != target_str.length(): return false
	var input_arr = input_str.split("")
	var target_arr = target_str.split("")
	input_arr.sort()
	target_arr.sort()
	return input_arr == target_arr

func complete_defense_sequence() -> void:
	is_game_active = false
	attack_mitigated.emit()
	terminal_log("\n=================================================================")
	terminal_log(" [SUCCESS]: INTRUSION VECTOR FULLY NEUTRALIZED.                 ")
	terminal_log(" [STATUS]: SYSTEM INTEGRITY RESTORED TO 100.0%.                  ")
	terminal_log(" [LOG]: ALL MALICIOUS DAEMONS QUARANTINED. THREAT DEFENDED.     ")
	terminal_log("=================================================================")
	render_terminal()
