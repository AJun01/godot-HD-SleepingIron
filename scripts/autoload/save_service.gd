extends Node
## Minimal learning-first save service (design.md SaveService). Persists only the
## player's position (Vector3) and facing (int) as JSON under user://, so a later
## full save system can grow behind this boundary without touching its callers.
## Any load failure collapses to an empty Dictionary rather than throwing.

## JSON file the arena save/load zone reads and writes.
const SAVE_PATH: String = "user://arena_save.json"

## Dictionary keys shared with save_load_trigger.gd so neither side hardcodes
## magic strings.
const POSITION_KEY: String = "position"
const FACING_KEY: String = "facing"


func save_player_state(position: Vector3, facing: int) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: failed to open save file for writing at %s" % SAVE_PATH)
		return false
	var data: Dictionary = {
		POSITION_KEY: [position.x, position.y, position.z],
		FACING_KEY: facing,
	}
	file.store_string(JSON.stringify(data))
	return true


func load_player_state() -> Dictionary:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveService: failed to open save file for reading at %s" % SAVE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		push_error("SaveService: save file %s does not contain a JSON object" % SAVE_PATH)
		return {}
	var state: Dictionary = _decode_state(parsed)
	if state.is_empty():
		push_error("SaveService: save file %s contains invalid save data" % SAVE_PATH)
		return {}
	return state


func _decode_state(data: Dictionary) -> Dictionary:
	var raw_position: Variant = data.get(POSITION_KEY)
	var raw_facing: Variant = data.get(FACING_KEY)
	if raw_position is not Array or not _is_number(raw_facing):
		return {}
	var position_array: Array = raw_position
	if position_array.size() != 3:
		return {}
	var x: Variant = position_array[0]
	var y: Variant = position_array[1]
	var z: Variant = position_array[2]
	if not _is_number(x) or not _is_number(y) or not _is_number(z):
		return {}
	return {
		POSITION_KEY: Vector3(float(x), float(y), float(z)),
		FACING_KEY: int(raw_facing),
	}


func _is_number(value: Variant) -> bool:
	return value is int or value is float
