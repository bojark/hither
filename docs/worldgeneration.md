# World Generation

**Target milestone:** 0.1p

## Implemented in 0.02p

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
