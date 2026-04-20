class_name Fx
extends RefCounted

## Fx — Reusable juice effects for any Control node.
##
## All methods are static so callers never need an Fx instance.
## Usage:
##   Fx.pop_scale(my_button)
##   Fx.slide_in(panel, Vector2(0, 40))
##   var shimmer := Fx.gold_shimmer(title_label)


## Spring scale: pops to target_scale then settles back to 1.0.
## Rapid consecutive calls on the same node no longer stack — any in-flight
## pop_scale tween is killed before the new one starts.
static func pop_scale(node: Control, target_scale: float = 1.15, duration: float = 0.3) -> void:
	if node.has_meta("_fx_pop_tween"):
		var prior: Variant = node.get_meta("_fx_pop_tween")
		if prior is Tween and (prior as Tween).is_valid():
			(prior as Tween).kill()
			node.scale = Vector2.ONE
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", Vector2(target_scale, target_scale), duration * 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.7) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	node.set_meta("_fx_pop_tween", tween)


## Slide in from an offset relative to current position, fading in simultaneously.
## Reads node.position BEFORE calling — call after the node is laid out in the tree.
static func slide_in(node: Control, from_offset: Vector2, duration: float = 0.4) -> void:
	var target_pos: Vector2 = node.position
	node.position = target_pos + from_offset
	node.modulate.a = 0.0
	var tween: Tween = node.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", target_pos, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(node, "modulate:a", 1.0, duration * 0.6)


## Count-up number animation on a Label from from_val to to_val over duration.
static func count_to(label: Label, from_val: int, to_val: int, duration: float = 0.5) -> void:
	var tween: Tween = label.create_tween()
	tween.tween_method(func(val: float) -> void:
		label.text = str(int(val))
	, float(from_val), float(to_val), duration)


## Flash the node's modulate to color then back to WHITE over duration.
static func flash(node: Control, color: Color = Color.WHITE, duration: float = 0.15) -> void:
	node.modulate = color
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", Color.WHITE, duration)


## Stagger-animate direct Control children sliding up and fading in.
## Delay between each child is delay_per seconds; vertical slide offset is from_y px.
static func stagger_children(container: Control, delay_per: float = 0.05, from_y: float = 20.0) -> void:
	var i: int = 0
	for child: Node in container.get_children():
		if child is Control:
			var ctrl: Control = child as Control
			var target_y: float = ctrl.position.y
			ctrl.position.y += from_y
			ctrl.modulate.a = 0.0
			var tween: Tween = ctrl.create_tween()
			tween.set_parallel(true)
			tween.tween_property(ctrl, "position:y", target_y, 0.3) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK) \
				.set_delay(i * delay_per)
			tween.tween_property(ctrl, "modulate:a", 1.0, 0.2) \
				.set_delay(i * delay_per)
			i += 1


## Gold shimmer: oscillates a Control's modulate between bright and warm gold
## on a loop. Works with Label, Button, or any Control that responds to
## modulate. Returns the Tween so callers can stop it with tween.kill().
static func gold_shimmer(target: Control, duration: float = 2.0) -> Tween:
	var tween: Tween = target.create_tween().set_loops()
	tween.tween_property(target, "modulate", Color(1.2, 1.1, 0.9, 1.0), duration * 0.5) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "modulate", Color(1.0, 0.95, 0.85, 1.0), duration * 0.5) \
		.set_ease(Tween.EASE_IN_OUT)
	return tween


## Screen shake: rapid jitter with exponential decay.
## node is typically the root Control of the scene.
## Overlapping shakes are coalesced — the new shake replaces the old one
## and restores the original position before starting.
static func shake(node: Control, intensity: float = 6.0, duration: float = 0.3) -> void:
	if node.has_meta("_fx_shake_tween"):
		var prior: Variant = node.get_meta("_fx_shake_tween")
		if prior is Tween and (prior as Tween).is_valid():
			(prior as Tween).kill()
			if node.has_meta("_fx_shake_origin"):
				var orig: Variant = node.get_meta("_fx_shake_origin")
				if orig is Vector2:
					node.position = orig
	var original_pos: Vector2 = node.position
	node.set_meta("_fx_shake_origin", original_pos)
	var tween: Tween = node.create_tween()
	node.set_meta("_fx_shake_tween", tween)
	var steps: int = int(duration / 0.03)
	var current_intensity: float = intensity
	for _s: int in range(steps):
		var offset: Vector2 = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		current_intensity *= 0.85
		tween.tween_property(node, "position", original_pos + offset, 0.03)
	tween.tween_property(node, "position", original_pos, 0.05)


## Scale-pulse a node: 1.0 → peak → 1.0 (one shot, good for number reveals).
## Overlapping pulses are coalesced — the new pulse replaces any in-flight one.
static func pulse(node: Control, peak: float = 1.2, duration: float = 0.4) -> void:
	if node.has_meta("_fx_pulse_tween"):
		var prior: Variant = node.get_meta("_fx_pulse_tween")
		if prior is Tween and (prior as Tween).is_valid():
			(prior as Tween).kill()
			node.scale = Vector2.ONE
	var tween: Tween = node.create_tween()
	node.set_meta("_fx_pulse_tween", tween)
	tween.tween_property(node, "scale", Vector2(peak, peak), duration * 0.35) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(node, "scale", Vector2.ONE, duration * 0.65) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


## Dim a node to target_alpha over duration (good for defeat vignette).
static func dim(node: Control, target_alpha: float = 0.6, duration: float = 0.8) -> void:
	var tween: Tween = node.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "modulate:a", target_alpha, duration)
