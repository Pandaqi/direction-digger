# Direction Digger

## To-Do

Implement special cells/rules

* [x] Stone
* [x] Spider Web
* [x] Energy Magic
* [x] Ice & Lava
* [x] Arrow Treasure

Create visuals:

* One digger that's tintable and matches the style of the rest.
  * Wheels are separate and animated
  * Digging drill is separate and animated
  * **In cells, the digger is just a single sprite**
  * **When moving, the wheel/drill "pop out" and that fake digger overlay actually animates and moves where it should go.**

Other stuff (if I get stuck with things above):

* Tweaks:
  * CHECK IF ALL GOLD WAS ALREADY COLLECTED WAY BEFORE END OF PUZZLE -> Could do it brute force, or could do it in a smarter way by checking the first turn someone grabs a gold cell (taking webs into account)?
  * Allow marking treasure as "required" or "optional". If we have too much treasure at the end, we can remove some optional ones.
  * "Control" over how loose to be with arrows enabled/numbers
  * "Control" over min/max number of turns expected based on map size and machine count
  * "Control" over how many wrong/useless special tiles are added just to distract the player
* Sound Effects: Digging, Collect Treasure, Blocked, Unique stuff for terrain types
* Animations: Fake move to new cell, Digging particles, Collect Gold Particles, Transition for terrain change, Unique stuff for terrain types
* Tutorial: Audio Narration + Pointer + Images
* Difficulty Levels (can't really do them until I know all my generation rules though) + Settings
* Visuals:
  * Background slightly darker/less distracting?
  * Ensure it's always clear where all the gold is and how much you still need to grab?


## Future To-Do / Optional

GENERATION: Already decide some arrows are brittle/limited _during generation_, so we can refuse further moves based on that for more variety?

Consider an alternative OBJECTIVE of **clearing the whole screen** ("visiting every cell at least once").



## PuzzleFramework (THIS IS LATEST VERSION NOW)

* @TODO: Allow setting the _scale_ of the `give_feedback` node?
* Setting to DISABLE giving hints (in case parents want to make it harder or whatever)?
* Create some reusable module for "react to click + hover on area" as I'm retyping that code again and again now ...
* Consider moving the `is_valid()` to `PuzzleCommand` abstract class.
  * And it will always check before executing a command and not do anything if not allowed

**@IMPROV: Allow picking the VOICE TYPE in settings.** Narration can be Male voice, Female voice, or None. ===> Should be a standard feature of the PuzzleFramework probably.

**@IDEA/@IMPROV: If we ever want to support "campaigns",** I could just save the seed + some crucial detail (like machine starting pos). I can then run a debug tool to just check if that crucial detail is still the same in all generated puzzles, protecting against accidental changes in earlier campaign puzzles.


# Difficulties

## Easiest

grid_width_bounds = Vector2i(3,3)
grid_height_bounds = Vector2i(3,3)
num_turns_bounds = Vector2i(3,6)

allow_backtracking = false
arrow_max_times_used = 1
remove_all_unused_arrows = true
arrow_point_anywhere = false

## Easy


## Medium


## Hard



## Hardest

arrow_point_anywhere = true




## Notes

You play a digging machine that starts somewhere in the level. There are _arrows_ around the edges of the field (both sides of rows and columns).

On your turn, you **press one such arrow** (of the row/column that the digger is in). It will send the digger _in that direction_, as far as it can.

> **You don't get all arrows at the start.** This prevents overwhelming, but also actually makes the puzzle possible. The game only reveals the arrows you actually _need_, plus maybe a few random ones.

The goal is simply to **get to all the gold/treasure**.

