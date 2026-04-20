# Direction Digger (Devlog)

Welcome to the devlog ("developer's diary") for the educational puzzle game [Direction Digger](/puzzlepages/level-1/physical/direction-digger/). In this article I'll explain the process for creating the game and any interesting lessons learned or funny development stories. As usual, I'll try to keep it brief and simple. (Which mostly means you don't need a lot of computer knowledge to understand the technnical bits.)

## What's the idea?

I was brainstorming ideas for games about teaching directions (left, right, etc). 

At some point I remembered this old Flash game (_Motherload_) that I played a lot when I was young. You have a little digging machine and go down to dig every day, trying to get the most precious golds out of a randomized underground map, but you have to get up in time before your oil runs out.

In that game you simply move your machine with the arrow keys and work towards earning as much money as possible. It's a single player game for an older target audience.

To make it an educational puzzle game for (younger) kids, I got the idea to ...

* Give you one or more cute digging robots.
* Make your goal to **grab all the gold on the map** (nothing with numbers or reading)
* Place **arrows outside the map**: the left-hand side has arrows pointing to the right for each row, the top side has arrows pointing down for each column, etcetera.
  * Each "move" simply means tapping one such arrow to send your robot in that direction.

There were a few things I liked about the idea (and which made me develop it before some other, smaller ideas).

* It can be played multiplayer: I can add _multiple robots_ to a single puzzle map and you need to collaborate and move around each other.
* It's simpler to use/understand than, say, _swiping_ or _pressing the arrow key on your keyboard_. Tapping a big arrow on the screen to move everything that way is much more direct and tangible.
* It has massive potential for growth. For extra rules and simple twists that make the puzzle really interesting. What if you can use each arrow only once? What if a space is blocked for one machine, but not for another? Etcetera.
* I wanted to challenge myself to a slightly more complicated puzzle design. (My other ideas would mostly mean coding roughly the same simple logic behind the scenes as I've been doing for weeks now. I wanted some new and more advanced logic to figure out, and this game surely needs it.)

## Let's Make That!

At its core, generating new puzzles is very simple. (Later in this article you'll see just how much more complicated it can get once we add more rules and requirements. But we keep it simple for now.)

* Start with an empty grid.
* Place a machine somewhere.
* Move it around in random directions.

Afterwards, 

* Drop some gold/treasure in _spaces where the machine has been_. (We basically "pretend the gold was always there and we picked it up!")
* Reset the machine back to its starting position

Tada! We have a puzzle to present to the player, and we have its solution---those random moves we took.

Is it good, though? No, not really.

* You are guaranteed to win whatever you do, because you can just keep pressing arrows until you have all the gold ;)
* Random moves often create useless detours and shuffling (the machine just going back-and-forth a few times).

## Improvement 1: Limited Arrows

As we generate our puzzle, we can track how often each arrow is used. We can save that number on the arrow, and disable it once you've used it that many times. 

{{% example %}}
An arrow says "2". You click it once now, and then again a few turns later. Now the arrow is "exhausted" and you can't click it again.
{{% /example %}}

Arrows that are _not used at all_ are simply completely hidden/disabled from the start.

This already improves the puzzle and forces you to use the actual solution, instead of ... basically any other path you want.

For the easiest difficulty, though, I wanted to streamline it even more. Make it even simpler, with fewer elements on the map, with fewer ways for a player to go wrong.

As such, I added the rule that arrows _can only be used once_. As soon as the generation algorithm uses an arrow, it disables it and won't pick it again.

This automatically leads to nicer puzzles. Or, well, actual _puzzles_ in the first place. Now you can't just take _any_ path towards the gold, you have to find the path you can do _with the limited arrows you have_.

## Improvement 2: Limited Paths

Continuing on that idea, I implemented two more restrictions (that I can turn on/off as needed).

* NO SHUFFLING: Don't allow a machine to go back to its previous square.
* NO BACKTRACKING (a harsher version): Don't allow a machine to ever visit the same square twice.

This "finished" the _Easiest_ puzzles for the most part. They are nice tiny puzzles that explain the rules of the game well. The machines make sensible paths and you (usually) have to execute the exact solution as there's no other possible solution.

But of course, I picked the idea for the _multiplayer_ and _potential_. So let's talk about that.

## How to deal with multiple machines?

The simplest way to do it is just to ... place multiple machines at the start. The puzzle isn't actually moving machines, it's about _pressing arrows_---which move _all machines_ that happen to be in its row/column. So absolutely nothing else needs to change even if we add 3 or 6 more digging machines.

This isn't ideal, however, because ...

* It's not guaranteed that a machine will move. We might randomly select only ONE of them each time, never moving the others.
* It's not guaranteed that machines will _interact_. If all of them just do their own thing, taking one step, one at a time, then the point of having multiple machines is lost.

As such, I tried something new,

* Start with only ONE machine.
* After a few turns, introduce the NEXT ONE.
  * We purposely place the next one in the same row/column as the move we already selected
  * So that we know, for sure, that THIS TURN will move both those machines
* This repeats until all desired machines are added.

It's not perfect, of course. There are cases in which there simply is NO free cell in the same row/column as an existing machine, so we have to pick a random starting cell. But this leads to nice puzzles where machines interact most of the time.

Which brings me to the second question: _how do they interact?_ Do we allow multiple machines on the same square? Do they block each other? Quite quickly, I decided that the most interesting thing was to allow **only one machine per cell**. (Also the easiest thing to code ... or so I thought.)

So yes, if you try to move into a cell that already has a machine, then you can't and you stay where you are.

But then, when testing this for the first time, I realized that **this actually the code a little harder**. Because you press _arrows_ that move _all machines at once_ in that row/column. In other words, two machines could be side by side, and they should be able to both move at once in the same direction.

But ... things _can't_ happen "exactly at the same time" in programming. As in, computers execute instructions one at a time, in sequence. If we try to move machine A into the space where machine B is, it can't. We first have to move machine B _out_. So now we have this complicated chain of finding the right order in which to move things!

Instead, I opted for a simpler solution (which only works in this exact puzzle game).

* Behind the scenes, a cell can have any number of machines. It's just a list that can contain 0, 1, 2, etc machines.
* When executing a turn (_clicking an arrow_), there's a brief moment a cell may have 2 machines. 
* But I am _certain_ that by the end of that turn the other machine will have moved out too, and the cell is back to 1. (Because, again, an arrow moves ALL machines in that row/column at once.)

This works ... until you encounter the **limits of the map!** If a machine is pressed against the right edge, for example, it _can't_ go further right. In that case I _do_ have to block other machines from moving into it. Aaargh! And what if we have 3 machines in a row, the last one pressed against the edge!?

We need to think for a bit and find a cleaner, more robust solution.

## Command Validity

In these puzzle games, _everything_ that happens is a `Command`. That is, a script that knows how to DO something and how to UNDO it. (This allows the entire undo system, the hint system, clean simple code, basically only advantages.)

{{% example %}}
The `CommandMove` has a few simple lines to move a machine in a direction. The `undo()` part has the same lines of code, but with some values reversed to make the machine move back in the opposite direction (to where it came from).
{{% /example %}}

After some trial and error, I discovered a very clean way to solve all my issues in this game: by adding an `is_valid()` function to the commands. In other words, a function that evaluates _if we can do this thing_ (before we actually do it). It's so useful that it has now become a built-in thing for my Puzzle Framework, so I can immediately use it for later games.

How does it work in practice?

* When you click an arrow, it creates a `CommandArrow`. 
* This finds _all machines_ in that row/column.
* It creates a `CommandMove` for each machine.
  * If the move would send the machine off the map, it's **not valid**.
  * If the move tries to enter a cell that already has a machine, _and that machine has no valid CommandMove to get out of the way_, it's **not valid**.
* If _all_ the `CommandMove`s we made are not valid, then the entire `CommandArrow` is not valid.
* Otherwise, if at least one of them will do something, then this is a valid turn. (It's fine if SOME machines can move and SOME can't.)

At this point, the `is_valid()` function has only a few lines of code with basic checks. (Are we going off the map!? Are we blocked!?)

But it will grow as we add more features/rules. For example, 

* If we allow arrows to be locked, then `CommandArrow` is obviously **not valid** if its arrow is locked. (Can't click an arrow that's disabled!)
* If arrows can only be used a maximum number of times, then the command is **not valid** if we've exhausted the arrow!
* Etc

I hope the general idea is clear. The command already knows how to do its thing. As such, that's the best place to check if the thing _can be done_. 

When generating the puzzle, we just need to make sure we never add illegal or nothing turns. So,

* I first collect _all_ `CommandArrow`s. That is, every arrow is an option for this next turn.
* Then I filter out all of them where `is_valid()` returns false.

In practice, this becomes a chain of calls checking for validity. If the entire chain returns true, it means everyone is happy and the turn can happen. If at some points things can't do what they need to do, then the chain returns false and we will not execute this specific turn.

## Inventing More Rules

Okay, so the "core gameplay" works now. With any number of machines. No matter where they are or how they interact. And it's not just the generation; at this point I can also actually fully _see_ and _play_ the puzzles it makes. (I like to do this quite early, even when the generation algorithm is still broken, precisely because it makes finding mistakes and debugging _much easier_ if you can actually see and play through the data created.)

What about the next difficulties?

The way we generate the puzzles now is something I call the "efficient" way. The alternative is the "brute force" method: you simply create completely random puzzles, then _check_ all possible moves to see if it _has a solution_. The code for that method is always identical---make a random map, try all moves---but it's obviously incredibly slow. My old broken laptop would take 30 seconds to find a puzzle :p And so I'm basically forced to generate puzzles the "smarter" way.

The downside of this ... is that every single rule in your puzzle requires a unique "smart" implementation. For every rule I want to add, I have to make sure there is a way to _include it in the generation algorithm_. A way to make all the logic hold up, and the algorithm _fast_.

To keep things simple for myself, I decided to connect these rules to **special squares**. Each square has a terrain type. The basic one (... mud?) just does nothing special. But other types work differently or do something to your machine when you enter it.

Now I'll briefly talk about the unique steps taken for every individual _terrain type_.

Keep in mind that we never select cells that already _have_ a type. I've kept that step out of the explanations below to keep them simple. But once a cell has been assigned a terrain type, then we never override it (never consider it for anything else), as that would break all the logic.

### Stone

This **blocks you**. I initially wasn't a fan of this, until I realized it could **selectively block**. For example, Machine Red can go through it, but not Machine Green!

How do we add this to the algorithm? After creating the solution, 

* We check for squares where **nobody has been**: with some probability, place a block there.
* We check for squares where **one player has been**: with some probability, place a block there that _only allows them to go through_.

### Spider Web

This **blocks treasure**. As long as this type is on the cell, you don't get the gold by visiting the cell.

I was thinking about how digging games usually have some "hard" type that requires _multiple attempts_ ("multiple digs") to finally break. Some type you have to "wear down".

At first, it seemed a bit silly to add this to my puzzle game. It doesn't matter if you "wear it down" by going through several times, because your goal is to get the gold, not clear the whole map or something.

But right when I thought that, it hit me: "duh, it _does_ work if we make it _block the gold_"!

How do we add this to the algorithm? After creating the solution, 

* We select all **squares that have been visited multiple times**.
* With some probability, we **turn them into this terrain** (and add treasure/gold if it doesn't have it already)
* Set the **number** to **how many times the square was visited**.
* (If all the visits were by the same machine, we can make this _selective_ too. So only _that_ machine can wear it down.)

Now we know that the final machine to visit that space will finally break the type and get the gold.

We can make it more varied by randomizing that number. Maybe 3 machines visit this square, but we only give it the number 2 so that the _second_ machine picks up the gold.



### Arrow Treasure

This **gives you more arrows**. In other words, by passing through this space, you get more movement options in the future.

Each square on the map has four arrows that can act on it (left/right/up/down). This square can, thus, give you 1--4 arrows back.

How do we add this to the algorithm? After creating the solution, 

* We check all squares that **were visited** (at least once).
* We grab the **four arrows** acting on this square.
* We check which ones **have not been used yet** before this point.
* Now (with some probability) we can **remove those arrows** and **place this terrain** (that will give them back once visited)

Like before, we're basically saying "in hindsight, let's pretend this block was always here and gives us exactly the arrows we need!" 

This works both for enabling/disabling arrows, as well as simply _raising the number_ on an arrow so you can use that one more often.


### Ice & Lava

As expected, this **freezes** and **unfreezes** machines. Machines that run into Ice can't move anymore. Once anyone visits Lava, all the frozen machines become normal again.

How do we add this to the algorithm? After creating the solution, 

* For each machine, check for _gaps_ in their movement. That is, they move a few times, then _don't move_ for five turns, then they move again.
* Turn the **last cell** we visited (before falling still) into **Ice**.
* Within that gap, turn a random cell (that some other machine visits) into **Lava**.
* (Any cells _before then_, visited by a _different machine_, can turn into **Ice** too if we want.)

This is a relatively simple way to allow a lot of variety in how things are frozen and unfrozen. Because it requires multiple eligible cells, it's less likely that we can actually _do_ this though. As such, this check comes _before_ the other ones, when the map is still mostly empty and a few Ice/Lava cells will fit.



### Energy Magic

This **gives you more turns**. There was a point when I considered an entire oil/energy mechanic for each machine, but this just became convoluted and unnecessary, especially when you play with multiple machines. So, instead, there's just a single "energy bar" showing how many turns you have, and these terrains play with that.

How do we add this to the algorithm? After creating the solution,

* Check the squares visited **from back to front**. (So, final square visited first, then penultimate square, etc)
* With some probability, turn this square into an **energy one**, and **reduce** the turn count (told to the player) by 1.
* IMPORTANT: If the turn when we visit this square is _equal_ to the current turn count, then we **can't do this**.
  * Because, if we reduce the turn count by 1 now ... then the player will not have enough _to actually get to us_. So the puzzle is not solvable anymore.
  * That's why we go back to front. As we place these squares, the turn count keeps dropping, and we need to make sure we're still able to reach these cells.

This was definitely the most tricky one to implement. Minor mistakes here lead to completely unsolvable puzzles (because you run out of turns halfway through). Even worse, some moves can move 2 or 3 machines at once, so you can earn _multiple moves_ back ... in one move. I also decided to introduce this one last, because it requires a lot of counting and number knowledge (which young players might not have) and only becomes interesting on big puzzles (with a lot of turns).

## Tweaking, Tweaking, Tweaking

After implementing everything there always comes the time for finding all sorts of tiny bugs and issues and ways that the algorithm can get off track. In the end, I implemented some ~15 extra "checks". They either clean up the puzzle, or discard it because it's "not good enough". (In which case the algorithm just tries again from scratch.)

To give some examples,

* Count the treasure (a _ratio_ of `num_treasure_cells` / `num_total_cells`). If too low, discard. If too high, remove some "optional" treasures ( = those placed along the path, not the final cell of a machine) to get back into range.
* Check _when_ a cell with treasure is visited for the first time (and thus the treasure collected). If the last move of the puzzle does not collect treasure, then part of the solution is "useless", so discard.
* Similarly, count how often a machine moves (in total), and how often it moves _between_ collecting treasures.
  * If a machine moves only once or twice, that's too little, so discard.
  * If a machine takes too long between treasures, it's likely shuffling aimlessly for a bit. We _could_ allow this, but I just don't like the puzzles that come out of that, so discard.
* On harder difficulties, introduce "red herrings": fake elements that are not part of the solution to distract the player. This makes the puzzles much harder (because you're not sure which of the arrows/elements you actually need), but also messier and less "pure" (so I made it a setting that you can turn off).
  * I basically defined a `generate_fake()` function for every terrain type that will randomly pick unused cells (that nobody ever visits in the perfect solution) and turn them into that type.
  * Some types have extra conditions just to make it a little nicer. For example, too many lava cells makes a puzzle meh (too easy to unfreeze anyone, looks overwhelming), so lava has a lower chance of placing fake versions.
* The grid size increases with difficulty, but only _horizontally_. The height of the map stays pretty much constant, because the game is in landscape mode (like most screens) and we just don't have that much vertical space.
  * Also, if you're playing with a _lot_ of machines, it overrides the grid size of your difficulty settings with the minimum it needs just to place everything.
* Similarly, I initially made a variable `num_turns_per_machine`, and just multiplied that by the number of machines to get the total number of turns this puzzle should have. The problem?
  * On high difficulties you have this huge map, but if you only have 1 or 2 machines ... then they're basically sticking to a corner and not actually visiting most of the map.
  * Conversely, on low difficulties and with 4(+) machines, space is too tight and most machines just can't move.
  * To solve it, I simply made the total number of turns **depend on grid size**, and the average turns we'd want for a machine is just `total / num_machines`. This ensures there are always enough squares to hit that number of turns and visit most of the map with your solution.

And more tiny stuff and bug fixes. Half of which I discovered->researched->fixed so quickly that I don't really remember doing so right now :p

Anyway, they end result is an algorithm that generates nice, balanced, playable, diverse puzzles at all difficulties and settings. The Easiest mode has tiny 3x3 grids that can still support multiple machines and be actually interesting puzzles. The Hardest mode has a much larger grid, all special types enabled, easily fits 6 players/machines, and even adults won't solve those first try.


## Conclusion

There are always some more things to tweak or tiny ideas I want to try out. (If an idea takes 5 minutes to implement, then it's basically always worth trying, even if it's completely silly and likely to not be in the final game.)

On higher difficulties, the maps get larger and more terrain types can be placed, but that's pretty standard.

I experimented with letting arrows **point in any direction** (instead of always pointing _into_ the map). My code handles that just fine without changes. It's _great_ practice for directions! But this simple change makes puzzles _so much harder_ that I left it for the harder difficulties only.

I experimented with forcing you to grab the gold _in order_. This actually makes puzzles much **easier** because you know the general order of things, but it's a nice way to practice **counting**. For that reason, I made it a _setting_ you can turn on/off if you want.

As for the visuals, I asked AI to generate a few things, made a few things myself, and tried to turn it all into a unified whole that clearly has this muddy, organic, underground, rough, digging for gold vibe. The tricky thing here is to make it look "good" instead of just ugly or broken. To make it look appealing still, instead of some brown dirty mess. The first iteration had that problem; later iterations of the visuals basically became shinier, more abstract, and more colorful each time to combat this.

After some more work with sound effects, particles, tutorial, and more ... the game was done! It was certainly the biggest challenge in terms of logic,generating the puzzles, getting guarantees about if interactions are valid. I learned some new things that will surely help with later puzzle games. 

I was also surprised by just how well this simple puzzle mechanic worked. I obviously made it _because I felt there was potential_, but I often found myself just randomly playing a few puzzles and completely forgetting that I booted the game to test some new feature. Though the rules are simple, the puzzles are not boring or obvious.

I'll probably recommend this one as the most all-round solid puzzle game (about directions and early counting) on the store. Until I make something else I like even more, probably.

Until the next devlog,

Pandaqi