extends Sprite2D

@export var image_path := ""

func _ready() -> void:
	if image_path.is_empty():
		return
	var image := Image.load_from_file(ProjectSettings.globalize_path(image_path))
	if image == null:
		push_error("Missing local art texture: %s" % image_path)
		return
	texture = ImageTexture.create_from_image(image)
