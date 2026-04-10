class_name SettingsStoreTest
extends GdUnitTestSuite

const SettingsStoreScript = preload("res://src/autoloads/settings_store.gd")

func _make_store() -> Node:
	var store := SettingsStoreScript.new()
	return store

# AC1: defaults
func test_settings_store_default_locale_is_en() -> void:
	var store := _make_store()
	assert_str(store.get_locale()).is_equal("en")

func test_settings_store_default_master_volume_is_one() -> void:
	var store := _make_store()
	assert_float(store.get_master_volume()).is_equal(1.0)

func test_settings_store_default_sfx_volume_is_one() -> void:
	var store := _make_store()
	assert_float(store.get_sfx_volume()).is_equal(1.0)

func test_settings_store_default_music_volume_is_one() -> void:
	var store := _make_store()
	assert_float(store.get_music_volume()).is_equal(1.0)

func test_settings_store_default_text_speed_is_one() -> void:
	var store := _make_store()
	assert_float(store.get_text_speed()).is_equal(1.0)

# AC2: set_locale sets value and dirty
func test_settings_store_set_locale_updates_value() -> void:
	var store := _make_store()
	store.set_locale("es")
	assert_str(store.get_locale()).is_equal("es")

func test_settings_store_set_locale_sets_dirty() -> void:
	var store := _make_store()
	store.set_locale("es")
	assert_bool(store._dirty).is_true()

# AC3: to_dict contains all fields
func test_settings_store_to_dict_contains_locale() -> void:
	var store := _make_store()
	store.set_locale("es")
	var d := store.to_dict()
	assert_str(d.get("locale", "")).is_equal("es")

func test_settings_store_to_dict_contains_all_keys() -> void:
	var store := _make_store()
	var d := store.to_dict()
	for key in ["locale", "master_volume", "sfx_volume", "music_volume", "text_speed"]:
		assert_bool(d.has(key)).is_true()

# AC4: from_dict restores locale
func test_settings_store_from_dict_restores_locale() -> void:
	var store := _make_store()
	store.from_dict({"locale": "es"})
	assert_str(store.get_locale()).is_equal("es")

# AC5: dirty flag + save_pending after setter
func test_settings_store_set_locale_sets_save_pending() -> void:
	var store := _make_store()
	store.set_locale("es")
	assert_bool(store._save_pending).is_true()

# Edge: from_dict does not set dirty
func test_settings_store_from_dict_does_not_set_dirty() -> void:
	var store := _make_store()
	store.from_dict({"locale": "es"})
	assert_bool(store._dirty).is_false()

# Edge: from_dict with missing keys uses defaults
func test_settings_store_from_dict_missing_keys_use_defaults() -> void:
	var store := _make_store()
	store.from_dict({})
	assert_str(store.get_locale()).is_equal("en")
	assert_float(store.get_master_volume()).is_equal(1.0)

# Edge: volume clamping
func test_settings_store_volume_clamped_to_max() -> void:
	var store := _make_store()
	store.set_master_volume(2.0)
	assert_float(store.get_master_volume()).is_equal(1.0)

func test_settings_store_volume_clamped_to_min() -> void:
	var store := _make_store()
	store.set_sfx_volume(-0.5)
	assert_float(store.get_sfx_volume()).is_equal(0.0)
