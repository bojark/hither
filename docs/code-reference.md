# Code Reference

**Implementation version:** 0.022p  
**Engine:** Godot 4.7.1  
**Language:** GDScript  
**Related document:** [`architecture.md`](architecture.md)

This document describes the classes, data structures, functions, generation flow, interface, and presentation layer present in version 0.022p.

The source code remains authoritative for exact function signatures. This document explains the responsibilities, relationships, inputs, outputs, and current behavior of the code.

## Contents

- [Conventions](#conventions)
- [Class hierarchy](#class-hierarchy)
- [Application layer](#application-layer)
  - [Game script](#game-script)
  - [WorldSeedProvider](#worldseedprovider)
  - [WorldDebugPrinter](#worlddebugprinter)
- [Startup and regeneration flow](#startup-and-regeneration-flow)
- [World generation flow](#world-generation-flow)
- [World model](#world-model)
  - [World](#world)
  - [HexCoord](#hexcoord)
  - [Tile](#tile)
  - [ClearingTile](#clearingtile)
  - [ForestTile](#foresttile)
  - [TileEnums](#tileenums)
- [Tile sectors](#tile-sectors)
  - [Sector](#sector)
- [Features](#features)
  - [Feature](#feature)
  - [Encounter](#encounter)
  - [Place](#place)
  - [BaseCamp](#basecamp)
  - [NiceSpot](#nicespot)
  - [WatchHill](#watchhill)
- [Interface layer](#interface-layer)
  - [GameInterface](#gameinterface)
- [World presentation layer](#world-presentation-layer)
  - [WorldView](#worldview)
  - [HexView](#hexview)
  - [FeatureView](#featureview)
  - [FeatureVisual](#featurevisual)
- [Scenes and assets](#scenes-and-assets)
- [Ownership and relationships](#ownership-and-relationships)
- [Current limitations](#current-limitations)

## Conventions

- Classes derived from `RefCounted` represent simulation data or stateless services and do not belong to the Godot scene tree.
- Classes derived from `Node3D` represent objects in the three-dimensional presentation layer.
- Classes derived from `CanvasLayer` represent screen-space interface elements.
- Classes derived from `Resource` store reusable external configuration.
- Stable internal identifiers use lowercase `snake_case`, for example `forest`, `base_camp`, and `watch_hill`.
- Methods whose names begin with `_` are constructors, Godot lifecycle callbacks, signal handlers, or internal implementation methods.
- Axial hex coordinates use the `q` and `r` axes.
- The simulation layer does not depend on the interface or presentation layers.
- Presentation classes read simulation data without owning or modifying it.
- `GameInterface` sends user requests through signals and does not create or modify the active world.
- Each tile contains seven sectors:
  - `0` — north;
  - `1` — north-east;
  - `2` — south-east;
  - `3` — south;
  - `4` — south-west;
  - `5` — north-west;
  - `6` — center.
- A sector can contain no more than one [`Feature`](#feature).
- A null `Sector.feature` represents an empty sector.

## Class hierarchy

- `Node`
  - [Game script](#game-script)
- `CanvasLayer`
  - [`GameInterface`](#gameinterface)
- `Node3D`
  - [`WorldView`](#worldview)
  - [`HexView`](#hexview)
  - [`FeatureView`](#featureview)
- `Resource`
  - [`FeatureVisual`](#featurevisual)
- `RefCounted`
  - [`WorldSeedProvider`](#worldseedprovider)
  - [`WorldDebugPrinter`](#worlddebugprinter)
  - [`World`](#world)
  - [`HexCoord`](#hexcoord)
  - [`Tile`](#tile)
    - [`ClearingTile`](#clearingtile)
    - [`ForestTile`](#foresttile)
  - [`Sector`](#sector)
  - [`Feature`](#feature)
    - [`Encounter`](#encounter)
    - [`Place`](#place)
      - [`BaseCamp`](#basecamp)
      - [`NiceSpot`](#nicespot)
      - [`WatchHill`](#watchhill)
  - [`TileEnums`](#tileenums)

## Application layer

### Game script

**Script:** [`res://scripts/core/game.gd`](../scripts/core/game.gd)  
**Base class:** `Node`  
**Scene:** [`res://scenes/Main.tscn`](../scenes/Main.tscn)  
**Named class:** none

Coordinates application startup, world generation, visualization, and application-level interface requests.

`Game` owns the active [`World`](#world). It receives requests from [`GameInterface`](#gameinterface), creates a new world when required, and passes generated tiles to [`WorldView`](#worldview).

Seed resolution, debug formatting, interface behavior, simulation, and rendering are delegated to their respective classes.

### Properties

#### `world: World`

The active generated world.

When another valid seed is submitted, this property is replaced with a newly created `World`.

#### `world_view: WorldView`

Reference to the `$WorldView` child node.

Receives the generated starting-area tiles and creates their visual representation.

#### `game_interface: GameInterface`

Reference to the `$Interface` child node.

Provides world-generation and application-exit requests through signals.

### Methods

#### `_ready() -> void`

Godot lifecycle callback executed when the `Game` node enters the scene tree.

It performs the current startup sequence:

1. connects `GameInterface.world_generation_requested`;
2. connects `GameInterface.exit_requested`;
3. prints the startup message;
4. asks [`WorldSeedProvider`](#worldseedprovider) for the startup seed;
5. displays that seed in the interface;
6. generates and displays the initial world.

#### `_generate_world(world_seed: int) -> void`

Creates and displays a new world using `world_seed`.

The method:

1. creates `World.new(world_seed)`;
2. assigns it to `world`;
3. calls `World.generate_starting_area()`;
4. passes the returned tiles to `WorldView.display_tiles()`;
5. passes the same tiles to `WorldDebugPrinter.print_starting_area()`.

The previous `World` reference is replaced. Existing visual tile nodes are removed by `WorldView` when the new tiles are displayed.

#### `_on_world_generation_requested(seed_text: String) -> void`

Handles a world-generation request emitted by `GameInterface`.

Current behavior:

- an empty string uses `WorldSeedProvider.DEFAULT_SEED`;
- a valid integer string creates a new world with that integer;
- invalid text produces a warning, preserves the current world, and calls `GameInterface.show_seed_error()`.

For an empty or valid seed, the normalized integer value is written back to the interface before generation.

#### `_on_exit_requested() -> void`

Handles `GameInterface.exit_requested`.

Calls:

`get_tree().quit()`

This ends the running application when the player presses the exit button.

#### `_get_startup_message() -> String`

Reads the application name and version from [`project.godot`](../project.godot).

Returns a string in this form:

`=== Hither v0.022p started ===`

---

### WorldSeedProvider

**Script:** [`res://scripts/core/world_seed_provider.gd`](../scripts/core/world_seed_provider.gd)  
**Base class:** `RefCounted`

Resolves the seed used for initial world generation.

The class is stateless. Its constants and methods are static, so creating a `WorldSeedProvider` instance is unnecessary.

Seed selection performed after startup through the interface is handled by [`Game`](#game-script). `WorldSeedProvider` is responsible only for the initial seed.

### Constants

#### `DEFAULT_SEED: int = 12345`

Fallback seed used when no valid external startup seed can be obtained.

The same value is used when the player submits an empty seed field.

#### `ARGUMENT_PREFIX: String = "--seed="`

Prefix used to locate an explicit command-line seed.

Example:

`--seed=98765`

#### `SEED_FILE_PATH: String = "res://config/world_seed.txt"`

Path to the development seed file.

The file is expected to contain one integer.

### Methods

#### `WorldSeedProvider.get_startup_seed() -> int`

Returns the seed used for initial world generation.

The current priority is:

1. a valid `--seed=<number>` command-line argument;
2. a valid integer in `config/world_seed.txt`;
3. `DEFAULT_SEED`.

Command-line behavior:

- a valid integer is returned immediately;
- an empty `--seed=` value allows seed resolution to continue to the file;
- an invalid non-empty value produces a warning and returns the default seed.

Seed-file behavior:

- a valid integer is returned;
- a missing file produces a warning and returns the default;
- an empty file produces a warning and returns the default;
- invalid file contents produce a warning and return the default.

The file is read only during initial startup. Regenerating the world from the interface does not modify it.

---

### WorldDebugPrinter

**Script:** [`res://scripts/debug/world_debug_printer.gd`](../scripts/debug/world_debug_printer.gd)  
**Base class:** `RefCounted`

Formats and prints temporary debugging information about generated worlds.

The class is stateless. Its methods are static.

`WorldDebugPrinter` does not generate or modify simulation data.

### Methods

#### `WorldDebugPrinter.print_starting_area(starting_tiles: Array[Tile]) -> void`

Prints the starting tile and its six neighbours.

The expected array order is:

1. starting tile;
2. north neighbour;
3. north-east neighbour;
4. south-east neighbour;
5. south neighbour;
6. south-west neighbour;
7. north-west neighbour.

Each tile is passed to `_print_tile_features()`.

#### `WorldDebugPrinter._print_tile_features(tile: Tile) -> void`

Prints every occupied sector of the supplied tile.

For each occupied sector, it prints:

- sector index;
- readable sector position;
- broad feature category;
- feature type ID.

Prints `No features` when every sector is empty.

#### `WorldDebugPrinter._get_feature_kind(feature: Feature) -> String`

Returns a temporary readable category for a feature.

Current results:

- `encounter` for [`Encounter`](#encounter);
- `place` for [`Place`](#place);
- `feature` for other [`Feature`](#feature) instances.

#### `WorldDebugPrinter._get_position_name(position_index: int) -> String`

Converts a sector localization key into a temporary English name.

For example:

`sector.north_east` becomes `North East`.

This conversion is used only for debug output and does not replace the future localization system.

---

## Startup and regeneration flow

### Initial startup

The following sequence is executed when the project starts:

1. [`Main.tscn`](../scenes/Main.tscn) creates the `Game` node.
2. `Game` receives its `WorldView` and `GameInterface` child references.
3. `GameInterface._ready()` prepares the seed-input styles and connects its controls.
4. `Game._ready()` connects the two interface signals.
5. `Game` prints the project name and version.
6. `WorldSeedProvider.get_startup_seed()` resolves the initial seed.
7. `GameInterface.set_world_seed()` displays the selected seed.
8. `Game._generate_world()` creates a new `World`.
9. `World.generate_starting_area()` returns seven generated tiles.
10. `WorldView.display_tiles()` creates the three-dimensional map.
11. `WorldDebugPrinter.print_starting_area()` prints the generated data.
12. The project remains running and accepts interface input.

### Valid seed regeneration

When the player enters a valid integer and presses `Generate` or `Enter`:

1. `GameInterface` strips leading and trailing whitespace.
2. `GameInterface` emits `world_generation_requested`.
3. `Game._on_world_generation_requested()` validates the string.
4. The text is converted to an integer.
5. The normalized integer is displayed in the seed field.
6. `Game._generate_world()` creates a new `World`.
7. `WorldView` removes the old visual tiles.
8. The new starting area is generated and displayed.
9. The new generated data is printed to the debug console.

The seed stored in `config/world_seed.txt` is not changed.

### Empty seed regeneration

When the submitted field is empty:

1. `Game` selects `WorldSeedProvider.DEFAULT_SEED`;
2. the field is changed to `12345`;
3. a new world is generated with seed `12345`.

### Invalid seed submission

When the submitted text is neither empty nor a valid integer:

1. the current `World` remains active;
2. the displayed map is not replaced;
3. a warning is sent to the debugger;
4. `GameInterface.show_seed_error()` marks the input;
5. the seed text becomes selected for correction.

Editing the field removes the visual error indication.

### Application exit

When the exit button is pressed:

1. `GameInterface` emits `exit_requested`;
2. `Game._on_exit_requested()` receives the signal;
3. the scene tree is asked to quit;
4. the application process ends normally.

---

## World generation flow

This section describes the exact generation sequence implemented in 0.022p.

The generation algorithm itself is unchanged from 0.02p. Versions 0.021p and 0.022p add presentation, environment, interface, and runtime regeneration around it.

General generation rules and architectural requirements belong in [`architecture.md`](architecture.md). This section records how the current code executes those rules.

### Starting-area generation

`World.generate_starting_area()` performs these operations:

1. Calls `World.get_start_tile()`.
2. Generates the starting tile at `(0, 0)` if it does not already exist.
3. Adds the starting tile to the result array at index `0`.
4. Processes the six offsets from `HexCoord.NEIGHBOR_DIRECTIONS` in index order.
5. Calculates each neighbouring coordinate with `HexCoord.get_neighbor()`.
6. Retrieves or generates each neighbour with `World.get_tile()`.
7. Appends the neighbours in direction order.
8. Places the unique Watch Hill after all seven tiles exist.
9. Returns the seven-tile array.

The resulting array order is stable:

| Array index | Coordinate direction |
|---:|---|
| `0` | Starting tile |
| `1` | North |
| `2` | North-east |
| `3` | South-east |
| `4` | South |
| `5` | South-west |
| `6` | North-west |

### Individual tile generation

`World._generate_tile()` performs these operations:

1. Converts the supplied [`HexCoord`](#hexcoord) into a `Vector2i` key.
2. Checks whether the key equals `START_COORD`.
3. Creates a [`ClearingTile`](#clearingtile) for `(0, 0)`.
4. For other coordinates:
   1. creates a `RandomNumberGenerator`;
   2. assigns the coordinate-specific seed;
   3. creates either a [`ForestTile`](#foresttile) or a [`ClearingTile`](#clearingtile).
5. Assigns the supplied coordinate to `tile.coord`.
6. Places a [`BaseCamp`](#basecamp) in sector `6` of the starting tile.
7. Calls `_populate_tile()` for non-starting tiles.
8. Returns the completed tile.

`World.get_tile()` then stores the tile in `World.tiles`.

### Terrain generation

For non-starting tiles, terrain selection currently has two equally probable results:

| Roll | Tile class | Type ID |
|---:|---|---|
| `0` | `ForestTile` | `forest` |
| `1` | `ClearingTile` | `clearing` |

The starting tile is always a `ClearingTile`.

### Sector population

`World._populate_tile()` processes only outer sector indices `0–5`.

The central sector at index `6` is reserved for separately placed content.

For each outer sector:

1. a new `RandomNumberGenerator` is created;
2. the generator receives a seed derived from the tile coordinate and sector index;
3. a number from `0` to `99` is generated;
4. the result determines the content;
5. non-empty content is placed with `Sector.set_feature()`.

Current result ranges:

| Roll | Result | Probability |
|---:|---|---:|
| `0–69` | Empty sector | 70% |
| `70–79` | `Feature.new("marsh")` | 10% |
| `80–89` | `Encounter.new("gnat_swarm")` | 10% |
| `90–99` | `NiceSpot.new()` | 10% |

These values describe the current implementation and are not permanent balance values.

### Base Camp placement

The Base Camp has a fixed location:

- tile coordinate: `(0, 0)`;
- tile type: `clearing`;
- sector index: `6`;
- sector position: center.

Ordinary sector population is not performed for the starting tile.

### Watch Hill placement

After all seven starting-area tiles exist, `World._place_watch_hill()`:

1. creates a separate `RandomNumberGenerator`;
2. seeds it with `generation_seed + WATCH_HILL_SEED_OFFSET`;
3. selects an array index from `1` to `6`;
4. obtains that neighbouring tile;
5. obtains its central sector;
6. places a [`WatchHill`](#watchhill).

Ordinary population does not use central sectors, so the selected sector is normally empty.

If the method is called again for the same area, it accepts an existing `WatchHill` but rejects a different feature in that sector.

### Seed derivation

A tile seed is calculated as:

`generation_seed + q * TILE_Q_SEED_FACTOR + r * TILE_R_SEED_FACTOR`

With current values:

`generation_seed + q * 73856093 + r * 19349663`

A sector seed is calculated as:

`tile_seed + (sector_index + 1) * SECTOR_SEED_FACTOR`

With the current value:

`tile_seed + (sector_index + 1) * 83492791`

The Watch Hill location uses:

`generation_seed + 104729`

Terrain selection, individual sector contents, and Watch Hill placement therefore remain reproducible.

---

## World model

### World

**Script:** [`res://scripts/core/world.gd`](../scripts/core/world.gd)  
**Base class:** `RefCounted`

Creates, stores, and retrieves generated tiles.

World generation is reproducible from the same seed and coordinates.

Tiles are generated when requested and retained for later access.

### Constants

#### `START_COORD: Vector2i = Vector2i(0, 0)`

Axial coordinates of the starting tile.

#### `TILE_Q_SEED_FACTOR: int = 73856093`

Constant used to mix the tile’s `q` coordinate into its seed.

#### `TILE_R_SEED_FACTOR: int = 19349663`

Constant used to mix the tile’s `r` coordinate into its seed.

#### `SECTOR_SEED_FACTOR: int = 83492791`

Constant used to derive a distinct seed for each sector.

#### `WATCH_HILL_SEED_OFFSET: int = 104729`

Offset used to select the Watch Hill independently from terrain and sector contents.

### Properties

#### `generation_seed: int`

Seed from which tile, sector, and special-placement seeds are derived.

#### `tiles: Dictionary[Vector2i, Tile]`

Generated tiles indexed by axial coordinates stored as `Vector2i`.

Repeated requests for the same coordinate return the stored tile.

### Methods

#### `World._init(seed_value: int) -> void`

Stores `seed_value` as the world generation seed.

Prints the selected seed for debugging.

#### `World.generate_starting_area() -> Array[Tile]`

Generates or retrieves the starting tile and its six neighbours.

Returns them in this order:

1. center;
2. directions `0–5`.

Places the unique Watch Hill after collecting the tiles.

#### `World.get_start_tile() -> Tile`

Returns the tile at `START_COORD`.

Generates it first if necessary.

#### `World.get_tile(coord: HexCoord) -> Tile`

Returns the tile at `coord`.

Calls `_generate_tile()` and stores the result when the tile does not yet exist.

#### `World._generate_tile(coord: HexCoord) -> Tile`

Creates one tile reproducibly from the world seed and coordinates.

Assigns its coordinate, terrain type, and initial contents.

#### `World._populate_tile(tile: Tile) -> void`

Generates content for the six outer sectors of a non-starting tile.

Does not populate the central sector.

#### `World._place_watch_hill(starting_tiles: Array[Tile]) -> void`

Places the unique Watch Hill in the central sector of one reproducibly selected neighbouring tile.

#### `World._get_tile_seed(coord: HexCoord) -> int`

Derives the seed used to select terrain at one coordinate.

#### `World._get_sector_seed(coord: HexCoord, sector_index: int) -> int`

Derives the seed used to populate one sector.

---

### HexCoord

**Script:** [`res://scripts/core/world/hex_coord.gd`](../scripts/core/world/hex_coord.gd)  
**Base class:** `RefCounted`

Represents axial coordinates of one hexagonal tile.

### Constants

#### `HexCoord.NEIGHBOR_DIRECTIONS: Array[Vector2i]`

Coordinate offsets of the six adjacent hexes:

| Index | Offset | Direction |
|---:|---|---|
| `0` | `Vector2i(0, -1)` | North |
| `1` | `Vector2i(1, -1)` | North-east |
| `2` | `Vector2i(1, 0)` | South-east |
| `3` | `Vector2i(0, 1)` | South |
| `4` | `Vector2i(-1, 1)` | South-west |
| `5` | `Vector2i(-1, 0)` | North-west |

### Properties

#### `q: int`

Position on the first axial coordinate axis.

#### `r: int`

Position on the second axial coordinate axis.

### Methods

#### `HexCoord._init(q_value: int, r_value: int) -> void`

Creates an axial coordinate with the supplied values.

#### `HexCoord.get_neighbor(direction_index: int) -> HexCoord`

Returns a new coordinate for the neighbouring tile in `direction_index`.

The accepted range is `0–5`.

An assertion fails for an index outside that range.

---

### Tile

**Script:** [`res://scripts/core/world/tile.gd`](../scripts/core/world/tile.gd)  
**Base class:** `RefCounted`

Represents one hexagonal world tile and owns its seven sectors.

`Tile` contains simulation data and has no dependency on its visual representation.

### Constants

#### `Tile.SECTOR_COUNT: int = 7`

Number of sectors created for every tile.

### Properties

#### `type: String`

Stable terrain-type identifier.

Current values:

- `clearing`;
- `forest`.

#### `coord: HexCoord`

Axial position assigned by [`World`](#world).

#### `visibility: TileEnums.Visibility`

Terrain visibility category.

Its gameplay effects are not implemented yet.

#### `outlook: TileEnums.Outlook`

Terrain outlook category.

Its gameplay effects are not implemented yet.

#### `sectors: Array[Sector]`

Seven sectors owned by the tile.

The array index matches each sector’s local index.

### Methods

#### `Tile._init(type_id: String) -> void`

Creates a tile with the supplied type ID.

The type ID must not be empty.

Creates sectors `0–6`.

#### `Tile.get_sector(sector_index: int) -> Sector`

Returns the sector at `sector_index`.

The accepted range is `0–6`.

An assertion fails for an index outside that range.

---

### ClearingTile

**Script:** [`res://scripts/core/world/tile_types/clearing_tile.gd`](../scripts/core/world/tile_types/clearing_tile.gd)  
**Base class:** [`Tile`](#tile)  
**Type ID:** `clearing`

Represents open clearing terrain.

### Initial values

- `visibility = TileEnums.Visibility.VISIBLE`
- `outlook = TileEnums.Outlook.OPEN`

### Methods

#### `ClearingTile._init() -> void`

Creates a tile with the type ID `clearing` and assigns the clearing-specific visibility and outlook.

---

### ForestTile

**Script:** [`res://scripts/core/world/tile_types/forest_tile.gd`](../scripts/core/world/tile_types/forest_tile.gd)  
**Base class:** [`Tile`](#tile)  
**Type ID:** `forest`

Represents forest terrain.

### Initial values

- `visibility = TileEnums.Visibility.HIGH`
- `outlook = TileEnums.Outlook.CLOSED`

### Methods

#### `ForestTile._init()`

Creates a tile with the type ID `forest` and assigns the forest-specific visibility and outlook.

---

### TileEnums

**Script:** [`res://scripts/core/world/tile_Enums.gd`](../scripts/core/world/tile_Enums.gd)  
**Base class:** `RefCounted`

Contains enum types shared by terrain classes.

### Enums

#### `TileEnums.Visibility`

Values:

- `HIDDEN`;
- `VISIBLE`;
- `HIGH`.

The gameplay effects are not implemented yet.

#### `TileEnums.Outlook`

Values:

- `CLOSED`;
- `OPEN`;
- `OVERVIEW`.

The gameplay effects are not implemented yet.

---

## Tile sectors

### Sector

**Script:** [`res://scripts/core/world/sector.gd`](../scripts/core/world/sector.gd)  
**Base class:** `RefCounted`

Represents one local position inside a tile.

A sector contains either one feature or `null`.

### Constants

#### `Sector.POSITION_IDS: Array[String]`

Stable localization keys for sector positions:

| Index | Localization key | Position |
|---:|---|---|
| `0` | `sector.north` | North |
| `1` | `sector.north_east` | North-east |
| `2` | `sector.south_east` | South-east |
| `3` | `sector.south` | South |
| `4` | `sector.south_west` | South-west |
| `5` | `sector.north_west` | North-west |
| `6` | `sector.center` | Center |

### Properties

#### `index: int`

Local sector index in the range `0–6`.

#### `feature: Feature = null`

Feature currently occupying the sector.

`null` means the sector is empty.

### Methods

#### `Sector._init(sector_index: int) -> void`

Creates a sector with the supplied index.

An assertion fails when the index is outside the supported range.

#### `Sector.get_position_id() -> String`

Returns the stable localization key for the sector position.

#### `Sector.is_empty() -> bool`

Returns `true` when `feature` is `null`.

#### `Sector.set_feature(new_feature: Feature) -> void`

Places a non-null feature into an empty sector.

Assertions prevent:

- assigning `null`;
- replacing an existing feature.

#### `Sector.clear_feature() -> void`

Removes the current feature by assigning `null`.

The method does not perform encounter resolution or other gameplay consequences.

---

## Features

### Feature

**Script:** [`res://scripts/core/world/feature.gd`](../scripts/core/world/feature.gd)  
**Base class:** `RefCounted`

Base class for anything that can occupy a sector.

This includes passive terrain features, encounters, and places.

### Properties

#### `type_id: String`

Stable internal feature identifier.

Current values:

- `marsh`;
- `gnat_swarm`;
- `base_camp`;
- `nice_spot`;
- `watch_hill`.

#### `name_id: String`

Localization key for the displayed feature name.

Constructed in this form:

`feature.<type_id>.name`

Example:

`feature.watch_hill.name`

### Methods

#### `Feature._init(feature_type_id: String) -> void`

Creates a feature with the supplied type ID.

The identifier must not be empty.

Generates `name_id` automatically.

---

### Encounter

**Script:** [`res://scripts/core/world/feature_types/encounter.gd`](../scripts/core/world/feature_types/encounter.gd)  
**Base class:** [`Feature`](#feature)

Represents a feature that requires interaction and a decision.

An encounter is expected to disappear after resolution. Resolution behavior is not implemented yet.

### Methods

#### `Encounter._init(encounter_type_id: String) -> void`

Creates an encounter with the supplied stable type ID.

The currently generated encounter uses `gnat_swarm`.

---

### Place

**Script:** [`res://scripts/core/world/feature_types/place.gd`](../scripts/core/world/feature_types/place.gd)  
**Base class:** [`Feature`](#feature)

Represents a persistent place with which the player may choose to interact.

Places currently behave as points of interaction.

Some places may receive their own internal spaces in future versions.

### Methods

#### `Place._init(place_type_id: String) -> void`

Creates a place with the supplied stable type ID.

---

### BaseCamp

**Script:** [`res://scripts/core/world/feature_types/base_camp.gd`](../scripts/core/world/feature_types/base_camp.gd)  
**Base class:** [`Place`](#place)  
**Type ID:** `base_camp`

Represents the player’s Base Camp.

Exactly one Base Camp is placed in the central sector of the starting tile.

### Methods

#### `BaseCamp._init() -> void`

Creates a place with the type ID `base_camp`.

---

### NiceSpot

**Script:** [`res://scripts/core/world/feature_types/nice_spot.gd`](../scripts/core/world/feature_types/nice_spot.gd)  
**Base class:** [`Place`](#place)  
**Type ID:** `nice_spot`

Represents a non-unique optional place.

It may appear in outer sectors populated by ordinary feature generation.

### Methods

#### `NiceSpot._init() -> void`

Creates a place with the type ID `nice_spot`.

---

### WatchHill

**Script:** [`res://scripts/core/world/feature_types/watch_hill.gd`](../scripts/core/world/feature_types/watch_hill.gd)  
**Base class:** [`Place`](#place)  
**Type ID:** `watch_hill`

Represents the unique Watch Hill in the starting area.

It is placed in the central sector of one neighbouring tile. Its location is reproducible from the world seed.

### Methods

#### `WatchHill._init() -> void`

Creates a place with the type ID `watch_hill`.

---

## Interface layer

### GameInterface

**Script:** [`res://scripts/presentation/interface/game_interface.gd`](../scripts/presentation/interface/game_interface.gd)  
**Scene:** [`res://scenes/Main.tscn`](../scenes/Main.tscn)  
**Base class:** `CanvasLayer`

Handles the current application-level interface.

The class reads interface controls and emits requests. It does not create, own, or modify the active world.

### Constants

#### `INVALID_SEED_COLOR: Color`

Color used for invalid seed text and the seed field’s focus border.

The current value is a red error color.

### Signals

#### `world_generation_requested(seed_text: String)`

Emitted when the player requests world generation.

The argument contains the trimmed contents of the seed input field.

The signal does not guarantee that the text contains a valid integer. Validation belongs to [`Game`](#game-script).

#### `exit_requested`

Emitted when the player presses the exit button.

[`Game`](#game-script) responds by requesting application shutdown.

### Properties

#### `seed_input_focus_style: StyleBoxFlat`

Runtime duplicate of the seed field’s configured focus style.

The duplicate allows the interface to change the focus-border color without modifying the original shared style resource.

#### `normal_seed_border_color: Color`

Original focus-border color restored after an input error is cleared.

#### `seed_input: LineEdit`

Reference to:

`$InterfaceRoot/SeedPanel/SeedMargin/SeedControls/SeedInput`

Displays the active seed and accepts another seed from the player.

#### `regenerate_button: Button`

Reference to:

`$InterfaceRoot/SeedPanel/SeedMargin/SeedControls/RegenerateButton`

Emits a world-generation request using the current field contents.

#### `exit_button: Button`

Reference to:

`$InterfaceRoot/ExitButton`

Emits an application-exit request.

### Methods

#### `GameInterface._ready() -> void`

Prepares the seed-input styles and connects the interface controls.

The method:

1. obtains the configured `focus` style from `SeedInput`;
2. verifies that it is a `StyleBoxFlat`;
3. duplicates it;
4. stores its original border color;
5. applies the duplicate as a local style override;
6. connects the Generate button;
7. connects seed submission through `Enter`;
8. connects seed text changes;
9. connects the exit button.

#### `GameInterface.set_world_seed(seed_value: int) -> void`

Displays `seed_value` in the seed input field.

Also clears any previously displayed seed error.

#### `GameInterface.show_seed_error() -> void`

Displays the invalid-seed state.

The method:

- changes the text color;
- changes the focus-border color;
- sets the tooltip to `Seed must be a whole number.`;
- gives focus to the field;
- selects all current text.

#### `GameInterface._clear_seed_error() -> void`

Removes the invalid-seed indication.

The method:

- removes the custom font color;
- restores the normal focus-border color;
- clears the tooltip.

#### `GameInterface._request_world_generation(seed_text: String) -> void`

Strips leading and trailing whitespace from `seed_text` and emits `world_generation_requested`.

#### `GameInterface._on_regenerate_button_pressed() -> void`

Handles the Generate button.

Passes the current field contents to `_request_world_generation()`.

#### `GameInterface._on_seed_input_text_submitted(submitted_text: String) -> void`

Handles `Enter` pressed in the seed input.

Passes the submitted text to `_request_world_generation()`.

#### `GameInterface._on_seed_input_text_changed(_new_text: String) -> void`

Clears the error indication as soon as the player edits the field.

The new text is not validated until another generation request is submitted.

#### `GameInterface._on_exit_button_pressed() -> void`

Emits `exit_requested`.

---

## World presentation layer

### WorldView

**Script:** [`res://scripts/presentation/world/world_view.gd`](../scripts/presentation/world/world_view.gd)  
**Scene:** [`res://scenes/world/world_view.tscn`](../scenes/world/world_view.tscn)  
**Base class:** `Node3D`

Displays generated tiles as a three-dimensional hexagonal map.

`WorldView` does not generate tiles and does not modify simulation data.

The scene also owns the current:

- tile-view container;
- fixed orthographic camera;
- outdoor environment;
- directional sunlight.

### Constants

#### `HEX_VIEW_SCENE: PackedScene`

Preloaded `hex_view.tscn` scene used to display each tile.

#### `HEX_X_SPACING: float = 1.5`

Horizontal center-to-center spacing for the current flat-top hex geometry.

#### `HEX_Z_SPACING: float = 1.7320508`

Depth-axis center-to-center spacing.

The value approximates `sqrt(3)`.

### Properties

#### `tiles_container: Node3D`

Reference to the `$Tiles` node.

Generated `HexView` instances are added to this container.

### Methods

#### `WorldView.display_tiles(tiles: Array[Tile]) -> void`

Replaces the displayed map with the supplied tiles.

For each tile, the method:

1. creates a `HexView`;
2. validates the instantiated scene type;
3. converts the tile coordinate into an XZ position;
4. passes the tile to `HexView.setup()`;
5. adds the view to `tiles_container`.

#### `WorldView._hex_to_world(coord: HexCoord) -> Vector3`

Converts axial coordinates into a position on the XZ plane.

The current formula is:

`x = q * 1.5`

`z = (r + q * 0.5) * 1.7320508`

The Y coordinate is `0.0`.

This formula produces the same arrangement as `HexCoord.NEIGHBOR_DIRECTIONS`.

#### `WorldView._clear_tiles() -> void`

Queues all existing children of `tiles_container` for deletion before a new map is displayed.

Deletion occurs through Godot’s `queue_free()` mechanism.

---

### HexView

**Script:** [`res://scripts/presentation/world/hex_view.gd`](../scripts/presentation/world/hex_view.gd)  
**Scene:** [`res://scenes/world/hex_view.tscn`](../scenes/world/hex_view.tscn)  
**Base class:** `Node3D`

Displays one simulation [`Tile`](#tile).

A `HexView`:

- selects the surface material for the terrain type;
- provides seven sector anchors;
- creates a `FeatureView` for every occupied sector.

It does not modify its tile.

### Constants

#### `TERRAIN_SURFACE_MATERIALS: Dictionary[String, Material]`

Maps terrain type IDs to external surface materials.

Current entries:

| Tile type | Material |
|---|---|
| `clearing` | `clearing_surface_material.tres` |
| `forest` | `forest_surface_material.tres` |

#### `FEATURE_VIEW_SCENE: PackedScene`

Preloaded `feature_view.tscn` scene used for occupied sectors.

### Properties

#### `tile: Tile`

Simulation tile currently represented by this view.

#### `surface: MeshInstance3D`

Reference to the `$Surface` mesh.

The selected terrain material is assigned to surface index `0`.

#### `sector_anchors: Node3D`

Reference to `$SectorAnchors`.

Contains markers named `Sector0` through `Sector6`.

### Methods

#### `HexView._ready() -> void`

Refreshes the view when a tile was assigned before the node entered the scene tree.

#### `HexView.setup(tile_data: Tile) -> void`

Assigns a non-null tile.

The method may be called before or after the node enters the scene tree.

When the node is ready, it refreshes the terrain and features immediately.

#### `HexView._refresh_view() -> void`

Updates both parts of the tile view:

1. terrain surface material;
2. displayed sector features.

#### `HexView._apply_tile_material() -> void`

Looks up the material associated with `tile.type`.

An assertion fails when no material is registered.

The selected external material is assigned to the `Surface` mesh.

#### `HexView._display_features() -> void`

Creates one [`FeatureView`](#featureview) for every occupied sector.

For each occupied sector, the method:

1. finds `Sector<index>` inside `$SectorAnchors`;
2. verifies that the marker exists;
3. instantiates `feature_view.tscn`;
4. passes the sector feature to `FeatureView.setup()`;
5. adds the view to the marker.

Empty sectors receive no `FeatureView`.

#### `HexView._clear_feature_views() -> void`

Removes previously created `FeatureView` children from all sector anchors.

Other possible child-node types are preserved.

---

### FeatureView

**Script:** [`res://scripts/presentation/world/feature_view.gd`](../scripts/presentation/world/feature_view.gd)  
**Scene:** [`res://scenes/world/feature_view.tscn`](../scenes/world/feature_view.tscn)  
**Base class:** `Node3D`

Displays one simulation [`Feature`](#feature) as a billboarded `Sprite3D`.

`FeatureView` reads its appearance from a [`FeatureVisual`](#featurevisual) resource.

It does not modify the feature.

### Constants

#### `FEATURE_VISUALS: Dictionary[String, FeatureVisual]`

Maps feature type IDs to external visual resources.

Current entries:

| Feature type | Visual resource |
|---|---|
| `marsh` | `marsh_visual.tres` |
| `gnat_swarm` | `gnat_swarm_visual.tres` |
| `base_camp` | `base_camp_visual.tres` |
| `nice_spot` | `nice_spot_visual.tres` |
| `watch_hill` | `watch_hill_visual.tres` |

### Properties

#### `feature: Feature`

Simulation feature currently represented by this view.

#### `icon: Sprite3D`

Reference to `$Icon`.

Receives its texture, tint, pixel size, and vertical position from the selected `FeatureVisual`.

### Methods

#### `FeatureView._ready() -> void`

Applies the selected visual when the feature was assigned before the node entered the scene tree.

#### `FeatureView.setup(feature_data: Feature) -> void`

Assigns a non-null feature.

The method may be called before or after the node enters the scene tree.

When the node is ready, it applies the corresponding visual immediately.

#### `FeatureView._apply_feature_visual() -> void`

Finds the `FeatureVisual` registered for `feature.type_id`.

Assertions verify that:

- a visual resource is registered;
- the visual resource contains a texture.

The method then applies:

- `texture` to `Sprite3D.texture`;
- `tint` to `Sprite3D.modulate`;
- `pixel_size` to `Sprite3D.pixel_size`;
- `vertical_offset` to `Sprite3D.position.y`.

---

### FeatureVisual

**Script:** [`res://scripts/presentation/world/feature_visual.gd`](../scripts/presentation/world/feature_visual.gd)  
**Base class:** `Resource`

Stores replaceable presentation settings for one feature type.

Keeping these values outside `FeatureView` allows placeholder visuals to be replaced without changing rendering code or simulation classes.

### Properties

#### `texture: Texture2D`

Texture displayed by `FeatureView`.

The current resources share a placeholder SVG texture.

#### `tint: Color = Color.WHITE`

Color multiplied with the texture.

The current placeholder features use different tints for visual distinction.

#### `pixel_size: float = 0.004`

Size of one texture pixel in three-dimensional world units.

The exported Inspector range is:

- minimum: `0.0001`;
- maximum: `0.02`;
- step: `0.0001`.

#### `vertical_offset: float = 0.25`

Vertical position of the sprite relative to its sector anchor.

---

## Scenes and assets

### Main scene

[`res://scenes/Main.tscn`](../scenes/Main.tscn)

Current relevant hierarchy:

```text
Main
└── Game
    ├── WorldView
    └── Interface
        └── InterfaceRoot
            ├── ExitButton
            └── SeedPanel
                └── SeedMargin
                    └── SeedControls
                        ├── SeedLabel
                        ├── SeedInput
                        └── RegenerateButton
```

`Game` owns the active world and coordinates its two presentation children.

`Interface` is a `CanvasLayer`, so its controls remain in screen space independently of the three-dimensional camera.

### World view scene

[`res://scenes/world/world_view.tscn`](../scenes/world/world_view.tscn)

Current relevant hierarchy:

```text
WorldView
├── Tiles
├── Camera3D
└── Lighting
    ├── WorldEnvironment
    └── Sun
```

The current camera:

- uses orthographic projection;
- has a fixed isometric-style angle;
- has no runtime movement or zoom controls.

The `Sun` node is a `DirectionalLight3D`.

It provides directional outdoor lighting and shadows. Its position in the scene is not significant; its rotation determines the direction of the light.

The sun is not yet connected to a world clock or shared time-of-day system.

### Hex view scene

[`res://scenes/world/hex_view.tscn`](../scenes/world/hex_view.tscn)

```text
HexView
├── Body
├── Surface
└── SectorAnchors
    ├── Sector0
    ├── Sector1
    ├── Sector2
    ├── Sector3
    ├── Sector4
    ├── Sector5
    └── Sector6
```

`Body` and `Surface` are separate six-sided `CylinderMesh` instances.

This allows the terrain surface and side walls to use independent materials or textures.

### Feature view scene

[`res://scenes/world/feature_view.tscn`](../scenes/world/feature_view.tscn)

```text
FeatureView
└── Icon
```

`Icon` is a billboarded `Sprite3D`.

### Outdoor environment

[`res://assets/environments/outdoor_environment.tres`](../assets/environments/outdoor_environment.tres)

Reusable environment resource used by `WorldEnvironment`.

It currently provides:

- a procedural sky;
- sky and horizon colors;
- lower background colors;
- ambient outdoor lighting.

The resource can later be shared by other outdoor scenes.

Clouds, weather, and time-dependent environment changes are not implemented.

### Terrain materials

Directory:

[`res://assets/materials/terrain/`](../assets/materials/terrain)

Current materials:

- `hex_body_material.tres`;
- `clearing_surface_material.tres`;
- `forest_surface_material.tres`.

The body and terrain surface use separate materials.

### Feature visuals

Directory:

[`res://assets/visuals/features/`](../assets/visuals/features)

Current resources:

- `marsh_visual.tres`;
- `gnat_swarm_visual.tres`;
- `base_camp_visual.tres`;
- `nice_spot_visual.tres`;
- `watch_hill_visual.tres`.

### Placeholder feature texture

[`res://assets/textures/feature_placeholder.svg`](../assets/textures/feature_placeholder.svg)

Temporary diamond-shaped texture shared by all current `FeatureVisual` resources.

Feature types are currently distinguished by tint.

### Exit icon

[`res://assets/textures/ui/exit_icon.svg`](../assets/textures/ui/exit_icon.svg)

Symmetrical cross icon used by the application exit button.

### Development seed

[`res://config/world_seed.txt`](../config/world_seed.txt)

Contains the seed used for ordinary editor startup runs.

A command-line seed can override it.

Runtime generation from the interface does not rewrite this file.

---

## Ownership and relationships

The main relationships in 0.022p are:

1. The `Game` node owns the active [`World`](#world).
2. [`WorldSeedProvider`](#worldseedprovider) supplies only the initial seed.
3. [`GameInterface`](#gameinterface) emits user requests without modifying the world.
4. `Game` validates runtime seed input and decides whether to replace the world.
5. `Game` receives generated tiles from `World`.
6. `Game` passes those tiles to [`WorldView`](#worldview).
7. [`WorldDebugPrinter`](#worlddebugprinter) reads the same tiles for console output.
8. `World` stores generated [`Tile`](#tile) instances.
9. Each `Tile` owns exactly seven [`Sector`](#sector) instances.
10. Each `Sector` may reference one [`Feature`](#feature).
11. `WorldView` creates one [`HexView`](#hexview) for each displayed tile.
12. `HexView` reads a tile’s type, coordinate, and sectors.
13. `HexView` creates a [`FeatureView`](#featureview) for each occupied sector.
14. `FeatureView` reads a feature’s `type_id`.
15. [`FeatureVisual`](#featurevisual) supplies replaceable presentation settings.
16. No interface or presentation class owns simulation state.

The principal dependency direction is:

```text
Game
├── WorldSeedProvider
├── World
│   └── Tile
│       └── Sector
│           └── Feature
├── WorldView
│   └── HexView
│       └── FeatureView
│           └── FeatureVisual
├── GameInterface
└── WorldDebugPrinter
```

Requests travel from the interface to the application layer:

```text
GameInterface
    ├── world_generation_requested
    └── exit_requested
                │
                ▼
              Game
```

Generated simulation data travels toward presentation:

```text
World
  │
  ▼
Game
  │
  ├──► WorldView
  └──► WorldDebugPrinter
```

Simulation classes do not depend on interface or presentation classes.

## Current limitations

At the end of 0.022p:

- only the starting tile and its six neighbours are displayed;
- other coordinates can be generated through `World.get_tile()`, but no exploration system requests them;
- only `forest` and `clearing` terrain types exist;
- terrain uses simple placeholder materials;
- all features use one diamond-shaped placeholder texture with different tints;
- recognizable feature-specific images are not yet present;
- empty sectors have no decorative visual variants;
- undiscovered and hidden content is not implemented;
- feature interaction is not implemented;
- encounter resolution is not implemented;
- localization keys exist, but translation resources are not present;
- visibility and outlook values do not affect gameplay;
- the camera is fixed and has no runtime movement or zoom controls;
- the current world always contains only the generated starting area;
- generated worlds are not saved;
- a seed entered through the interface is not persisted to `world_seed.txt`;
- seed input accepts signed integer text but does not provide additional range controls;
- generated data is still printed to the debug console;
- the procedural environment has no clouds, weather, or animated time of day;
- the directional sun is not synchronized through a shared world clock;
- other planned gameplay layers, including sector exploration, combat, dialogue, and internal place spaces, are not implemented.

The next visualization work is expected to replace the shared feature placeholder with recognizable feature-specific images and then add deterministic decorative variants to otherwise empty sectors.

Version 0.03p remains the target for completing the first world-visualization milestone without adding player movement or interaction systems.