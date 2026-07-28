# World Generation (v0.1)

## Overview

The world is generated lazily.

A hex is generated only when it is first requested by a game mechanic
(player movement, observation object, etc.).

Once generated, a hex never changes its type during version 0.1.

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
- The starting Clearing always contains the unique object
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

- Never contains a Watch Hill object.
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

- May contain a Watch Hill object.

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
- Never contains a Watch Hill object.

---

# Objects

## Base Camp

Unique.

Always generated on the starting Clearing.

---

## Watch Hill

Rare exploration object.

When used

- generates second-ring hexes as if adjacent hexes
  had been visited;
- reveals all eligible generated hexes;
- does not reveal Hidden hexes;
- visibility is blocked by High hexes located between
  the Watch Hill and target hexes.