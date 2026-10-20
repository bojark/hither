# Hither (and Yonder)

**Hither** is a simulation-driven, semi-text RPG built with Godot.

**Made by Ivan "komurka" Kostin**

The player explores an unfamiliar world one hex at a time. Locations are generated as they become relevant, while established places remain part of that world’s history.

> Every playthrough tells the story of a world that did not exist before you entered it.

> **Status:** Early prototype development  
> **Current version:** 0.022p

## Current prototype

Version 0.022p currently provides:

- reproducible generation of a starting area from a world seed;
- a starting hex and its six axial neighbours;
- Clearing and Forest terrain;
- seven local sectors inside every hex;
- passive Features, Encounters and Places;
- a unique Base Camp and Watch Hill;
- Marshes, Gnat Swarms and non-unique Nice Spots;
- a three-dimensional isometric world-map view;
- separate materials for terrain surfaces and hex bodies;
- visual markers for generated sector content;
- a procedural outdoor environment and directional sunlight;
- runtime seed input and world regeneration;
- visible validation of invalid seed input;
- an application exit button.

The current prototype is a development foundation rather than a complete gameplay loop. Player movement, exploration interactions and world-time simulation are not implemented yet.

## Documentation

- [Architecture](docs/architecture.md) — game vision and high-level application structure;
- [World generation and content](docs/worldgeneration.md) — terrain, Features and generation rules;
- [Code reference](docs/code-reference.md) — implemented classes, functions and execution flows;
- [Development chronicle](docs/chronicles.md) — version history, current milestone and nearest development target.

## Technology

- Godot 4.7.1
- GDScript

## License

Currently not specified.