# Direction Digger

## To-Do

* VISUALIZE what's happening
* CommandMove should check if it _can_ move there.   ==> Consider a general `is_valid()` function required of commands, which checks if it CAN be executed---or should it check if it HAS been executed/DONE something???
* Filter our all illegal/nothing moves.
  * See @TODOs
  * Setting to limit arrow usage to only once.
  * Setting to forbid digger from visiting any cell they've been before. (And/or just forbid going in REVERSE, back to where you came from.)
  * 




## Notes -> CLEAN UP THIS MESS

You play a digging machine that starts somewhere in the level. There are _arrows_ around the edges of the field (both sides of rows and columns).

On your turn, you **press one such arrow** (of the row/column that the digger is in). It will send the digger _in that direction_, as far as it can.

> **You don't get all arrows at the start.** This prevents overwhelming, but also actually makes the puzzle possible. The game only reveals the arrows you actually _need_, plus maybe a few random ones.

At first, the goal is simply to **get to the gold** (or maybe **clear the whole screen**?).

* Later Levels = Multiple gold pieces that you all need to grab.
* Later Levels = Blocks that you can't pass through
* Later Levels = Blocks that you can "wear down" if you hit them often enough  ---> but then what's the point of wearing them down if you can already move through them? ----> This only makes sense if the blocks have **different colors** and only block _one specific machine_.
* Later Levels = A way to lock/unlock arrows at the sides => 
  * Pass through this block to get the arrows shown on that row/column. (This could be 1--4 of them.)

**@IDEA: MULTIPLE MACHINES!** 

* Some arrows only match with one machine (based on color/shape/whatever)
* Some will move _both_ if they happen to be in the same row/column
  * All machines are moved in tandem. (This is simply the easiest way to pick random moves and make sure they avoid each other.)
  * But their starting positions are not decided beforehand ---> later machines start in such a way that they align (row/column) with an earlier machine that has already moved. This ensures there is at least one "double move" turn if we want it.

**@IDEA:** Blocks that give you **more turns** if you move through them. (So a kind of oil/energy blocks.)
--> GENERATION = Place the block, reduce turn count told to player by 1, ensure turn count is still higher than the turn when we grab this thing.

**@IDEA:** Blocks that _freeze_ a machine---you need _another_ machine to unfreeze it.
--> GENERATION = Pick the machine that has not moved for the longest. Turn their current cell into a "freeze". Turn the current cell of _this_ machine into an "unfreeze".
--> GENERATION (ALTERNATIVE) = When it _switches_ to a new machine moving (from previous turn), pretend the new machine's current cell was a FREEZE all the time, and pretend the previous machine's current cell was an UNFREEZE all the time.



**@IDEA: You can set this in the settings.** So _you_ decide with how many people/diggers you want to play. And that's what goes into the generation. ====> This is a major selling point. _One of the rare puzzle games that allows playing with multiple people, each trying to solve their own digger's path, but helping each other at some points._

**@IMPROV: Allow picking the VOICE TYPE in settings.** Narration can be Male voice, Female voice, or None. ===> Should be a standard feature of the PuzzleFramework probably.

**@IDEA/@IMPROV: If we ever want to support "campaigns",** I could just save the seed + some crucial detail (like machine starting pos). I can then run a debug tool to just check if that crucial detail is still the same in all generated puzzles, protecting against accidental changes in earlier campaign puzzles.


**@IDEA**: Arrows that can only be used once or twice! "Brittle arrows" that are clearly different and once used can't be tapped again. ---> This is also easy to generate, as we can just calculate how often arrows were used and make most 1-time used arrow "brittle". (Can also limit this during generation by pre-deciding some arrows are brittle and refusing further moves along that axis!)

Yes, the game (and generation algorithm) should mostly be about those ARROWS at the edges, as they directly teach directions and control the entire puzzle in an easy way.

**Do arrows simply disappear BY DEFAULT and the game is over once you've used them all?** This might be a really tight way to do it, OR it might make solutions too obvious/simple. Perhaps it's more thematic to display some ENERGY meter or OIL bar, stating how much energy the machine still has. (When running low, machines might start to make a tired face and puffing smoke and stuff.)

* Yes, use this "all arrows can only be used once, perfectly use them all to solve it" on EASIEST DIFFICULTY. (Makes for easier puzzles and explanation.)
* Then, later, introduce the OIL/ENERGY idea and blocks for it.



FROM WEBPAGE

The puzzle contains 5 difficulty levels. Later difficulties add,

* More directions
* Larger grids with larger solutions
* Arrows that you still need to unlock, or which destroy themselves after using them once
* Blocks that force you to go around them or go through them multiple times
* And maybe some more special things to collect or find underground ...