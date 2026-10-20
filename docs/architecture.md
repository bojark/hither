# Hither Architecture

**Target milestone:** 0.1p  
**Current implementation:** 0.022p  
**Document status:** Working design  
**Last updated:** 2026-10-20

## Purpose

This document records the current vision for Hither and the general structure of the application.

It includes both implemented foundations and planned systems. These are design intentions rather than immutable rules and may change as the project develops.

Implementation details, individual classes and function signatures belong in the [code reference](code-reference.md). Content definitions and generation rules belong in the [world-generation reference](worldgeneration.md).

## Documentation structure

Each project document has a distinct purpose:

- [`README.md`](../README.md) — short project introduction and a concise description of the current playable functionality;
- `architecture.md` — game vision, conceptual model and high-level application structure;
- [`worldgeneration.md`](worldgeneration.md) — content encyclopedia and rules governing terrain, Features, generation and their interactions;
- [`code-reference.md`](code-reference.md) — implemented classes, properties, functions and execution flows;
- [`chronicles.md`](chronicles.md) — completed versions, development history, current milestone and nearest target.

Information should be defined in one primary document and linked from the others rather than repeated.

## Game concept

Hither is a simulation-driven, semi-text RPG about exploring an unfamiliar finite world.

The player acts as an explorer and cartographer. Exploration gradually reduces the uncertainty of the world: new locations receive definite content when generation is requested, while already established locations remain part of that world’s history.

The world is intended to exist independently of the player and change over time. Player actions, previous discoveries, global rules, local conditions and chance may all affect what is generated next.

## Design intentions

- The complete world is not generated in advance.
- Generated locations remain spatially and historically consistent.
- World state, player knowledge and displayed information are separate.
- Exploration and most meaningful actions consume world time.
- The simulation should remain independent of Godot scenes where practical.
- Interface and presentation code may request or display changes but should not own the simulation.
- New mechanics should be added without requiring a complete restructuring of the existing model.
- The same simulation state should be usable by different presentation scenes.

## Conceptual game model

### World

A `World` represents one playthrough.

The intended world model includes:

- immutable parameters selected when the world is created;
- mutable world state;
- generated hexes;
- regions and extended world objects;
- active entities;
- world time;
- rules that influence future generation.

The current implementation stores a generation seed and generated tiles. Other parts of the model will be added as they become necessary.

### Hex

A hex is the smallest world-map location.

The code currently calls it a `Tile`. The terms *hex*, *tile* and *cell* refer to the same map unit unless a more specific distinction is introduced later.

Hexes use axial `q` and `r` coordinates and have six neighbours.

A hex contains seven internal sectors but is not itself composed of seven smaller world-map hexes.

### Sector

A sector is a local position inside a hex.

The six outer sectors are numbered clockwise from north:

| Index | Direction |
|---:|---|
| `0` | North |
| `1` | North-east |
| `2` | South-east |
| `3` | South |
| `4` | South-west |
| `5` | North-west |
| `6` | Centre |

Sector numbers support orientation, local placement and generated text.

Each sector may contain no more than one Feature.

### Feature

A Feature is meaningful local content occupying a sector.

A Feature may remain unknown after its hex has been generated or discovered. Generation, discovery and interaction are separate events.

The main conceptual categories are:

- **passive Feature** — affects the hex or actions within it and is usually observed rather than directly used;
- **Encounter** — requires a decision or action and usually disappears after resolution;
- **Place** — offers optional interaction and usually persists.

Some Places may later provide their own explorable spaces, such as buildings, caves, dungeons or labyrinths. In early versions they remain single interaction points.

### Terrain and Features

A terrain type describes the whole hex. A Feature occupies one sector inside that hex.

Similar names do not imply that they are the same kind of object. For example:

- **Hill** is a terrain type;
- **Watch Hill** is a Place of Interest.

Their exact rules and relationships belong in [`worldgeneration.md`](worldgeneration.md).

### Region

A Region is a larger area that provides context for multiple hexes.

Examples may include forests, swamps, settlements or other coherent areas. A Region is not itself a hex and may affect terrain and Feature generation within it.

Regions are planned but not implemented.

### WorldObject

A WorldObject is a continuous object that may extend across multiple hexes.

Examples may include roads and rivers. Individual hexes contain local manifestations of the larger object.

WorldObjects are planned but not implemented.

### Entity

An Entity has its own state and may act or move independently.

The Player and NPCs are entities rather than Features. An NPC may temporarily occupy a hex or sector but is not part of that location’s fixed Feature content.

Entities are planned but not implemented.

## State and knowledge

The architecture distinguishes four related forms of data:

### World state

What currently exists in the simulated world, whether or not the player knows about it.

### Player knowledge

What the player has discovered about the world.

A generated hex or Feature may exist without being known to the player.

### Presentation state

What a particular scene currently displays and how it displays it.

Presentation state includes camera position, selected objects, open interface elements and temporary visual effects. It must not replace simulation state.

### Persistent history

Generated locations, resolved encounters, world changes and other established facts may become part of the playthrough’s history.

The exact save format has not been designed.

## High-level application structure

The intended dependency direction is:

```text
Input and interface
        │
        ▼
Application coordination
        │
        ▼
Simulation and player knowledge
        │
        ▼
Presentation data
        │
        ▼
Visual scenes and audio
```

The simulation must not depend on the scenes that display it.

The current 0.022p structure is:

```text
Game
├── World
│   └── Tile
│       └── Sector
│           └── Feature
├── WorldSeedProvider
├── WorldDebugPrinter
├── GameInterface
└── WorldView
    └── HexView
        └── FeatureView
            └── FeatureVisual
```

This is the current implementation, not a required final class hierarchy.

### Simulation

The simulation owns world state and rules.

Current simulation classes use `RefCounted` and do not belong to the scene tree.

Implemented foundations include:

- `World`;
- axial coordinates;
- terrain tiles;
- seven sectors per tile;
- the Feature hierarchy;
- reproducible generation of the starting area.

### Application coordination

The application layer connects simulation, interface and presentation.

`Game` currently owns the active `World`, handles application-level requests and sends generated data to the world view.

Supporting services currently include:

- `WorldSeedProvider` for initial seed selection;
- `WorldDebugPrinter` for temporary diagnostic output.

These responsibilities may be reorganized as the application grows.

### Interface

The interface collects player input and communicates requests through signals.

It should not directly own or modify the simulated world.

The current `GameInterface` provides:

- seed input;
- a world-regeneration request;
- visible invalid-input feedback;
- an application-exit request.

This is development-oriented interface functionality rather than the final game UI.

### Presentation

Presentation converts available game data into scenes, visuals, text and sound.

The current world-map presentation consists of:

- `WorldView` for the displayed map;
- `HexView` for one hex;
- `FeatureView` for one visible Feature;
- `FeatureVisual` resources for replaceable visual settings.

The current presentation receives complete generated tiles directly. Once player knowledge is implemented, presentation should receive only information available to the player.

## Presentation contexts

Hither is expected to use several presentation contexts for the same simulated world.

### World map

An isometric three-dimensional map used for orientation and movement between hexes.

Each terrain type has its own visual appearance. Features are displayed in their sectors when they are known to the player. Empty or unknown sectors use suitable terrain decoration.

This is the presentation context currently being developed.

### Hex and sector exploration

A separate scene for examining or moving within the current hex or one of its sectors.

Its camera and controls may differ from the world map.

### Interactions

Combat, dialogue and other focused interactions may use dedicated scenes or interfaces.

### Internal spaces

Some Places may later open their own navigable spaces.

An internal space may represent a dungeon, building, cave, garden or other contained location. It may use a square grid, free movement or another structure suitable for that Place.

All presentation contexts should read and update the same underlying world state rather than creating separate versions of the world.

## Reusable visual resources

Visual configuration should remain replaceable without changing simulation classes.

The current project stores terrain materials, Feature visuals and the outdoor environment as external resources.

Exterior scenes may share:

- sky and atmospheric settings;
- terrain and object materials;
- visual definitions;
- time-of-day information.

Individual scenes may still use their own cameras, local lights and composition.

## World time

World time is intended to be part of simulation state.

Actions such as movement, exploration and interaction consume time. The initial design uses four broad periods:

- morning;
- day;
- evening;
- night.

The current expected default duration is six hours per period, while ordinary movement to a neighbouring hex is expected to take one hour. These values may change during implementation and balancing.

A future shared time service or `WorldClock` should provide a common time value to all gameplay and presentation contexts.

Presentation systems may derive the following from that value:

- sun direction;
- light color and intensity;
- sky appearance;
- environmental effects;
- time-dependent interface information.

Individual scenes should not maintain separate unsynchronized clocks.

World time is not implemented in 0.022p.

## World generation

The world is intended to be finite and generated gradually when requested by game mechanics.

The generator may consider:

- world parameters;
- previously generated locations;
- neighbouring hexes;
- remaining required content;
- terrain and Feature rules;
- current world state;
- controlled random selection.

A seed is one input to generation rather than a complete predefined map.

The current prototype uses a simpler coordinate-based deterministic generator so that tests can be repeated independently of exploration order.

Detailed terrain definitions, generation pools, probabilities, placement restrictions and Feature interactions belong in [`worldgeneration.md`](worldgeneration.md).

## Player

The Player represents the playable character.

The intended Player state may include:

- current location;
- attributes and health;
- fatigue;
- inventory;
- knowledge of the world;
- other temporary or persistent conditions.

The first playable prototype is expected to include location, exploration, world knowledge, fatigue and rest.

The Player model is not implemented in 0.022p.

## NPCs

NPCs are intended to be independent entities with their own state.

The architecture should allow NPCs to:

- move through the world;
- react to world changes and player actions;
- interact with other entities;
- appear, disappear or die;
- continue acting independently of direct player observation.

Detailed NPC simulation belongs to a later milestone.

## Target prototype 0.1p

The target for 0.1p is a small but complete exploration loop.

The player should be able to:

- create a finite world;
- explore it one hex at a time;
- discover neighbouring locations;
- view discovered information on the map;
- interact with initial Features and Places;
- spend world time;
- accumulate fatigue;
- return to the Base Camp and rest.

The prototype should include a small initial set of terrain and content. Their definitions and generation rules are maintained in [`worldgeneration.md`](worldgeneration.md).

## Current architectural foundation

Version 0.022p currently provides:

- reproducible generation of a seven-hex starting area;
- axial hex coordinates;
- terrain tiles with seven internal sectors;
- passive Features, Encounters and Places;
- a unique Base Camp and Watch Hill;
- three-dimensional world-map presentation;
- external terrain, Feature and environment resources;
- a fixed orthographic map camera;
- an outdoor environment and directional sun;
- runtime seed input and world regeneration;
- an application exit control;
- separation between simulation, interface and presentation responsibilities.

This foundation is incomplete and does not yet constitute the target exploration loop.

## Future directions

Possible later systems include:

- weather and seasons;
- richer encounters;
- inventory and character development;
- NPC simulation;
- quests and economy;
- long-lived characters across multiple worlds;
- death, inheritance and world succession;
- expanded internal spaces;
- additional world and interaction presentation modes.

These directions remain provisional and do not define the scope of 0.1p.