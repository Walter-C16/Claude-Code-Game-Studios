class_name StoryFlow

# ---------------------------------------------------------------------------
# Prologue steps (3 steps → hub)
# ---------------------------------------------------------------------------

enum Step { PROLOGUE, SCENE1_FOREST, SCENE1_COMBAT, COMPLETED }

static var current_step: int = Step.PROLOGUE
static var active: bool = false

static func start_intro() -> void:
	active = true
	current_step = Step.PROLOGUE
	# Start with backstory cinematic dialogue
	DialogueRunner.start_dialogue("prologue", "start")
	SceneManager.change_scene(SceneManager.SceneId.DIALOGUE)

static func advance_step() -> void:
	match current_step:
		Step.PROLOGUE:
			# Backstory done → forest crash combat (meet Artemis)
			current_step = Step.SCENE1_FOREST
			GameStore.set_met("artemisa", true)
			# Init tutorial combat
			var enemy := CombatSystem.create_enemy("ENEMY_FOREST_MONSTER", 40)
			var deck := CombatSystem.create_standard_deck()
			CombatStore.init_combat(enemy, "artemisa", deck)
			SceneManager.change_scene(SceneManager.SceneId.COMBAT)

		Step.SCENE1_FOREST:
			# Tutorial combat won → go to hub
			current_step = Step.SCENE1_COMBAT
			advance_step()  # Immediately advance to completion

		Step.SCENE1_COMBAT:
			# Set flags and go to hub
			current_step = Step.COMPLETED
			active = false
			GameStore.set_flag("prologue_complete")
			GameStore.set_flag("chapter_prologue_done")
			GameStore.add_gold(50)  # TODO: read from data config
			GameStore.add_xp(25)    # TODO: read from data config
			SceneManager.change_scene(SceneManager.SceneId.HUB)

		Step.COMPLETED:
			push_warning("[StoryFlow] advance_step called after flow completed.")

static func is_intro_complete() -> bool:
	return GameStore.has_flag("prologue_complete")
