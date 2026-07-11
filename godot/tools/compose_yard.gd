extends SceneTree

# Compose the Hush Arbor pixel yard from Tiny Farm tiles (issue #100). Native 320x200 canvas
# (16px tiles), shown at 4x = 1280x800 with nearest filtering. Station world positions map
# to native by /4. Re-run to iterate; the output is the committed yard background texture.

const TILE := "res://assets/art/tiny-farm/Tiles/tile_%04d.png"
const OUT := "res://assets/art/hush-arbor-yard.png"
const W := 320
const H := 200

var _cache := {}
var _img: Image

func _initialize() -> void:
	_img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_img.fill(_tile(0).get_pixel(1, 1))   # grass base sampled from the pack

	_paths()
	_soil_beds()
	_treeline()
	_scatter()
	_stations()

	_img.save_png(ProjectSettings.globalize_path(OUT))
	print("composed pixel yard -> %s (%dx%d)" % [OUT, W, H])
	quit(0)

# --- layout passes ---

func _paths() -> void:
	# A horizontal dirt lane across the yard, with a spur up to the plant stand.
	var lane := [49, 50, 62, 61]
	for tx in range(2, 19):
		_stamp(lane[tx % lane.size()], tx * 16 + 8, 104)
	for ty in range(5, 7):
		_stamp(24 if ty % 2 == 0 else 12, 160, ty * 16 + 8)

func _soil_beds() -> void:
	# A 3x2 tilled bed the stations sit on so props rest on soil, not float on grass.
	for bed in [[77, 84], [160, 80], [229, 100], [120, 134], [179, 137]]:
		for dx in [-16, 0, 16]:
			_stamp(61, bed[0] + dx, bed[1])
	# Planted nursery rows along the central lane so it reads as beds of stock, not bare dirt.
	var crops := [53, 41, 5, 54, 66, 30, 55]
	for i in range(crops.size()):
		_stamp(crops[i], 40 + i * 38, 104)

func _treeline() -> void:
	# A dense orchard line framing the top — Hush Arbor is orchard country. Round fruit
	# trees carry it, a few pines at the ends for depth.
	_stamp(15, 12, 12)
	_stamp(27, 308, 12)
	for i in range(14):
		var tx := 26 + i * 20
		_stamp(39, tx, 13 + (i % 2) * 3)
	# Trees anchoring the lower corners so the yard feels enclosed.
	_stamp(15, 18, 150)
	_stamp(39, 302, 126)
	_stamp(27, 306, 158)

func _scatter() -> void:
	# Bushes, berry bushes, and sprouts for a lush, plant-forward yard.
	var spots := [
		[40, 40, 60], [78, 64, 60], [28, 288, 70], [40, 300, 158],
		[78, 44, 132], [28, 250, 150], [5, 100, 50], [4, 210, 46],
		[81, 140, 150], [5, 275, 100], [40, 96, 128], [80, 232, 140],
	]
	for s in spots:
		_stamp(s[0], s[1], s[2])
	# Flowering accents.
	_stamp(17, 56, 44)
	_stamp(17, 268, 158)

func _stations() -> void:
	# Signal board (308,322)->(77,80): a notice post.
	_stamp(88, 77, 78)
	# Plant stand (640,300)->(160,75): the centrepiece — a market table heaped with produce
	# and a sunflower, the most plant-forward silhouette.
	_stamp(110, 160, 82)
	_stamp(83, 148, 68)
	_stamp(11, 152, 74)
	_stamp(47, 168, 74)
	_stamp(41, 174, 68)
	# Propagation bench (916,380)->(229,95): seedling trays on a bench.
	_stamp(98, 229, 98)
	_stamp(4, 222, 90)
	_stamp(5, 236, 90)
	_stamp(16, 229, 88)
	# Ledger (480,520)->(120,130): a records crate.
	_stamp(97, 120, 130)
	# Journal (716,534)->(179,133): a reading nook — churn barrel with a potted sprig.
	_stamp(125, 179, 134)
	_stamp(81, 190, 130)

# --- helpers ---

func _tile(idx: int) -> Image:
	if not _cache.has(idx):
		var t := Image.load_from_file(ProjectSettings.globalize_path(TILE % idx))
		t.convert(Image.FORMAT_RGBA8)
		_cache[idx] = t
	return _cache[idx]

func _stamp(idx: int, cx: int, cy: int) -> void:
	_img.blend_rect(_tile(idx), Rect2i(0, 0, 16, 16), Vector2i(cx - 8, cy - 8))
