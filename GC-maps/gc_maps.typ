#import "@preview/touying:0.8.0": *
#import themes.simple: *
#import "@preview/fletcher:0.5.8" as fletcher: node, edge
#import "@preview/fletcher:0.5.8" as fletcher: diagram
#import "@preview/cetz:0.4.2"
#import "@preview/pinit:0.2.2": *

#import "@preview/theorion:0.4.1": *
#show: show-theorion


#let fletcher-diagram = touying-reducer.with(
  reduce: fletcher.diagram,
  cover: fletcher.hide,
)
#let cetz-canvas = touying-reducer.with(
  reduce: cetz.canvas,
  cover: cetz.draw.hide.with(bounds: true),
)

#show: simple-theme.with(
  aspect-ratio: "16-9",
  config-common(frozen-counters: (theorem-counter,),),
)

#set text(font: "New Computer Modern")
#set math.text(font: "New Computer Modern Math")

#show strong: it => text(fill: blue, weight: "bold")[#it]

#show raw: it => {
  show regex("pin\d"): it => pin(eval(it.text.slice(3)))
  it
}

#let blue_color(it) = text(fill: blue)[#it]
#let red_color(it) = text(fill: red)[#it]
#let pink_color(it) = text(fill: fuchsia)[#it]

// ---------- shared drawing helpers ----------

// arrow with a proper head in any direction
#let arrow(a, b, stroke: 1.5pt + black) = cetz.draw.line(
  a, b, stroke: stroke, mark: (end: "straight"),
)

// a stack frame as a column of raw 64-bit values
#let stack-vals = (
  "0x00007F3A1C402A10",
  "0x000000000000002A",
  "0x00007F3A1C402B88",
  "0x00000000DEADBEEF",
  "0x00007F3A1C402A10",
)

#let stack-column(highlight: ()) = {
  import cetz.draw: *
  for (i, v) in stack-vals.enumerate() {
    let y = -i * 1.2
    let fill = if i in highlight { orange.lighten(70%) } else { none }
    rect((0, y), (8, y - 1), stroke: 1.5pt + black, fill: fill)
    content((4, y - 0.5))[#text(size: 18pt)[#raw(v)]]
  }
}


#title-slide([
  = GC maps: how the collector finds your pointers

  Salimov Rustam 26162
  #place(right + bottom)[year 2026]
  #place(left + bottom)[🗺️]
])

// =====================================================================
== Quick recap

#slide(repeat: 5, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon, dy: -1em)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      let obj((x, y), name) = {
        rect((x - 1.5, y - 0.5), (x + 1.5, y + 0.5), radius: 4pt)
        content((x, y))[#name]
      }

      let hl((x, y), color: green) = {
        rect((x - 1.5, y - 0.5), (x + 1.5, y + 0.5), radius: 4pt, stroke: 2pt + color)
      }

      content((0, 0.6))[Roots]
      line((-2, 0), (2, 0))

      obj((0, -1))[$A$]
      obj((0, -2.5))[$B$]
      obj((0, -4))[$C$]

      arrow((1.5, -1), (3.5, -1))
      obj((5, -1))[$A_1$]
      arrow((6.5, -1), (8.5, -1))
      obj((10, -1))[$A_2$]

      arrow((1.5, -2.5), (3.5, -2.5))
      obj((5, -2.5))[$B_1$]

      obj((16, -1))[$F$]
      obj((16, -2.5))[$G_1$]
      obj((16, -4.5))[$G_2$]
      arrow((15.3, -3), (15.3, -4))
      arrow((16.7, -4), (16.7, -3))

      uncover("2-", {
        hl((0, -1))
        hl((0, -2.5))
        hl((0, -4))
      })

      uncover("3-", {
        hl((5, -1))
        hl((10, -1))
        hl((5, -2.5))
      })

      uncover("4-5", {
        hl((16, -1), color: orange)
        hl((16, -2.5), color: orange)
        hl((16, -4.5), color: orange)
      })
    })
  ]

  #uncover("1-")[
    #place(bottom + center, dy: -0.5em)[
      Roots = *local variables on the stack*, globals, registers.\
      #uncover("5-")[But how do we *read* the stack?]
    ]
  ]
])

// =====================================================================
== The stack is just bytes

#place(left + horizon)[
  #cetz.canvas({
    import cetz.draw: *
    content((4, 0.8))[stack frame]
    stack-column()
  })
]

#place(right + horizon)[
  #set align(left)
  In your code: `Point p`, `int n`

  #pause
  After compilation: *just 64-bit numbers*

  #pause
  Which of them are *pointers*?

  #pause
  Address? Integer? Hash code?
]

// =====================================================================
== Why guessing wrong is fatal

#slide(repeat: 5, self => [
  #let (uncover, only, alternatives) = utils.methods(self)
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,
  [
    *Missed a pointer*

    #cetz.canvas({
      import cetz.draw: *
      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      rect((0, 0), (3, -1), stroke: 1.5pt + black)
      content((1.5, -0.5))[`p`]
      arrow((3, -0.5), (6, -0.5))

      uncover("-1", {
        rect((6, 0), (10, -1), stroke: 1.5pt)
      })
      uncover("2-", {
        rect((6, 0), (10, -1), stroke: 1.5pt + red)
      })
      content((8, -0.5))[`Point`]

      uncover("2-", {
        line((6, 0), (10, -1), stroke: 2pt + red)
        line((6, -1), (10, 0), stroke: 2pt + red)
        content((8, -1.7))[freed by GC]
      })
    })

    #uncover("3-")[
      → *dangling pointer* again, \
      but now caused by the runtime
    ]
  ],
  [
    #uncover("4-")[
    *Number taken for a pointer*

    #set text(size: 18pt)
    ```java
    long id = 0x7F3A1C402B88;
    // GC moves the object "at" that address
    // and fixes every pointer to it...
    ```
    ]
    #uncover("5-")[
    ```java
    id == 0x7F3A1C409F00   // ?!
    ```
    #set text(size: 20pt)
    → your data *silently changes*
    ]
  ],
)
])

// =====================================================================
== Option 1: be conservative

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)
  #let step = self.subslide

  #place(center + horizon)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      stack-column(highlight: if step >= 2 { (0, 2, 4) } else { () })

      uncover("2-", {
        rect((12, 0.5), (22, -5.5), stroke: (paint: gray, thickness: 1.5pt, dash: "dashed"))
        content((17, 1))[heap: `0x7F3A1C400000` ... `0x7F3A1C4FFFFF`]
      })

      uncover("3-", {
        rect((14, -0.3), (18, -1.3), stroke: 1.5pt + black)
        content((16, -0.8))[$X$]
        content((19, -0.8))[🔒]

        rect((14, -2.7), (18, -3.7), stroke: 1.5pt + black)
        content((16, -3.2))[$Y$]
        content((19, -3.2))[🔒]

        arrow((8, -0.5), (14, -0.8), stroke: 1.5pt + orange)
        arrow((8, -5.3), (14, -1.1), stroke: 1.5pt + orange)
        arrow((8, -2.9), (14, -3.2), stroke: 1.5pt + orange)

        content((17, -4.7))[*can't move!*]
      })
    })
  ]

  #only("1")[
    #place(bottom + center, dy: -0.5em)[Idea: don't even try to know]
  ]
  #only("2")[
    #place(bottom + center, dy: -0.5em)[Anything that *looks like* a heap address is a pointer]
  ]
  #only("3")[
    #place(bottom + center, dy: -0.5em)[It might be an integer, so we must not "fix" it]
  ]
])

---

#v(1fr)
#red_color[+] No help from the compiler needed: works even for C/C++

#pause
#v(0.5fr)
#red_color[−] Numbers that look like pointers keep garbage alive

#pause
#v(0.5fr)
#red_color[−] Objects referenced from the stack *can't be moved* → no compaction

#pause
#v(1fr)
Used by: *Boehm GC*, WebKit's *JavaScriptCore* (for the stack)
#v(1fr)

// =====================================================================
== Option 2: ask the compiler

#place(center + horizon)[
  #fletcher-diagram(
    spacing: (4em, 2em),
    node-stroke: 1.5pt,
    node-corner-radius: 4pt,
    node-inset: 12pt,
    node((0, 1), [Source code \ `Point p; int n;`]),
    edge((0, 1), (1, 1), "-|>"),
    node((1, 1), [Compiler]),
    pause,
    edge((1, 1), (2, 0), "-|>"),
    node((2, 0), [Machine code \ just bytes]),
    pause,
    edge((1, 1), (2, 2), "-|>"),
    node((2, 2), [*GC map* \ where the pointers are], stroke: 1.5pt + blue),
  )
]

#pause

#place(bottom + left, block(width: 17em)[
  For a point in the code: *which stack slots and registers hold reference* 
])

---

#v(1fr)
The compiler *knew the types all along*: let it write them down

#pause
#v(0.5fr)
GC stops a thread → looks up the map → knows *exactly* what is a pointer

#pause
#v(0.5fr)
Nothing is guessed → objects *can move* freely

#pause
#v(0.5fr)
This is called *precise* (or *exact*) GC
#v(1fr)

// =====================================================================
== A worked example

#let example-rows = (
  ([1], [`compute()`], [`p`], [slot + 16]),
  ([2], [`new Point`], [`p`, `q`], [slot + 16]),
  ([3], [`log()`], [`q`], [reg `RBX`]),
  ([4], [`render()`], [—], [—]),
)

#slide(repeat: 5, self => [
  #let (uncover, only, alternatives) = utils.methods(self)
  #let step = self.subslide

  #grid(
    columns: (1.3fr, 1fr),
    gutter: 1.5em,
    [
      #set text(size: 18pt)
      ```java
      void draw() {
          Point p = new Point(1, 2);
          int n = pin1compute()pin2;           // 1
          Point q = pin3new Point(n, n)pin4;   // 2
          pin5log(p.x)pin6;                    // 3
          pin7render(q)pin8;                   // 4
      }
      ```
    ],
    [
      #set text(size: 18pt)
      #table(
        columns: 4,
        align: center + horizon,
        inset: 8pt,
        fill: (x, y) => if y == step and step <= 4 { yellow.lighten(60%) },
        table.header([], [*Call*], [*Live refs*], [*Where*]),
        ..example-rows
          .enumerate()
          .map(((i, r)) => r.map(c => uncover(str(i + 1) + "-", c)))
          .flatten(),
      )
    ],
  )

  #for i in range(1, 5) {
    only(i)[#pinit-highlight(2 * i - 1, 2 * i, extended-height: -0.6em, dy: 0.1em)]
  }

  #only("1")[
    #place(bottom + center, dy: -0.5em)[`n` is an `int` → *never listed*]
  ]
  #only("5")[
    #place(bottom + center, dy: -0.5em)[
      `p` is *dead* after 3 → it can be collected *while still in scope*!
    ]
  ]
])

// =====================================================================
== Safepoints

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon, dy: -1em)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      line((0, 0), (22, 0), stroke: 2pt + black, mark: (end: "straight"))
      content((22, -0.8))[time]

      for x in range(1, 22) {
        line((x, 0.2), (x, -0.2), stroke: 1pt + black)
      }

      let sps = ((4, [call]), (9, [alloc]), (14, [loop back-edge]), (19, [return]))
      for (x, label) in sps {
        circle((x, 0), radius: 0.3, fill: orange, stroke: none)
        content((x, -1))[#label]
      }

      uncover("2-", {
        arrow((6, -2.5), (6, -0.4), stroke: 1.5pt + blue)
        content((6, -4))[#blue_color[GC requested]]

        arrow((9, 2.5), (9, 0.4), stroke: 1.5pt + green)
        content((9, 3))[thread parks here]
      })
    })
  ]

  #only("1")[
    #place(bottom + center, dy: -0.5em)[
      A map for *every* instruction is too big → maps only at *safepoints*
    ]
  ]
  #only("2-")[
    #place(bottom + center, dy: -0.5em)[
      GC can stop a thread *only at a safepoint* #uncover("3-")[\ (like an elevator: only at floors)]
    ]
  ]
])

// =====================================================================
== Time to safepoint

#place(center + horizon, dy: -1em)[
  #cetz-canvas({
    import cetz.draw: *

    let parks = (5, 4, 6, none)

    for (i, park) in parks.enumerate() {
      let y = -i * 1.5
      content((-1.2, y))[T#(i + 1)]
      if park == none {
        line((0, y), (18, y), stroke: 3pt + red)
        content((9, y - 0.8))[#red_color[hot loop without safepoint checks]]
      } else {
        line((0, y), (park, y), stroke: 3pt + black)
        line((park, y), (18, y), stroke: (paint: gray, thickness: 3pt, dash: "dashed"))
        circle((park, y), radius: 0.25, fill: orange, stroke: none)
      }
    }

    line((3, 1), (3, -4.9), stroke: (paint: blue, thickness: 1.5pt, dash: "dashed"))
    content((3, 1.5))[#blue_color[GC requested]]

    (pause,)

    line((18, 1), (18, -5.5), stroke: 2pt + green)
    content((18, 1.5))[GC can start]
  })
]


#place(bottom + center, dy: -0.5em)[*Everyone waits for the slowest thread*]

---

How runtimes fight it:

#pause
- *Java HotSpot*: used to drop checks from counted loops; now splits long loops into chunks

#pause
- *.NET*: some methods are "fully interruptible": a map at *every* instruction

#pause
- *Go 1.14+*: interrupts a stuck thread with an *OS signal*,
  scans that innermost frame *conservatively*

#pause
#align(center)[Precise and conservative approaches *meet*]

// =====================================================================
== Walking the stack

#slide(repeat: 4, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon, dy: -1em)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      let frame(y, name, note) = {
        rect((0, y), (8, y - 2), stroke: 1.5pt + black)
        content((4, y - 0.6))[*#name*]
        content((4, y - 1.4))[#text(size: 16pt)[#note]]
      }

      let map-box(y, title, body) = {
        rect((12, y), (21, y - 1.6), stroke: 1.5pt + blue, radius: 4pt)
        content((16.5, y - 0.5))[#text(size: 16pt)[#title]]
        content((16.5, y - 1.1))[#text(size: 16pt)[#body]]
      }

      content((4, 1))[stack]
      frame(0, [compute], [allocating → *GC triggered*])
      frame(-2.2, [draw], [stopped at call compute])
      frame(-4.4, [main], [stopped at call `draw()`])

      uncover("2-", {
        arrow((8, -0.8), (12, -0.8), stroke: 1.5pt + blue)
        content((10, -0.3))[#text(size: 14pt)[pc]]
        map-box(0, [map: compute \@ alloc], [no live refs])
      })

      uncover("3-", {
        arrow((8, -0.8), (12, -3), stroke: 1.5pt + blue)
        content((10, -2.5), angle: -30deg)[#text(size: 14pt)[ret addr]]
        map-box(-2.2, [map: draw \@ compute], [`p` → slot +16])
      })

      uncover("4-", {
        arrow((8, -3), (12, -5.2), stroke: 1.5pt + blue)
        content((10, -4.7), angle: -30deg)[#text(size: 14pt)[ret addr]]
        map-box(-4.4, [map: main \@ call], [`scene` → slot +8])
      })
    })
  ]

  #uncover("4-")[
    #place(bottom + center, dy: -0.5em)[
      Every frame below the top is stopped *at a call* → *return address* is the key to its map
    ]
  ]
])

// =====================================================================
== The tricky part: derived pointers

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(top + center, dy: 3em)[
    #set text(size: 18pt)
    ```c
    for (p = &a[0]; p < end; p++) sum += *p;   // what the JIT may produce
    ```
  ]

  #place(center + horizon, dy: 1em)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      let array(x0, y0, color: black) = {
        for i in range(6) {
          rect((x0 + i * 2, y0), (x0 + i * 2 + 2, y0 - 1), stroke: 1.5pt + color)
          content((x0 + i * 2 + 1, y0 - 0.5))[#text(fill: color)[$a_#i$]]
        }
      }

      let ptr(x, y0, label, color: black) = {
        arrow((x, y0 + 1.5), (x, y0 + 0.1), stroke: 1.5pt + color)
        content((x, y0 + 2))[#text(fill: color)[#label]]
      }

      only("1", {
        array(1, 0)
        ptr(2, 0, [base])
        ptr(8, 0, [cursor])
      })

      uncover("2-", {
        array(1, 0, color: gray)
        content((7, -1.6))[#text(fill: gray)[old location]]

        arrow((7, -2.2), (10, -3.4), stroke: (paint: gray, thickness: 1.5pt, dash: "dashed"))

        array(10, -4)
        ptr(11, -4, [base'])
        ptr(17, -4, [cursor'])
      })
    })
  ]

  #only("1")[
    #place(bottom + center, dy: -0.5em)[`cursor` points into the *middle* of an object]
  ]
  #only("2")[
    #place(bottom + center, dy: -0.5em)[The array moved: `cursor` must move too]
  ]
  #only("3")[
    #place(bottom + center, dy: -0.5em)[
      Map entry: `cursor = base + offset` → move `base`, re-apply `offset`
    ]
  ]
])

// =====================================================================
== Where you'll find them

#grid(
  columns: (1fr, 1fr),
  gutter: 2em,
  [
    *Precise (GC maps)*

    - Java HotSpot: _OopMaps_
    #pause
    - .NET: _GC info_ from the JIT
    #pause
    - Go: stack maps in every binary
    #pause
    - V8: safepoint tables
    #pause
    - LLVM: _statepoints_
    #only(7)[- *Kotlin*: I am currently working on]
  ],
  [
    #pause
    *Conservative stack scanning*

    - Boehm GC (C/C++)
    - WebKit's JavaScriptCore
  ],
)

// =====================================================================
== The cost of precision

GC maps are *not free*

#pause

- Maps take *space*: runtimes compress them heavily

#pause

- They *restrict the optimizer*: references must be where the map says

#pause

- Safepoint checks cost a little *on every loop*

#pause

#align(center)[But they make *moving collectors* possible: compaction, generations]

// =====================================================================
== Takeaways

#v(1fr)
1. After compilation a pointer is *just a number*: GC maps restore the types.
#pause
#v(.5fr)
2. Maps exist only at *safepoints*: threads must reach one before GC runs.
#pause
#v(.5fr)
3. Precise maps let objects *move*; conservative scanning trades that for *simplicity*.
#v(1fr)
