extends CanvasLayer
class_name GameInterface

## Handles the application-level interface and forwards user requests
## without creating or modifying the simulated world.

const INVALID_SEED_COLOR: Color = Color(
	0.8784314,
	0.32156864,
	0.32156864,
	1.0
)

## Emitted when the player requests a new world.
signal world_generation_requested(seed_text: String)

## Emitted when the player requests application shutdown.
signal exit_requested

var seed_input_focus_style: StyleBoxFlat
var normal_seed_border_color: Color

@onready var seed_input: LineEdit = (
	$InterfaceRoot/SeedPanel/SeedMargin/SeedControls/SeedInput
)

@onready var regenerate_button: Button = (
	$InterfaceRoot/SeedPanel/SeedMargin/SeedControls/RegenerateButton
)

@onready var exit_button: Button = (
	$InterfaceRoot/ExitButton
)


## Prepares the input styles and connects the interface controls.
func _ready() -> void:
	var configured_focus_style := (
		seed_input.get_theme_stylebox("focus")
	)

	assert(
		configured_focus_style is StyleBoxFlat,
		"SeedInput focus style must be a StyleBoxFlat."
	)

	seed_input_focus_style = (
		configured_focus_style.duplicate() as StyleBoxFlat
	)
	normal_seed_border_color = (
		seed_input_focus_style.border_color
	)

	seed_input.add_theme_stylebox_override(
		"focus",
		seed_input_focus_style
	)

	regenerate_button.pressed.connect(
		_on_regenerate_button_pressed
	)
	seed_input.text_submitted.connect(
		_on_seed_input_text_submitted
	)
	seed_input.text_changed.connect(
		_on_seed_input_text_changed
	)
	exit_button.pressed.connect(
		_on_exit_button_pressed
	)


## Displays the seed used by the active world.
func set_world_seed(seed_value: int) -> void:
	seed_input.text = str(seed_value)
	_clear_seed_error()


## Visually marks the current seed as invalid.
func show_seed_error() -> void:
	seed_input.add_theme_color_override(
		"font_color",
		INVALID_SEED_COLOR
	)
	seed_input_focus_style.border_color = (
		INVALID_SEED_COLOR
	)
	seed_input.tooltip_text = (
		"Seed must be a whole number."
	)

	seed_input.grab_focus()
	seed_input.select_all()


## Removes the invalid-seed indication.
func _clear_seed_error() -> void:
	seed_input.remove_theme_color_override(
		"font_color"
	)
	seed_input_focus_style.border_color = (
		normal_seed_border_color
	)
	seed_input.tooltip_text = ""


## Requests generation using the current field contents.
func _request_world_generation(seed_text: String) -> void:
	world_generation_requested.emit(
		seed_text.strip_edges()
	)


## Handles the Generate button.
func _on_regenerate_button_pressed() -> void:
	_request_world_generation(seed_input.text)


## Handles Enter pressed in the seed input field.
func _on_seed_input_text_submitted(
	submitted_text: String
) -> void:
	_request_world_generation(submitted_text)


## Clears the error indication when the player edits the seed.
func _on_seed_input_text_changed(
	_new_text: String
) -> void:
	_clear_seed_error()


## Forwards the application exit request.
func _on_exit_button_pressed() -> void:
	exit_requested.emit()
