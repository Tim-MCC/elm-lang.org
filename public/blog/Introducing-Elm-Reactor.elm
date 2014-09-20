import Website.Skeleton (skeleton)
import Window

port title : String
port title = "Introducing: Elm-Reactor"

main = lift (skeleton "Blog" everything) Window.dimensions

everything wid =
  let w  = truncate (toFloat wid * 0.8)
      w' = min 600 w
      section txt =
          let words = width w' txt in
          container w (heightOf words) middle words
  in
  flow down
  [ width w pageTitle
  , section content
  , width w example
  , section workflow
  , section closing
  ]

pageTitle = [markdown|
<br/>
<div style="font-family: futura, 'century gothic', 'twentieth century', calibri, verdana, helvetica, arial; text-align: center;">
<div style="font-size: 4em;">Introducing Elm Reactor</div>
<div style="font-size: 1.5em;">An Interactive Programming Tool</div>
</div>
|]

content = [markdown|

<p style="text-align: right;">
By <a href="http://github.com/michaelbjames">Michael James</a>
</p>

Elm Reactor is a development tool that gives you the power to time-travel.
Pause, rewind, and unpause any Elm program to find bugs and explore the
interaction space. Elm Reactor swaps in new code upon saving, letting you know
immediately if your bug fix or feature works. This way it&rsquo;s easy to tweak
layout, play with colors, and quickly explore ideas. Elm has prototyped [these
features](http://debug.elm-lang.org/) before, but **Elm Reactor polishes them in
an [easy-to-install package][install]** that can be used with any text editor.
You can start using it for your projects today.

[install]: https://github.com/elm-lang/elm-platform#elm-platform

The following demo shows someone fixing a bug in a TodoMVC app written with
[elm-html](/blog/Blazing-Fast-Html.em). Any task marked as complete should not appear under
&ldquo;Active Tasks&rdquo;, but this bug mistakes completed tasks for active tasks.
Watch them find the bug, fix the code, see the fix propagate
automatically, and rewind the program to verify the fix.

<img src="/imgs/reactor-post/fold.gif" style="width:600px; height:364px;">

Elm Reactor grew out of my internship working on Elm at Prezi this summer. It
combines the time-traveling debugger prototype created by Laszlo Pandy and Evan
Czaplicki along with the modular design of Elm to make a practical development
tool. It harnesses the recent features of Elm to give the debugging process a
much needed upgrade.

# Ultimate Undo Button

Elm Reactor lets you travel back in time. You can pause the execution of your
program, rewind to any earlier point, and start running again. Watch me misplace
a line piece and correct my mistake:

<img src="/imgs/reactor-post/tetris.gif" style="width:600px; height:306px;">

In this example, I paused the game, went back, and continued to avoid crushing
defeat. This is what &ldquo;time-traveling&rdquo; means in Elm Reactor. It lets
you:

* Pause a running program
* Step backwards and forwards in time
* Continue from any point in the program&rsquo;s past

This sort of time traveling lets you explore the interaction space of your
program faster. Imagine debugging an online checkout page. You want to
verify that the error messages look right. There are several dozen
ways to trigger an error message (e.g., bad phone number, no last name, etc.).
Traditionally you would need to repeat the entire transaction for each error,
slowly going crazy as you re-enter the same data for the 13th time. Elm
Reactor lets you rewind to any point, making it easy to explore an alternate
interaction. The next few sections will describe how Elm Reactor makes this
possible.

### Recording Inputs

All input sources to an Elm program are managed by the runtime and known
statically at compile-time. You declare that your game will be expecting
keypresses and mouse clicks. This makes the inputs easy to track. The first step
in time-traveling is to know your history, so Elm Reactor records these input
events.

The next step is to pause time. The following diagram shows how an event such as
a keypress or mouse click comes to the Elm runtime. When an event happens, it is
shown on the &ldquo;Real Time&rdquo; graph and when your program receives the
event, it is shown on the &ldquo;Elm Time&rdquo;. When Elm Reactor pauses Elm,
the program stops receiving inputs from the real world until Elm is unpaused.


<img src="/imgs/reactor-post/timeline-pause.png" style="width:600px; height:200px;">

Events in Elm have a time associated with them. So that Elm does not get a hole
in its perception of time, Elm Reactor offsets that recorded time by the time
spent paused. The combination of event value and time means that these events
can be replayed at any speed (read: really fast).

### Safe Replay

Elm functions are pure, meaning they don&rsquo;t write to files, mutate state,
or have other side-effects. Since they don&rsquo;t modify the world, functions
are free to be replayed, without restriction.

Elm programs may have state, even though all functions are pure. The
runtime stores this state, not your program. The input events dictate how the
state will change when your program is running. Because this internal state is
determined entirely by the recorded input events, Elm Reactor can transition to
any state. Transitioning is restricted to only mutating to the next state
becuase an input cannot be undone. So, to transition to any point in time, you
must replay the events leading up to that point.

The simple approach to time-traveling is to start from the beginning and replay
everything up to the desired event. So if you wanted to step to the 1000th
event, you would have to replay 1000 events. Elm Reactor uses *snapshotting* to
avoid replaying so many events.

### Snapshotting

Snapshotting is to save the state of your application in a way that can be
restored. Elm&rsquo;s version of [FRP](/learn/What-is-FRP.elm) makes this
straightforward and cheap. There is a clean separation of code and data: the
application data is totally separate from the runtime. So to snapshot an Elm
application we only have to save the **application data** and not implementation
details like the state of the stack, heap, or current line number. This is most
equivalent to saving the model in MVC.

Elm Reactor takes a snapshot every 100 events. This means jumping to any event
from any other takes no more than 100 event replays. For example, to jump to
event #199 from event #1000 Elm Reactor first restores the snapshot at event
#100, then applies the next 99 recorded events. A better user experience
strategy to snapshotting could ensure time-traveling never takes more than N
milliseconds. This could be done by timing each round of computation and
snapshotting every N milliseconds. Instead Elm Reactor uses the simpler
snapshot-every-Nth strategy for its initial release.

# Changing History

In addition to time-traveling, Elm Reactor lets you change history. Since
Elm Reactor records the entire history of inputs to the program, we can simply
replay these inputs on new code to see a bug fix or watch how things change.

<img src="/imgs/reactor-post/swap.gif" style="width:600px; height:364px;">

In this example, Mario&rsquo;s image URL and gravity were set incorrectly. Mario
had already made a few jumps and time had passed. But the functions that control
Mario could be swapped out because the functions are independent from their
inputs. So despite having played with Mario, Elm Reactor can still swap in new code.

Playing a game while you build it is quite nice, but this is also remarkably handy
for more typical applications. In the checkout example we described earlier,
perhaps the last screen misplaced a close button. Once you navigate to that
page, Elm Reactor lets you mess with the code as much as you want while you find
the right place for the close button. You can see the results of your new code
without maddeningly running through the entire interaction each time!

In real life, it&rsquo;s easy to get time-traveling wrong. People are always
disappearing from photographs and kissing grandparents. Elm Reactor will only
swap in *valid* programs. If a potential program has a type error or syntax
error, then Elm Reactor does not swap in the new code. Instead, Elm Reactor overlays
an error message explaining the issue and the last working version keeps running.

<img src="/imgs/reactor-post/error.gif" style="width:600px; height:364px;">

# Try it yourself!

You can hide the debugging panel by clicking on the tab.
|]

example = [markdown|
<iframe src="http://debug.elm-lang.org/edit/Thwomp.elm?cols=100%25%2C150px" frameborder="0" style="overflow:hidden; height:400px; width:100%" height="400px" width="100%"></iframe>
|]

workflow = [markdown|

# In your workflow

Elm Reactor will work with any pure Elm project. Use it with  [elm-html][],
[elm-webgl][], [elm-d3][], or any other renderer.

[elm-html]: /blog/Blazing-Fast-Html.elm
[elm-webgl]: /blog/announce/0.12.3.elm
[elm-d3]: https://github.com/seliopou/elm-d3

<img style="width:200px; height:100px;" src="/imgs/reactor-post/elm-html.png">
<img style="width:190px; height:100px;" src="/imgs/reactor-post/elm-webgl.png">
<img style="width:200px; height:100px;" src="/imgs/reactor-post/elm-d3.png">

Elm Reactor can also integrate with your favorite editor. The code
swapping is editor-agnostic; it just watches your project directory for file
saves. There is no need for an emacs, Sublime Text, or vim plug-in. It just
works!

That applies for multi-module projects, too! Whenever Elm Reactor detects a file
change, it tries to recompile the main Elm file, which recompiles any
dependencies. For more information about using the debugger in your own
workflow, check out the [repository](https://github.com/elm-lang/elm-reactor).|]

closing = [markdown|
# What&rsquo;s next

This is the first public release of Elm Reactor. There are many useful ideas
and plans that didn&rsquo;t make it in the first version. The long-term vision
includes:

* **REPL in the Reactor** - A [read-eval-print loop][repl] (REPL) is super
useful for testing specific functions in a large project. Imagine an in-browser
REPL that knows about your code so you can explore an idea in a scratchpad or
make sure a function does what you expect.

[repl]: http://en.wikipedia.org/wiki/Read%E2%80%93eval%E2%80%93print_loop

* **Ports** - [Ports][] make it easy for Elm programs to send messages to and
from JS, where there may be all sorts of side-effects. It is not immediately
obvious how ports will work with time-traveling. The easy solution is to never
send values out of ports, avoiding unwanted side-effects like appending too many
times as we rewind. But *some* ports are safe to replay.

[ports]: /learn/Ports.elm

* **Hot-swapping** - Hot-swapping lets you keep the current state of a program
but change its future behavior. Some fast-paced Elm games may want this feature
to avoid the cost of replaying all events when swapping code. This has
already been implemented for Elm [as described here][hotswap], so the technical
part should be straight-forward.

[hotswap]: /blog/Interactive-Programming.elm

* **Save Event Sequences** - Elm Reactor already saves inputs to a program. If
you could give these inputs to someone else, you could easily file an
informative bug report that shows *exactly* how to reproduce an error.

* **Improved visualizations** - It may help to use techniques like
[sparklines](http://en.wikipedia.org/wiki/Sparkline) to visualize
tracked values (e.g., mouse position).

* **Plug-ins** - Elm Reactor may be a nice way to expose lots of functionality
in browsers with a nice UI. A plug-in system would make it easier for the Elm
community to make editor-agnostic tools.

There are a lot of great ideas that can make Elm Reactor even more
powerful. If you&rsquo;re interested, check out
[the repository](https://github.com/elm-lang/elm-reactor/)
and the [community][]. We will be happy to help get you
started on a project.

[community]: https://groups.google.com/forum/#!forum/elm-discuss

# Thank You

Thank you Evan Czaplicki for your guidance, wisdom, and patience while writing
this. You taught me an astonishing amount about FRP and rigour this summer.
I&rsquo;m so grateful for the methodologies I picked up from you.

Thank you to Laszlo Pandy who demonstrated the possibility of debugging like
this by writing the prototype Elm debugger. Thanks Gábor Hoffer and the Prezi
design team for the suggestions on making the debugging tab pretty!

Thank you to Bret Victor, whose talk,
[&ldquo;Inventing on Principle&rdquo;](https://www.youtube.com/watch?v=PUv66718DII) offered
valuable insight into what the debugging experience should be like.

|]