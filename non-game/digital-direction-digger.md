# Direction Digger

## To-Do

**OTHER**:

* Tutorial: Images
* (Puzzle Generation: Make it faster / more likely to succeed with high number of machines => Sometimes still breaks???)


**DIGGER:** One digger that's tintable and matches the style of the rest.
* Wheels are separate and animated
* Digging drill is separate and animated
* **In cells, the digger is just a single sprite**
* **When moving, the wheel/drill "pop out" and that fake digger overlay actually animates and moves where it should go.**









## Future To-Do / Optional

GENERATION: Already decide some arrows are brittle/limited _during generation_, so we can refuse further moves based on that for more variety?

Consider an alternative OBJECTIVE of **clearing the whole screen** ("visiting every cell at least once").



## PuzzleFramework (THIS IS LATEST VERSION NOW)

* Allow setting the _scale_ of the `give_feedback` node (and other UI elements??)
* Create some reusable module for "react to click + hover on area" as I'm retyping that code again and again now ...
  * Yes, an `Area2D` that sends these signals, plus a `set_size` function for dynamic resizing of collision shape that I often do (and an `@export` variable to set this from editor manually)
* SOME WAY TO TRACK/SAVE PROGRESS? Like "how far did the player get?" or "what's the highest difficulty they solved?" or "how long does it take them on average to solve these puzzles (in terms of time/turns)?"


**@IDEA/@IMPROV: If we ever want to support "campaigns",** I could just save the seed + some crucial detail (like machine starting pos). I can then run a debug tool to just check if that crucial detail is still the same in all generated puzzles, protecting against accidental changes in earlier campaign puzzles.


# Difficulties

## Easiest

TUTORIAL = "Press one of the arrows to move all the digging machines that it points to. Move the machines around such that you collect all the gold!"

grid_width_bounds = Vector2i(3,3)
grid_height_bounds = Vector2i(3,3)
num_turns_bounds = Vector2i(2,4)

allow_backtracking = false
add_fake_terrains = false
forbid_terrains_for_treasure = true

arrow_max_times_used = 1
arrow_randomization_prob = 0.0

terrain_types_allowed = []

## Easy

TUTORIAL = "The stone tile blocks your machine. If stone has a color, then only the machine with that color may pass through."

grid_width_bounds = Vector2i(4,4) ----> We need enough cells to ensure a stone being placed
grid_height_bounds = Vector2i(3,4) ---> Height never grows much because it's a landscape-orientation game
num_turns_bounds = Vector2i(3,5)

allow_backtracking = false
add_fake_terrains = false
forbid_terrains_for_treasure = true

arrow_max_times_used = 1
arrow_randomization_prob = 0.0

terrain_types_allowed = [CellData.TerrainType.STONE(3)]


## Medium

TUTORIAL = "The spider web always hides treasure. Every time you move through it, its number gets lower. Once the web disappears, you can finally take the treasure!"

grid_width_bounds = Vector2i(4,5)
grid_height_bounds = Vector2i(4,4)
num_turns_bounds = Vector2i(3,5)

allow_backtracking = false
add_fake_terrains = false
forbid_terrains_for_treasure = false

arrow_max_times_used = 2
arrow_randomization_prob = 0.0

special_types_allowed = [CellData.TerrainType.STONE(3), CellData.TerrainType.WEB(8)]


## Hard

TUTORIAL = "A tile with ice crystals will freeze a machine! Another machine must visit a lava tile to unfreeze you again."

grid_width_bounds = Vector2i(4,6)
grid_height_bounds = Vector2i(4,4)
num_turns_bounds = Vector2i(4,6)

allow_backtracking = true
add_fake_terrains = true
forbid_terrains_for_treasure = false

arrow_max_times_used = 2
arrow_randomization_prob = 0.15

special_types_allowed = [CellData.TerrainType.STONE(3), CellData.TerrainType.WEB(8), CellData.TerrainType.LAVA(5)]


## Hardest

TUTORIAL = "The green gemstone gives you more turns. The purple diamond gives you extra arrows."

grid_width_bounds = Vector2i(5,6)
grid_height_bounds = Vector2i(4,4)
num_turns_bounds = Vector2i(4,6)

allow_backtracking = true
add_fake_terrains = true
forbid_terrains_for_treasure = false

arrow_max_times_used = 3
arrow_randomization_prob = 0.25

special_types_allowed = [CellData.TerrainType.STONE(3), CellData.TerrainType.WEB(8), CellData.TerrainType.LAVA(5), CellData.TerrainType.ENERGY(7), CellData.TerrainType.ARROWS(6)]



## Notes

You play a digging machine that starts somewhere in the level. There are _arrows_ around the edges of the field (both sides of rows and columns).

On your turn, you **press one such arrow** (of the row/column that the digger is in). It will send the digger _in that direction_, as far as it can.

> **You don't get all arrows at the start.** This prevents overwhelming, but also actually makes the puzzle possible. The game only reveals the arrows you actually _need_, plus maybe a few random ones.

The goal is simply to **get to all the gold/treasure**.

