# Code Reference

**Implementation version:** 0.021p  
**Engine:** Godot 4.7  
**Language:** GDScript  
**Related document:** [`architecture.md`](architecture.md)

This document describes the classes, data structures, functions, generation flow, and presentation layer present in version 0.021p.

The source code remains authoritative for exact function signatures. This document explains the responsibilities, relationships, inputs, outputs, and current behavior of the code.

## Contents

- [Conventions](#conventions)
- [Class hierarchy](#class-hierarchy)
- [Entry point](#entry-point)
  - [Game script](#game-script)
- [Startup flow](#startup-flow)
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
- [Presentation layer](#presentation-layer)
  - [WorldView](#worldview)
  - [HexView](#hexview)
  - [FeatureView](#featureview)
  - [FeatureVisual](#featurevisual)
- [Scenes and assets](#scenes-and-assets)
- [Ownership and relationships](#ownership-and-relationships)
- [Current limitations](#current-limitations)

## Conventions

- Classes derived from `RefCounted` represent simulation data and do not belong to the Godot scene tree.
- Classes derived from `Node3D` represent objects in the three-dimensional presentation layer.
- Classes derived from `Resource` store reusable external configuration.
- Stable internal identifiers use lowercase `snake_case`, for example `forest`, `base_camp`, and `watch_hill`.
- Methods whose names begin with `_` are constructors, Godot lifecycle callbacks, or internal implementation methods.
- Axial hex coordinates use the `q` and `r` axes.
- The simulation layer does not depend on the presentation layer.
- The presentation layer reads simulation data without owning or modifying it.
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
- `Node3D`
  - [`WorldView`](#worldview)
  - [`HexView`](#hexview)
  - [`FeatureView`](#featureview)
- `Resource`
  - [`FeatureVisual`](#featurevisual)
- `RefCounted`
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

## Entry point

### Game script

**Script:** [`res://scripts/core/game.gd`](../scripts/core/game.gd)  
**Base class:** `Node`  
**Scene:** [`res://scenes/Main.tscn`](../scenes/Main.tscn)  
**Named class:** none

Coordinates project startup.

The script:

- determines the world seed;
- creates the active [`World`](#world);
- generates the starting area;
- passes generated tiles to [`WorldView`](#worldview);
- prints the generated state for debugging.

World generation and visual rendering remain delegated to their respective classes.

### Constants

#### `DEFAULT_WORLD_SEED: int = 12345`

Fallback seed used when no valid external seed can be obtained.

#### `SEED_ARGUMENT_PREFIX: String = "--seed="`

Prefix used to locate an explicit command-line seed.

Example:

`--seed=98765`

#### `WORLD_SEED_FILE_PATH: String = "res://config/world_seed.txt"`

Path to the text file used for ordinary development runs.

The file must contain one integer.

### Properties

#### `world: World`

Active generated world owned by the game script.

#### `world_view: WorldView`

Reference to the `WorldView` child node.

Initialized when the `Game` node becomes ready.

### Methods

#### `_get_startup_message() -> String`

Reads the application name and version from [`project.godot`](../project.godot).

Returns a string in this form:

`=== Hither v0.021p started ===`

#### `_get_world_seed() -> int`

Selects the seed used to generate the world.

The current priority is:

1. valid `--seed=<number>` command-line argument;
2. valid integer stored in `config/world_seed.txt`;
3. `DEFAULT_WORLD_SEED`.

An empty `--seed=` argument is treated as absent and allows the file to be read.

An invalid non-empty command-line value produces a warning and returns the default seed.

The file also falls back to the default when it:

- does not exist;
- is empty;
- does not contain a valid integer.

#### `_ready() -> void`

Godot lifecycle callback executed when the `Game` node enters the scene tree.

It performs the current startup sequence:

1. prints the startup message;
2. obtains the world seed;
3. creates a `World`;
4. generates the starting area;
5. sends the generated tiles to `WorldView`;
6. prints the generated tiles and features.

#### `_print_starting_area(starting_tiles: Array[Tile]) -> void`

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

#### `_print_tile_features(tile: Tile) -> void`

Prints every occupied sector of the supplied tile.

For each feature, it prints:

- sector index;
- readable sector position;
- feature category;
- feature type ID.

Prints `No features` when every sector is empty.

#### `_get_feature_kind(feature: Feature) -> String`

Returns a temporary readable category for a feature.

Current results:

- `encounter` for [`Encounter`](#encounter);
- `place` for [`Place`](#place);
- `feature` for other [`Feature`](#feature) instances.

#### `_get_position_name(position_index: int) -> String`

Converts a sector localization key into a temporary English name.

For example:

`sector.north_east` becomes `North East`.

This debug conversion does not replace the future localization system.

---

## Startup flow

The following sequence is executed when the project starts:

1. [`Main.tscn`](../scenes/Main.tscn) creates the `Game` node.
2. The `Game` node contains an instantiated [`WorldView`](#worldview).
3. `WorldView` and its child nodes become ready.
4. `Game._ready()` prints the application name and version.
5. `Game._get_world_seed()` determines the seed.
6. `Game` creates `World.new(world_seed)`.
7. `World.generate_starting_area()` returns seven generated tiles.
8. `Game` calls `WorldView.display_tiles(starting_tiles)`.
9. `WorldView` creates one [`HexView`](#hexview) for each tile.
10. Each `HexView` selects a terrain material and creates visual representations of occupied sectors.
11. `Game` prints the same generated data to the debug console.
12. The project remains running.

---

## World generation flow

This section describes the exact generation sequence implemented in 0.021p.

The underlying generation algorithm is unchanged from 0.02p. Version 0.021p adds visualization and an external development seed file.

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

1. A new `RandomNumberGenerator` is created.
2. The generator receives a seed derived from the tile coordinate and sector index.
3. A number from `0` to `99` is generated.
4. The result determines the content.
5. Non-empty content is placed with `Sector.set_feature()`.

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

Returns a new coordinate for the neighbouring tile in direction `direction_index`.

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

## Presentation layer

### WorldView

**Script:** [`res://scripts/presentation/world/world_view.gd`](../scripts/presentation/world/world_view.gd)  
**Scene:** [`res://scenes/world/world_view.tscn`](../scenes/world/world_view.tscn)  
**Base class:** `Node3D`

Displays generated tiles as a three-dimensional hexagonal map.

`WorldView` does not generate tiles and does not modify simulation data.

The scene also owns the current:

- orthographic camera;
- directional light;
- environment;
- blue background;
- container for generated `HexView` instances.

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

Stores the replaceable presentation settings for one feature type.

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
    └── WorldView
```

`Game` owns the simulation and calls its child `WorldView`.

### World view scene

[`res://scenes/world/world_view.tscn`](../scenes/world/world_view.tscn)

```text
WorldView
├── Tiles
├── WorldEnvironment
├── DirectionalLight3D
└── Camera3D
```

The current camera:

- uses orthographic projection;
- has a fixed isometric-style angle;
- has no runtime controls.

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

This allows the terrain surface and side walls to use independent assets.

### Feature view scene

[`res://scenes/world/feature_view.tscn`](../scenes/world/feature_view.tscn)

```text
FeatureView
└── Icon
```

`Icon` is a billboarded `Sprite3D`.

### Terrain materials

Directory:

[`res://assets/materials/terrain/`](../assets/materials/terrain)

Current materials:

- `hex_body_material.tres`;
- `clearing_surface_material.tres`;
- `forest_surface_material.tres`.

### Feature visuals

Directory:

[`res://assets/visuals/features/`](../assets/visuals/features)

Current resources:

- `marsh_visual.tres`;
- `gnat_swarm_visual.tres`;
- `base_camp_visual.tres`;
- `nice_spot_visual.tres`;
- `watch_hill_visual.tres`.

### Placeholder texture

[`res://assets/textures/feature_placeholder.svg`](../assets/textures/feature_placeholder.svg)

Temporary diamond-shaped texture shared by all current `FeatureVisual` resources.

### Development seed

[`res://config/world_seed.txt`](../config/world_seed.txt)

Contains the seed used for ordinary editor test runs.

A command-line seed can override it.

---

## Ownership and relationships

The main relationships in 0.021p are:

1. The `Game` node owns the active [`World`](#world).
2. `Game` receives generated tiles from `World`.
3. `Game` passes those tiles to [`WorldView`](#worldview).
4. `World` stores generated [`Tile`](#tile) instances.
5. Each `Tile` owns exactly seven [`Sector`](#sector) instances.
6. Each `Sector` may reference one [`Feature`](#feature).
7. `WorldView` creates one [`HexView`](#hexview) for each displayed tile.
8. `HexView` reads a tile’s type, coordinate, and sectors.
9. `HexView` creates a [`FeatureView`](#featureview) for each occupied sector.
10. `FeatureView` reads a feature’s `type_id`.
11. `FeatureVisual` supplies replaceable presentation settings.
12. No presentation class modifies or owns simulation state.

The dependency direction is:

```text
Game
├── World
│   └── Tile
│       └── Sector
│           └── Feature
└── WorldView
    └── HexView
        └── FeatureView
            └── FeatureVisual
```

Simulation classes do not depend on presentation classes.

## Current limitations

At the end of 0.021p:

- only the starting tile and its six neighbours are displayed;
- other coordinates can be generated through `World.get_tile()`, but no exploration system requests them;
- only `forest` and `clearing` terrain types exist;
- terrain uses flat-color placeholder materials;
- all features use one placeholder texture with different tints;
- empty sectors have no decorative visual variants;
- undiscovered and hidden content is not implemented;
- feature interaction is not implemented;
- encounter resolution is not implemented;
- localization keys exist, but translation resources are not present;
- visibility and outlook values do not affect gameplay;
- the camera is fixed and has no runtime movement or zoom controls;
- the sky is represented by a static blue environment color;
- the exit button planned for 0.03p is not implemented;
- generated data is still printed to the debug console.

Version 0.03p is intended to complete the first visualization milestone without adding movement, exploration interactions, or the broader game interface.