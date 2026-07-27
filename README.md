# Hither (and Yonder)

**Hither** is a simulation-driven, semi-text RPG built with Godot.

**Made by Ivan "komurka" Kostin**

The project focuses on creating a living world where exploration emerges from simulation rather than scripted events.

> Every playthrough tells the story of a world that did not exist before you entered it.
>
> Every journey takes place in a newly generated world. The player explores an unknown land one location at a time, making decisions, facing dangers, meeting people and uncovering places that have never existed before.

> **Status:** Early development

---

## Philosophy

The game follows a simulation-first approach.

Godot is primarily used as an engine for rendering, input and UI, while the game logic is implemented independently from scene nodes whenever possible.

Core principles:

- simulation over scripting;
- deterministic world generation;
- emergent gameplay;
- modular architecture;
- code that can be tested independently from the engine.

---

## Current Features

- World class
- Project architecture
- Design documentation

The gameplay systems are currently under active development.

---

## Planned Systems

- Procedural world generation
- Regions
- Cells
- Features
- Interactive objects
- NPC simulation
- Time and seasons
- Weather
- Events
- Exploration
- Perils
- Inventory
- Character progression

---

## Project Structure

```text
docs/
    architecture.md

scripts/
    core/
        game.gd
        world.gd
```

---

## Documentation

Project documentation is located in the `docs` directory.

Currently available:

- `architecture.md`

Additional documents will describe world generation, events, combat, characters and other systems.

---

## Technology

- Godot 4.7
- GDScript

---

## Development Status

Hither is currently in the architecture phase.

The primary goal at this stage is to design robust and extensible gameplay systems before implementing game mechanics and content.

---

## License

Currently not specified.