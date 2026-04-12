class_name JsonLoader
extends RefCounted

## JsonLoader — Shared JSON file loading utility.
##
## Centralizes the load-file / check-null / parse / error pattern used by
## every data-driven system (BlessingSystem, ExplorationSystem, StoryFlow,
## HandEvaluator, ScoreCalculator, CompanionRegistry, etc.). Keeps error
## messages consistent and reduces duplication.
##
## All methods are static — no instantiation needed.
##
## ── Layer Classification ──
## JsonLoader is a FOUNDATION-level stateless utility (like Godot's JSON
## or FileAccess). It has no mutable state, no dependencies on other
## project modules, and is safe for any layer to call — including
## autoloads. It lives in src/systems/ for file organization only;
## the classification follows ADR-0006's "stateless utility classes are
## foundation-level regardless of directory" rule (see also: CompanionState,
## Fx, UIConstants).

# ── Public API ─────────────────────────────────────────────────────────────────

## Loads a JSON file expected to contain a top-level Dictionary.
## Returns the parsed Dictionary on success, empty Dictionary on any failure.
## Errors are logged via push_warning — caller decides how to respond.
static func load_dict(path: String) -> Dictionary:
	var parsed: Variant = _load_raw(path)
	if parsed == null:
		return {}
	if not parsed is Dictionary:
		push_warning("[JsonLoader] Expected top-level Dictionary in %s, got %s" % [path, typeof(parsed)])
		return {}
	return parsed as Dictionary


## Loads a JSON file expected to contain a top-level Array.
## Returns the parsed Array on success, empty Array on any failure.
static func load_array(path: String) -> Array:
	var parsed: Variant = _load_raw(path)
	if parsed == null:
		return []
	if not parsed is Array:
		push_warning("[JsonLoader] Expected top-level Array in %s, got %s" % [path, typeof(parsed)])
		return []
	return parsed as Array


# ── Private ────────────────────────────────────────────────────────────────────

## Returns the parsed JSON value, or null on any failure (logs warning).
static func _load_raw(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("[JsonLoader] File not found: %s" % path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[JsonLoader] Failed to open: %s" % path)
		return null
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_warning("[JsonLoader] Failed to parse JSON: %s" % path)
		return null
	return parsed
