# World Generation

**Target milestone:** 0.1p

## Implemented in 0.02p
# World Generation and Content Reference

**Target milestone:** 0.1p  
**Current implementation:** 0.022p  
**Document status:** Working design  
**Last updated:** 2026-10-20

## Purpose

This document is the working encyclopedia of Hither’s world content and the rules governing its generation, placement, discovery, interaction and persistence.

It records:

- terrain types;
- sector structure;
- Features, Encounters and Places;
- generation pools and restrictions;
- relationships between generated content;
- discovery and visibility rules;
- differences between currently implemented test rules and target behavior.

This document may change as the game design develops.

General application structure belongs in [`architecture.md`](architecture.md). Exact classes, functions and currently encoded values belong in [`code-reference.md`](code-reference.md). Version history belongs in [`chronicles.md`](chronicles.md).

## Status labels

The following labels are used throughout this document:

- **Implemented** — present in the current prototype;
- **Target 0.1p** — intended for the first playable prototype;
- **Future** — considered for a later milestone;
- **Undecided** — the concept is accepted, but its exact rule is not fixed.

A rule marked as implemented describes current behavior. A target rule may replace the current test behavior later.

## Terminology

### World

One generated playthrough with its own parameters, state and history.

### Hex

The smallest location on the world map.

The code currently calls it a `Tile`. The terms *hex*, *tile* and *cell* refer to the same world-map unit.

### Terrain type

The primary type of a whole hex.

Examples:

- Clearing;
- Forest;
- Hill;
- Wasteland;
- Cliff.

A terrain type is not a Feature and does not occupy a sector.

### Sector

A local position inside a hex.

Each hex contains six outer sectors and one central sector.

### Feature

Meaningful local content occupying one sector.

Features include passive properties, Encounters and Places.

### Encounter

A Feature that requires a decision or action and usually disappears after resolution.

### Place

A persistent Feature that offers optional interaction.

### Region

A larger contextual area containing multiple hexes.

Regions are not implemented yet.

### WorldObject

A continuous object that may cross multiple hexes, such as a river or road.

WorldObjects are not implemented yet.

## Important distinction: Hill and Watch Hill

**Hill** and **Watch Hill** are different kinds of content.

- **Hill** is a terrain type applying to an entire hex.
- **Watch Hill** is a unique Place occupying one sector inside a hex.

A Hill does not automatically contain a Watch Hill.

Under the current target rules, a Watch Hill should not be placed on Hill terrain.

## Core generation principles

### Gradual generation

**Target 0.1p**

The complete world is not generated in advance.

A new hex is generated only when a game mechanic requests it. Possible requests include:

- player movement;
- scouting;
- observation from a Place;
- another Feature;
- a world event.

Generation, discovery and visitation are different events.

A hex may:

1. be generated in the world;
2. remain unknown to the player;
3. become known without being visited;
4. later be visited and interacted with.

### Persistent results

Once a hex has been generated, its terrain type becomes part of the world’s history.

The terrain type is not expected to change during prototype 0.1p.

Features and other world state may still change through:

- player interaction;
- encounter resolution;
- world events;
- environmental changes;
- actions of other entities.

Previously established facts should not be silently regenerated into contradictory results.

### Finite world

**Target 0.1p**

The world contains a specified number of internal, non-edge hexes.

Its final shape is not stored as a predefined rectangular or hexagonal array. The shape emerges as internal hexes are generated.

After the available internal content has been exhausted, the remaining required boundary hexes become edge terrain.

### Local generation

**Target 0.1p**

When selecting the content of a new hex, the generator may consider:

- neighbouring generated hexes;
- the remaining generation pool;
- required world content;
- terrain restrictions;
- Feature restrictions;
- Regions;
- WorldObjects;
- the current world state;
- generation weights;
- the circumstances that requested generation.

The generator may evaluate whether a possible result would make the remaining world impossible to complete.

It must not assign concrete terrain types to future ungenerated coordinates merely to reserve them.

### Seed behavior

The world seed provides reproducible random choices.

The seed is one input to generation rather than a complete predefined map.

In the current prototype, the result at a coordinate is derived directly from:

- the world seed;
- the hex coordinates;
- the sector index where relevant.

This makes the test world reproducible independently of request order.

Later generation may also depend on exploration order and changing world state. In that model, the same seed reproduces the same random decisions only when the same sequence of generation requests and world changes occurs.

## Current test generator

**Implemented in 0.022p**

The current generator is deliberately small. Its purpose is to test the world model and presentation layer.

### Starting area

The generated starting area contains seven hexes:

1. the starting hex at `(0, 0)`;
2. its north neighbour;
3. its north-east neighbour;
4. its south-east neighbour;
5. its south neighbour;
6. its south-west neighbour;
7. its north-west neighbour.

The starting hex is always a Clearing.

The six neighbours are currently selected independently as either:

- Forest;
- Clearing.

Both results currently have equal probability.

### Current sector population

The starting hex is not populated through the ordinary random sector rule.

For every neighbouring hex, outer sectors `0–5` are populated independently.

| Roll | Result | Current probability |
|---:|---|---:|
| `0–69` | Empty sector | 70% |
| `70–79` | Marsh | 10% |
| `80–89` | Gnat Swarm | 10% |
| `90–99` | Nice Spot | 10% |

Central sector `6` is excluded from ordinary population.

These are temporary test probabilities rather than final balance values.

### Current unique content

- Base Camp is placed in central sector `6` of the starting hex.
- Watch Hill is placed in central sector `6` of one neighbouring hex.
- The Watch Hill location is selected reproducibly from the world seed.
- Nice Spots are non-unique and may appear more than once.

### Current storage

Generated hexes are stored by axial coordinates.

Requesting the same coordinate again returns the existing hex rather than generating another result.

## Hex directions and sectors

Each hex has six neighbours using axial coordinates.

The corresponding local sector directions are:

| Index | Direction |
|---:|---|
| `0` | North |
| `1` | North-east |
| `2` | South-east |
| `3` | South |
| `4` | South-west |
| `5` | North-west |
| `6` | Centre |

Outer sectors correspond to directions around the hex.

The central sector is intended primarily for content with a special relationship to the whole hex. It is still a sector and may contain no more than one Feature.

Sector indices are local positions inside a hex and are not world coordinates.

## Feature rules

### Sector occupancy

**Implemented**

Each sector contains either:

- no Feature;
- exactly one Feature.

A Feature cannot be added to an occupied sector without first removing its current content.

### Feature identity

**Implemented**

Every Feature has a stable internal type ID.

Examples:

- `marsh`;
- `gnat_swarm`;
- `base_camp`;
- `nice_spot`;
- `watch_hill`.

Stable IDs allow simulation, presentation and future localization data to refer to the same content without storing displayed text in game logic.

### Feature discovery

**Target 0.1p**

Generating or revealing a hex does not automatically reveal every Feature inside it.

Features may be discovered through:

- entering the hex;
- examining a sector;
- using an observation Place;
- another Feature;
- an event;
- information received through dialogue or text.

The exact discovery procedure is undecided.

### Feature influence

A Feature may optionally affect:

- movement or action cost;
- terrain behavior;
- generation weights;
- allowed neighbouring content;
- the creation of another Feature;
- the availability of interactions;
- world events.

Not every Feature must influence generation.

### Feature persistence

The expected default behavior depends on the category:

| Category | Usual persistence |
|---|---|
| Passive Feature | Remains after discovery |
| Encounter | Usually disappears after resolution |
| Place | Usually remains after interaction |

External events may still alter or remove any Feature where the content rules allow it.

## Generation pool

**Target 0.1p**

The generation pool controls the finite internal content of the world.

It is not a list of coordinates or a pre-generated map.

The intended pool contains several kinds of entries.

### Fixed entries

Fixed entries require a specific number of instances.

Possible examples:

- a required number of Hills;
- one unique settlement;
- one required Place or Region.

The exact pool for prototype 0.1p has not been selected.

### Joker entries

A Joker becomes a concrete terrain type only when generation is requested.

Its possible results are restricted by:

- remaining limits;
- neighbouring terrain;
- world rules;
- current generation weights.

Example:

If the world allows at most ten Forests and three already exist, future Jokers may produce no more than seven additional Forests.

### Unlimited entries

Some fallback terrain may be generated without consuming a limited pool entry.

Wasteland is currently intended to serve this role.

It may be selected normally or used when no other valid internal terrain can satisfy all generation rules.

## World boundary

### Edge terrain

**Target 0.1p**

Cliff is the initial edge terrain.

Cliffs form a continuous closed boundary around the internal world.

A Cliff may be generated:

- when selected by an allowed rule;
- when all internal hexes have been generated and the remaining open boundary must be closed.

The number of boundary hexes is determined by the shape produced during generation. It is not included in the requested number of internal hexes.

### Outside World

At least one side of every edge hex borders the Outside World.

The Outside World is not an ordinary playable hex.

Its exact representation is undecided.

## Visibility and discovery

### Terrain visibility

Terrain may affect what the player can observe from one hex to another.

Possible properties include:

- open sight;
- blocked sight;
- elevated sight;
- hidden terrain.

The current `Visibility` and `Outlook` values are an early technical foundation. Their final meaning and use remain subject to revision.

### Generated versus known

The simulation may contain more information than the player knows.

The world map should eventually display:

- known terrain;
- discovered Features;
- suitable representations of unknown content.

The current prototype displays every generated Feature because player knowledge is not implemented.

### Observation

Observation mechanics may request generation or reveal already generated content.

Observation should not alter a previously generated terrain type merely because it became visible.

## Terrain catalogue

## Clearing

**Internal ID:** `clearing`  
**Current status:** Implemented  
**Target role:** Open internal terrain

### Intended properties

- open terrain;
- ordinary visibility;
- relatively easy movement.

### Target generation rules

- should have at least one neighbouring Forest;
- should have at least one neighbouring open hex;
- should not become completely surrounded by Forests and Cliffs.

These restrictions are not implemented.

### Special rules

- the starting hex is always a Clearing;
- the starting Clearing always contains the unique Base Camp.

## Forest

**Internal ID:** `forest`  
**Current status:** Implemented  
**Target role:** Dense internal terrain

### Intended properties

- closed terrain;
- limited local outlook;
- encourages connected forest areas.

### Target generation rules

Forest strongly prefers neighbouring Forests.

The probability of another nearby Forest should be high but must not reach 100%.

The design goal is for a player entering a Forest to tend to remain within forest terrain for some time before reaching open ground.

These contextual weights are not implemented.

## Hill

**Provisional internal ID:** `hill`  
**Current status:** Target 0.1p  
**Target role:** Elevated terrain

### Intended properties

- high terrain;
- extended observation;
- distinct from the Watch Hill Place.

### Target generation rules

Hill is selected according to the remaining pool, restrictions and current weights.

The required or maximum number of Hills has not been fixed.

### Special rules

- a Hill never contains the Watch Hill Place;
- visiting a Hill reveals all six adjacent eligible hexes;
- Hidden terrain is not revealed by this effect.

The exact relationship between Hill terrain and longer-distance visibility remains undecided.

## Wasteland

**Provisional internal ID:** `wasteland`  
**Current status:** Target 0.1p  
**Target role:** Open fallback terrain

### Intended properties

- open terrain;
- valid ordinary generation result;
- fallback when other non-edge terrain cannot be placed legally.

### Target generation rules

Wasteland may:

- appear through normal weighted generation;
- be generated when no other valid internal terrain satisfies all applicable rules.

### Special rules

Wasteland may contain the Watch Hill Place.

## Cliff

**Provisional internal ID:** `cliff`  
**Current status:** Target 0.1p  
**Target role:** World boundary

### Intended properties

- edge terrain;
- hidden from ordinary observation where appropriate;
- impassable or otherwise limits travel;
- borders the Outside World.

### Target generation rules

Cliff may be selected through generation rules or created when the remaining boundary must be closed.

Cliffs must form a continuous boundary around the internal world.

### Special rules

- at least one side borders the Outside World;
- never contains the Watch Hill Place;
- cannot be entered through ordinary movement unless a later rule explicitly allows it.

The exact movement behavior is undecided.

## Passive Feature catalogue

## Marsh

**Internal ID:** `marsh`  
**Category:** Passive Feature  
**Current status:** Implemented as generated content

A marsh represents a waterlogged part of a hex.

### Intended behavior

- affects movement through its sector;
- may slow travel or make a route temporarily impassable;
- may influence other content or encounters;
- remains after being observed.

The exact movement cost and generation influence are undecided.

### Current generation

A marsh may appear in any outer sector of a non-starting hex produced by the current test generator.

It currently has no gameplay effect.

## Encounter catalogue

## Gnat Swarm

**Internal ID:** `gnat_swarm`  
**Category:** Encounter  
**Current status:** Implemented as generated content

A swarm of gnats requires the player to respond rather than merely observe it.

### Intended behavior

- requires an action or decision;
- may consume time or another resource;
- usually disappears after resolution.

Possible resolution methods may include avoiding it, driving it away or enduring its effect.

The exact encounter mechanics are undecided.

### Current generation

A Gnat Swarm may appear in any outer sector of a non-starting hex produced by the current test generator.

It currently has no interaction or resolution behavior.

## Place catalogue

## Base Camp

**Internal ID:** `base_camp`  
**Category:** Place  
**Uniqueness:** Unique  
**Current status:** Implemented as generated content

The Base Camp is the player’s starting place and a stable point of reference.

### Placement rules

- always occupies central sector `6`;
- always belongs to the starting Clearing;
- only one Base Camp exists in the world.

### Intended interactions

- rest;
- fatigue recovery;
- possible later storage or preparation functions.

Only placement and visualization are currently implemented.

## Watch Hill

**Internal ID:** `watch_hill`  
**Category:** Place  
**Uniqueness:** Unique  
**Current status:** Implemented as generated content

The Watch Hill is an observation Place.

It is distinct from Hill terrain.

### Current placement

In the current test generator:

- one Watch Hill is always created;
- it occupies central sector `6`;
- it is placed on one of the six neighbouring starting-area hexes;
- the selected neighbour is reproducible from the world seed;
- the neighbour may currently be either Forest or Clearing.

### Target placement rules

- never placed on Hill terrain;
- never placed on Cliff terrain;
- may be placed on Wasteland;
- placement may eventually depend on visibility and surrounding terrain.

Other permitted terrain types remain subject to balancing.

### Intended interaction

Using the Watch Hill should:

1. request generation of eligible second-ring hexes as though their adjacent first-ring hexes had been visited;
2. reveal eligible generated hexes;
3. avoid revealing Hidden terrain;
4. respect sight obstruction from intervening high terrain.

The exact visibility algorithm is undecided.

The interaction is not implemented.

## Nice Spot

**Internal ID:** `nice_spot`  
**Category:** Place  
**Uniqueness:** Non-unique  
**Current status:** Implemented as generated content

A Nice Spot is a simple example of an optional persistent Place.

### Placement rules

In the current test generator, it may appear:

- in any outer sector of a non-starting hex;
- more than once in the same world.

### Intended interaction

The final purpose of a Nice Spot is undecided.

It may eventually provide a small contextual interaction, observation, rest benefit or descriptive event.

It does not currently provide gameplay behavior.

## Regions

**Current status:** Future

A Region provides shared context for multiple hexes.

A Region may affect:

- terrain weights;
- available Features;
- descriptions;
- weather;
- encounters;
- WorldObjects;
- generation restrictions.

Possible Regions include:

- forest;
- swamp;
- settlement;
- wasteland.

Region boundaries and generation are undecided.

## WorldObjects

**Current status:** Future

A WorldObject is a continuous feature of the world that spans multiple hexes.

Examples include:

- rivers;
- roads;
- walls;
- other extended structures.

A hex stores only the local manifestation required to represent or interact with the WorldObject at that coordinate.

WorldObjects may influence terrain and Feature generation without being ordinary sector Features.

## Feature-created content

A Feature may create or request another Feature where its rules require it.

Possible examples include:

- terrain producing an Encounter;
- a Place opening access to an internal space;
- a discovered Feature enabling a related Place;
- a world event replacing one local Feature with another.

Created content must still respect sector occupancy and uniqueness rules.

No Feature-created content behavior is currently implemented.

## Internal spaces

**Current status:** Future

Some Places may contain their own explorable spaces.

Examples include:

- caves;
- buildings;
- dungeons;
- garden labyrinths;
- taverns.

An internal space is not represented by ordinary world-map sectors.

It may use:

- a square grid;
- free movement;
- a third-person view;
- another structure suited to the Place.

The Place remains the world-map connection to that internal space.

## Target generation sequence

**Target 0.1p**

A normal generation request is expected to follow this conceptual order:

1. receive a request for an ungenerated coordinate;
2. determine whether another stored hex already occupies it;
3. collect neighbouring world state;
4. inspect remaining pool entries and required content;
5. apply terrain restrictions;
6. remove results that would make the remaining world impossible;
7. calculate current weights for valid results;
8. select and store the terrain type;
9. apply Region and WorldObject relationships;
10. generate or reserve permitted sector content;
11. update the generation pool;
12. expose only the information justified by player knowledge.

This sequence is conceptual. Its implementation may be divided differently between systems.

## Starting exploration sequence

**Target 0.1p**

The expected initial exploration flow is:

1. generate the starting Clearing;
2. place the Base Camp;
3. generate the six adjacent hexes;
4. determine which information about those neighbours is initially known;
5. allow the player to move or investigate;
6. generate additional hexes when movement or observation requests them;
7. update player knowledge separately from world state.

The current prototype performs only the first three steps and displays all generated content.

## Unresolved decisions

The following rules still require design or implementation decisions:

- number of internal hexes in the first playable world;
- exact contents of the generation pool;
- minimum and maximum counts for terrain types;
- final terrain weights;
- representation of the Outside World;
- exact boundary-closing algorithm;
- Region generation;
- WorldObject generation;
- Feature discovery procedure;
- movement costs for terrain and passive Features;
- encounter resolution structure;
- Watch Hill visibility algorithm;
- use of `Visibility` and `Outlook`;
- Nice Spot interaction;
- generation and persistence of internal spaces;
- effects of exploration order on reproducibility.

These are open design questions rather than missing documentation.

## Adding new content

A new terrain type should define:

- displayed name and stable ID;
- status;
- conceptual role;
- terrain properties;
- generation restrictions;
- generation influences;
- movement and visibility behavior;
- allowed or prohibited Features;
- persistence rules where applicable.

A new Feature should define:

- displayed name and stable ID;
- category;
- uniqueness;
- status;
- allowed terrain and sectors;
- generation conditions;
- discovery conditions;
- interaction behavior;
- persistence after interaction;
- influence on other generation;
- connection to an internal space, if any.

The exact class and resource implementation should be documented separately in [`code-reference.md`](code-reference.md).
Version 0.02p provides a deliberately small, reproducible generator for testing the world model.

- A run accepts a user argument in the form `--seed=<number>` and falls back to seed `12345` when it is absent, empty or invalid.
- The starting area consists of the starting hex and its six neighbours.
- Generated hexes are stored by axial coordinate and are returned unchanged when requested again.
- The starting hex is always a Clearing at `(0, 0)`.
- Other generated hexes are currently either Forest or Clearing.
- The Base Camp is unique and occupies central sector 6 of the starting hex.
- The Watch Hill is unique and occupies central sector 6 of one neighbouring hex selected reproducibly from the world seed.
- Each outer sector independently has a 70% chance to remain empty, a 10% chance to contain a marsh Feature, a 10% chance to contain a gnat-swarm Encounter and a 10% chance to contain a non-unique Nice Spot.

These probabilities and the two available terrain types are test rules for 0.02p. The pool, boundary and contextual generation rules below describe the target for prototype 0.1p.

## Overview

The world is generated lazily.

A hex is generated only when it is first requested by a game mechanic
(player movement, observation object, etc.).

Once generated, a hex never changes its type during prototype 0.1p.

The world is finite.

When all non-edge hexes have been generated, every newly generated hex
becomes an Edge Hex (Cliff).

---

# World Pool

The world consists of a generation pool.

The pool is not a list of predefined hexes.

Instead it contains three kinds of entries.

## Fixed entries

Examples

- 3 Hills

These must appear exactly this many times.

---

## Joker entries

Most entries are Jokers.

A Joker becomes a concrete hex only at the moment of generation.

Its possible outcomes are restricted by world rules.

Example

Maximum Forests in world = 10

Already fixed Forests = 3

Therefore Jokers may generate at most 7 additional Forests.

---

## Unlimited entries

Some hexes do not require explicit pool entries.

Example

- Wasteland

Wasteland may appear whenever allowed by generation rules.

It is also used whenever no other valid non-edge hex can be generated.

---

# Generation Principles

Generation is local.

A generation request considers

- neighbouring generated hexes;
- remaining pool;
- world rules;
- generation weights.

The generator may analyse future consequences of its decision,
but may never assign types to future hexes.

---

# Visibility

Each generated hex may reveal surrounding hexes according
to its properties.

Generation and visibility are different concepts.

---

# Sectors and Features

Each hex has six outer sectors, numbered clockwise from the north: 0 north, 1 northeast, 2 southeast, 3 south, 4 southwest, and 5 northwest. Sector 6 is the centre, reserved for special features. Each sector contains at most one Feature. These local sector numbers are distinct from the hex's world coordinates.

A Feature occupies one sector and may remain undiscovered after its hex has been revealed. Features include passive properties, Encounters that require a decision and usually disappear when resolved, and Places of Interest that offer optional interaction and usually persist. A Feature may also cause another Feature to appear. In early prototypes, a Place is a single interaction point; some Places may have explorable interiors in later versions.

---

# Hex Types

## Clearing (Опушка)

Properties

- Open Hex

Generation rules

- Must have at least one neighbouring Forest.
- Must have at least one neighbouring Open Hex.
- Cannot become completely surrounded by Forests and Cliffs.

Special rules

- The starting hex is always a Clearing.
- The starting Clearing always contains the unique Place of Interest
  Base Camp.

---

## Forest (Лес)

Properties

- Dense Hex
- Visible Hex

Generation rules

- Strongly prefers neighbouring Forests.
- Probability of another Forest nearby is high,
  but never reaches 100%.

Design goal

A player entering a Forest should tend to remain
inside the forest for some time before reaching
an open area.

---

## Hill (Холм)

Properties

- High Hex
- Visible Hex

Generation rules

- Generated according to remaining pool and weights.

Special rules

- Never contains a Watch Hill Place of Interest.
- Visiting a Hill immediately reveals all six adjacent
  hexes except Hidden hexes.

---

## Wasteland (Пустырь)

Properties

- Open Hex

Generation rules

- May appear normally according to weights.
- May be generated whenever no other valid
  non-edge hex satisfies all generation rules.

Special rules

- May contain a Watch Hill Place of Interest.

---

## Cliff (Обрыв)

Properties

- Hidden Hex
- Edge Hex

Generation rules

- Represents the world's boundary.
- Generated when selected from the pool or
  automatically after all non-edge hexes have been placed.
- Edge hexes form a continuous closed border.

Special rules

- At least one side of every Cliff borders the Outside World.
- Never contains a Watch Hill Place of Interest.

---

# Places of Interest

## Base Camp

Unique.

Always generated in central sector 6 of the starting Clearing.

---

## Watch Hill

Unique exploration object.

In 0.02p it is always generated in central sector 6 of one of the six hexes neighbouring the starting Clearing. The selected neighbour is determined reproducibly by the world seed.

When used

- generates second-ring hexes as if adjacent hexes
  had been visited;
- reveals all eligible generated hexes;
- does not reveal Hidden hexes;
- visibility is blocked by High hexes located between
  the Watch Hill and target hexes.

The interaction effects above are targets for prototype 0.1p and are not implemented in 0.02p.

---

## Nice Spot

Non-unique Place used by the 0.02p generator as an example of optional sector content. It may appear in any outer sector and may occur more than once in a world.
