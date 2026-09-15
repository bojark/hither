# Hither (and Yonder)

**Hither** is a simulation-driven, semi-text RPG built with Godot.

**Made by Ivan "komurka" Kostin**

The player explores a finite, unfamiliar world one hex at a time. Its shape and many of its places are determined during play, as exploration, prior discoveries, world rules and chance interact. Once a place has been generated, it remains part of that world's history.

> Every playthrough tells the story of a world that did not exist before you entered it.

> **Status:** Early prototype development
>
> **Current version:** 0.02p
>
> **Target milestone:** 0.1p

---

## Design principles

- Simulation and world state drive play rather than a fixed sequence of events.
- Generation happens when a mechanic requests a new hex; the full map is not generated in advance.
- Generated locations and established world objects remain spatially consistent.
- What exists in the world, what the player knows and what the interface shows are distinct.
- World logic should remain independent of Godot scene nodes where practical.

Prototype 0.02p uses a world seed to reproduce terrain and sector contents at a given coordinate. Later generators may also account for exploration order, prior discoveries and changing world state, so the seed will remain one input rather than a complete predefined map.

---

## Prototype 0.1p

The first playable version is intended to provide a small, complete exploration loop:

- create a world with a specified number of non-edge hexes and generate its boundary as its shape emerges;
- move between hexes, scout neighbouring locations and interact with the current location;
- advance world time, accumulate fatigue and recover through rest;
- use a small set of hex types, including Clearing, Forest, Wasteland and Cliff;
- encounter a Base Camp and a Watch Hill;
- display a simple map and the information the player has discovered, with initial text descriptions.

The [world-generation rules](docs/worldgeneration.md) also define Hill as a hex type. NPC simulation, seasons, weather, richer events, inventory and character progression belong to later stages.

---

## Current state

Prototype 0.02p implements the simulation foundation for a starting area:

- `World`, `Tile`, `HexCoord`, `Sector` and the base `Feature` hierarchy are independent of scene presentation;
- each hex contains six directional sectors and one central sector, with at most one Feature in each sector;
- the starting Clearing and its six neighbours are generated from a world seed and retained by coordinate;
- the central sector of the starting hex always contains the unique Base Camp;
- the central sector of one neighbouring hex always contains the unique Watch Hill;
- outer sectors may contain a passive marsh, a gnat-swarm Encounter or a non-unique Nice Spot;
- the test run accepts `--seed=<number>`, uses `12345` when no valid value is provided, prints the generated area and then exits.

Movement, player knowledge and the playable exploration loop remain targets for later prototype versions. Version 0.03p is reserved for visualizing the generated starting area in Godot.

---

## Architecture

Godot handles input, UI, map and scene rendering. The simulation holds the world, its rules and the player's knowledge. The interface and future visual scene of the current hex should reveal only information available to the player. Visuals can be built independently on top of the simulation.

Each hex has six directional sectors numbered 0–5 clockwise from north, plus a central sector numbered 6. Features occupy sectors and may be passive properties, encounters requiring a decision, or optional places of interest.

See [architecture](docs/architecture.md) for the wider model and [world generation](docs/worldgeneration.md) for prototype rules.

---

## Technology

- Godot 4.7
- GDScript

---

## License

Currently not specified.
