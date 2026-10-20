extends RefCounted
class_name WorldSeedProvider

## Resolves the seed used for initial world generation.
##
## Command-line arguments have the highest priority, followed by the
## configured seed file and finally the built-in default value.

const DEFAULT_SEED: int = 12345
const ARGUMENT_PREFIX: String = "--seed="
const SEED_FILE_PATH: String = "res://config/world_seed.txt"


## Returns the seed used for initial world generation.
static func get_startup_seed() -> int:
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with(
			ARGUMENT_PREFIX
		):
			continue

		var argument_seed_text := argument.trim_prefix(
			ARGUMENT_PREFIX
		).strip_edges()

		if argument_seed_text.is_empty():
			break

		if argument_seed_text.is_valid_int():
			return argument_seed_text.to_int()

		push_warning(
			"Invalid command-line world seed '%s'. "
			+ "Using default seed %d."
			% [
				argument_seed_text,
				DEFAULT_SEED
			]
		)

		return DEFAULT_SEED

	if not FileAccess.file_exists(
		SEED_FILE_PATH
	):
		push_warning(
			"World seed file '%s' was not found. "
			+ "Using default seed %d."
			% [
				SEED_FILE_PATH,
				DEFAULT_SEED
			]
		)

		return DEFAULT_SEED

	var file_seed_text := FileAccess.get_file_as_string(
		SEED_FILE_PATH
	).strip_edges()

	if file_seed_text.is_empty():
		push_warning(
			"World seed file '%s' is empty. "
			+ "Using default seed %d."
			% [
				SEED_FILE_PATH,
				DEFAULT_SEED
			]
		)

		return DEFAULT_SEED

	if file_seed_text.is_valid_int():
		return file_seed_text.to_int()

	push_warning(
		"Invalid world seed '%s' in file '%s'. "
		+ "Using default seed %d."
		% [
			file_seed_text,
			SEED_FILE_PATH,
			DEFAULT_SEED
		]
	)

	return DEFAULT_SEED
