# Hither (and Yonder)

**Hither** is a simulation-driven, semi-text RPG built with Godot.

**Made by Ivan "komurka" Kostin**

The player explores a finite, unfamiliar world one hex at a time. Its shape and many of its places are determined during play, as exploration, prior discoveries, world rules and chance interact. Once a place has been generated, it remains part of that world's history.

> Every playthrough tells the story of a world that did not exist before you entered it.

> **Status:** Early prototype development
>
> **Current version:** 0.021p
>
> **Target milestone:** 0.1p

---

## Design principles

- Simulation and world state drive play rather than a fixed sequence of events.
- Generation happens when a mechanic requests a new hex; the full map is not generated in advance.
- Generated locations and established world objects remain spatially consistent.
- What exists in the world, what the player knows and what the interface shows are distinct.
- World logic should remain independent of Godot scene nodes where practical.
- Visual presentation should read simulation data without becoming its owner.

The current prototype uses a world seed to reproduce terrain and sector contents at a given coordinate. Later generators may also account for exploration order, prior discoveries and changing world state, so the seed will remain one input rather than a complete predefined map.

---

## Prototype 0.1p

The first playable version is intended to provide a small, complete exploration loop:

- create a world with a specified number of non-edge hexes and generate its boundary as its shape emerges;
- move between hexes, scout neighbouring locations and interact with the current location;
- advance world time, accumulate fatigue and recover through rest;
- use a small set of hex types, including Clearing, Forest, Wasteland, Hill and Cliff;
- encounter a Base Camp and a Watch Hill;
- display a simple map and the information the player has discovered, with initial text descriptions.

NPC simulation, seasons, weather, richer events, inventory and character progression belong to later stages.

---

## Current state

### Simulation foundation — 0.02p

Prototype 0.02p established the simulation foundation for a starting area:

- `World`, `Tile`, `HexCoord`, `Sector` and the base `Feature` hierarchy are independent of scene presentation;
- each hex contains six directional sectors and one central sector, with at most one Feature in each sector;
- the starting Clearing and its six neighbours are generated from a world seed and retained by coordinate;
- the central sector of the starting hex always contains the unique Base Camp;
- the central sector of one neighbouring hex always contains the unique Watch Hill;
- outer sectors may contain a passive marsh, a gnat-swarm Encounter or a non-unique Nice Spot;
- the generated starting area can be reproduced from the same seed.

### Visualization foundation — 0.021p

Prototype 0.021p begins the visualization work planned for 0.03p:

- the generated starting area is displayed as a three-dimensional hexagonal map;
- each tile is represented by a reusable `HexView` scene;
- hexes use separate body and terrain-surface meshes and materials;
- Clearing and Forest tiles receive different surface materials;
- axial coordinates are converted into positions on the three-dimensional XZ plane;
- the map uses a fixed orthographic isometric camera;
- the scene includes directional lighting, shadows and a temporary blue background;
- every hex contains seven visual sector anchors matching its simulation sectors;
- occupied sectors display billboarded placeholder sprites;
- marshes, gnat swarms, the Base Camp, Nice Spots and the Watch Hill have separate visual resources;
- feature textures, colors, sizes and vertical offsets are stored in external `FeatureVisual` resources;
- the world seed can be changed through `config/world_seed.txt`;
- `--seed=<number>` remains available as a command-line override;
- `docs/code-reference.md` documents the classes and functions present at the end of 0.02p.

The project now remains running after generation instead of terminating automatically.

To complete 0.03p, the visualization still needs its final prototype placeholders, decorative empty-sector variants and an on-screen exit button. Camera controls, gameplay interaction and other interface elements belong to later versions.

---

## Architecture

Godot handles input, UI, map and scene rendering. The simulation holds the world, its rules and the player's knowledge. The interface and visual scenes read the simulation state without owning or generating it.

Each hex has six directional sectors numbered 0–5 clockwise from north, plus a central sector numbered 6. Features occupy sectors and may be passive properties, encounters requiring a decision, or optional places of interest.

The current presentation hierarchy separates responsibilities:

- `WorldView` displays a collection of generated tiles;
- `HexView` displays one tile and its sectors;
- `FeatureView` displays one feature;
- `FeatureVisual` stores replaceable presentation settings for a feature type.

See [architecture](docs/architecture.md) for the wider model, [code reference](docs/code-reference.md) for the implemented API, and [world-generation notes](docs/worldgeneration.md) for earlier generation design notes.

---

## Technology

- Godot 4.7
- GDScript

---

## License

Currently not specified.