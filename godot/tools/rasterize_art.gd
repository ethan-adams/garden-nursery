extends SceneTree

# Rasterize the SVG art sources into the committed PNGs the scenes render.
#
# The scenes must reference imported PNG textures (see the "Art loads through the
# import pipeline" check), but the editable source of truth for each piece is its
# SVG. Whenever an SVG changes, rerun this and commit the regenerated PNG:
#
#   godot --headless --path godot -s res://tools/rasterize_art.gd
#
# Each entry rasterizes at the exact size the scene displays it, so no scene-side
# scaling blurs the art.

const TARGETS := [
	{"svg": "res://assets/art/hush-arbor-yard.svg", "png": "res://assets/art/hush-arbor-yard.png", "width": 1280.0},
	{"svg": "res://assets/art/gardener-player.svg", "png": "res://assets/art/gardener-player.png", "width": 96.0},
]


func _initialize() -> void:
	var failed := false
	for target in TARGETS:
		if not _rasterize(target["svg"], target["png"], target["width"]):
			failed = true
	quit(1 if failed else 0)


func _rasterize(svg_path: String, png_path: String, target_width: float) -> bool:
	var file := FileAccess.open(svg_path, FileAccess.READ)
	if file == null:
		push_error("rasterize: cannot read %s" % svg_path)
		return false
	var svg_text := file.get_as_text()
	var viewbox_width := _viewbox_width(svg_text)
	if viewbox_width <= 0.0:
		push_error("rasterize: no usable viewBox in %s" % svg_path)
		return false
	var image := Image.new()
	var err := image.load_svg_from_string(svg_text, target_width / viewbox_width)
	if err != OK:
		push_error("rasterize: SVG parse failed for %s (err %d)" % [svg_path, err])
		return false
	err = image.save_png(png_path)
	if err != OK:
		push_error("rasterize: cannot write %s (err %d)" % [png_path, err])
		return false
	print("ok - %s -> %s (%dx%d)" % [svg_path, png_path, image.get_width(), image.get_height()])
	return true


func _viewbox_width(svg_text: String) -> float:
	var regex := RegEx.create_from_string("viewBox=\"\\s*[-\\d.]+\\s+[-\\d.]+\\s+([\\d.]+)\\s+[\\d.]+\\s*\"")
	var result := regex.search(svg_text)
	if result == null:
		return 0.0
	return float(result.get_string(1))
