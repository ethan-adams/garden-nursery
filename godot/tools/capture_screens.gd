extends SceneTree

# Headless-ish screenshot capture for ship evidence (issue #98, Tier 2).
#
# `--headless` has no renderer, so this runs with a real GL context: on CI (Linux) under
# `xvfb-run --rendering-driver opengl3`, locally on a Mac/desktop with a window. It loads
# the REAL yard scene and drives the overlay exactly as gameplay does (the stand lives on
# a CanvasLayer, so a screen-space capture matches what the player sees), renders each
# key state at the 1280x800 Steam Deck target, and saves PNGs.
#
# Output dir is the first user arg after `--`; defaults to `res://tools/_screens`.
# Wrapped by `npm run godot:screens`.

const YardScene = preload("res://scenes/nursery/nursery_yard.tscn")
const SAVE_PATH := "user://garden_nursery_vertical_slice_save.json"
const DECK_SIZE := Vector2i(1280, 800)

func _initialize() -> void:
	_run()

func _run() -> void:
	var out_dir := "res://tools/_screens"
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 0 and not String(user_args[0]).is_empty():
		out_dir = String(user_args[0])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir) if out_dir.begins_with("res://") else out_dir)

	# Start every capture run from a fresh week so the shots are deterministic.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	root.size = DECK_SIZE
	var yard := YardScene.instantiate()
	root.add_child(yard)
	await _settle(4)

	# 1. The walkable yard — the first screen the player sees.
	await _capture(out_dir, "01-yard")

	var stand := yard.get_node_or_null("StationOverlay/NurseryStand")
	if stand == null:
		push_error("capture: StationOverlay/NurseryStand not found in the yard scene")
		quit(1)
		return

	# 2. The plant stand overlay, fully open.
	stand.open_station("all")
	await _settle(4)
	await _capture(out_dir, "02-stand-open")

	# 3. Scroll-follows-focus made visible: focus the last (off-panel) inventory item and
	# show it pulled into view.
	var inventory_list: Node = stand.inventory_list
	var count := inventory_list.get_child_count()
	if count > 0:
		var last := inventory_list.get_child(count - 1) as Control
		last.grab_focus()
		await _settle(4)
		await _capture(out_dir, "03-stand-scrolled-to-last")

	# 4. The week-outcome state after doing real work: recommend an in-stock plant, then
	# close the week.
	var rs = stand.run_state
	var plant_id := _first_in_stock_id(rs)
	if not plant_id.is_empty():
		stand._recommend_plant(plant_id)
		await _settle(2)
		stand._on_advance_week_button_pressed()
		await _settle(4)
		await _capture(out_dir, "04-week-outcome")

	quit(0)

func _first_in_stock_id(rs) -> String:
	for plant in rs.plants:
		if int(plant.get("starting_stock", 0)) > 0:
			return String(plant.get("id", ""))
	return ""

func _capture(out_dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path := "%s/%s.png" % [out_dir, name]
	var err := image.save_png(path)
	if err != OK:
		push_error("capture: failed to save %s (err %d)" % [path, err])
	else:
		print("ok - captured %s (%dx%d)" % [path, image.get_width(), image.get_height()])

func _settle(frames: int) -> void:
	for _i in range(frames):
		await process_frame
