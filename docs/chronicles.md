# Hither Development Chronicle

This document records completed prototype versions, the current milestone and the nearest development target.

---

## Current Milestone

### Prototype 0.1p

The first playable version is intended to provide a small, complete exploration loop:

- create a world with a specified number of non-edge hexes and generate its boundary as its shape emerges;
- move between hexes, scout neighbouring locations and interact with the current location;
- advance world time, accumulate fatigue and recover through rest;
- use a small set of hex types, including Clearing, Forest, Wasteland, Hill and Cliff;
- encounter a Base Camp and a Watch Hill;
- display a simple map and the information the player has discovered, with initial text descriptions.

NPC simulation, seasons, weather, richer events, inventory and character progression belong to later stages.

---

## Nearest Target

### World visualization — 0.03p

Prototype 0.03p is intended to complete the first visual representation of the generated world.

The remaining work is:

- create readable prototype placeholders for the implemented Feature types;
- add decorative visual variants for empty sectors;
- keep decorative selection reproducible for the same world seed and coordinates;
- add a red exit button with a white cross in the upper-right corner;
- verify that every generated tile, terrain type and occupied sector is displayed correctly;
- update the project version and documentation to 0.03p.

Camera controls, player movement, hex interaction and other interface elements belong to later versions.

---

## History

### Project foundation — 0.01p

**Date:** 2026-07-27

Prototype 0.01p established the initial Godot project and its architectural direction:

- the Godot 4.7 project and main scene were created;
- the `Game` node and startup script were added as the application entry point;
- the first minimal `World` class was created and instantiated when the game started;
- core scripts were placed under `scripts/core`;
- the project was configured to use Forward+ rendering and Jolt Physics;
- the initial repository structure, README and architecture document were created;
- the separation between Godot presentation and independent simulation logic was established as a design principle.

This version did not yet generate a playable world. Its purpose was to establish the project structure and define the intended architecture.

### Simulation foundation — 0.02p

**Date:** 2026-09-15

Prototype 0.02p established the simulation foundation for a starting area:

- `World`, `Tile`, `HexCoord`, `Sector` and the base `Feature` hierarchy are independent of scene presentation;
- each hex contains six directional sectors and one central sector, with at most one Feature in each sector;
- the starting Clearing and its six neighbours are generated from a world seed and retained by coordinate;
- the central sector of the starting hex always contains the unique Base Camp;
- the central sector of one neighbouring hex always contains the unique Watch Hill;
- outer sectors may contain a passive marsh, a gnat-swarm Encounter or a non-unique Nice Spot;
- the generated starting area can be reproduced from the same seed.

### Visualization foundation — 0.021p

**Date:** 2026-10-13

Prototype 0.021p began the visualization work planned for 0.03p:

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
- `docs/code-reference.md` documents the classes and functions implemented through version 0.021p.

The project now remains running after generation instead of terminating automatically.