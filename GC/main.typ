
#import "@local/touying:0.8.0": *
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

#let find = math.op[find]
#let partial = math.op[partial]
#let pf = math.op[PF]

#let link = math.op[link]
#let union = math.op[union]

#let size = math.op[size]
#let rank = math.op[rank]
#let parent(x) = [#math.op[parent]$[#x]$]

#let tow = math.op[tow]

#let time = math.op[time]

#let arr(size: 2em, ..x) = {
  cetz-canvas({
    import cetz.draw: *

    for (i, elem) in x.pos().enumerate() {
      content((i * size, 0))[#box(
          stroke: black,
          height: size,
          width: size,
        )[#align(center + horizon)[#text(size: size / 2)[#elem]]]]
      content((i * size, -size))[#text(size: size / 2)[#i]]
    }
  })
}

#let mem(size, color) = {
  cetz-canvas({
    import cetz.draw: *

    rect((0, 0), (size, 1), stroke: color + 2pt)
  })
}

#show raw: it => {
  show regex("pin\d"): it => pin(eval(it.text.slice(3)))
  it
}

#let blue_color(it) = text(fill: blue)[#it]
#let red_color(it) = text(fill: red)[#it]
#let pink_color(it) = text(fill: fuchsia)[#it]


#title-slide([
  = What is GC in programming

  Salimov Rustam 26162
  #place(right + bottom)[year 2026]
  #place(left + bottom)[🚮]
])

== Line that isn't there

#[
#set text(size: 20pt)
```C
// C
typedef struct { int x, y; } Point;

Point *p = malloc(sizeof(Point));pin1
p->x = 1; p->y = 2;pin2
free(p);pin3
```

#pinit-point-from(1)[allocating memory]
#pause
#pinit-point-from(2)[using memory]
#pause
#pinit-point-from(3)[*freeing memory*]
#pause


#h(1fr)
#box()[
```Python
# Python
class Point:
    def __init__(self, x, y): ...

p = Point(1, 2)pin4
p.x, p.ypin5
```
]
#pause
#pinit-point-from(4)[allocating memory]
#pause
#pinit-point-from(5)[using memory]
#pause
#place(dx: 0em, dy: -1em, text(size:2em)[*Where is free?* #pause *GC!*])
]

== The goal, not the mechanism

Amount of memory your program needs:

#mem(10, blue)

#pause

Amount of memory your computer has:

#mem(20, orange)

#pause

#align(center)[*GC not needed!*]

---

Amount of memory your program needs:

#mem(21, blue)

Amount of memory your computer has:

#mem(20, orange)

---

Amount of memory your program needs:

#mem(21, blue)

Amount of memory your computer has:

#mem(200, orange)

#pause

To make the program thinks that you computer has $infinity$ memory

== What manual memory managment costs


#place(left + horizon)[
  #{
    set text(size:20pt)
    ```C
    Point *p = malloc(sizeof(Point));
    ...
    p->x = 1; p->y = 2;
    ...
    fpin7ree(p);pin8
    ```
    only(3)[
      ```C
      ...
      pin1printf("%d, p->x);pin2
      ```
    ]
  }

  #only(2)[
    It is called *leak*
  ]
  #only(3)[
    It is called *dangling pointer*
  ]
]

#only(2)[#pinit-line(7,8, stroke: 2pt + red, start-dx: -0.5em, start-dy: -0.3em, end-dy: -0.3em)]
#only(3)[#pinit-highlight(1,2, dx: -1.5em, extended-width: 1.5em, extended-height: -0.1em, dy: 0.3em)]

#place(right + horizon)[
  What can possibly go wrong?
  #pause
  + *Forget* about allocation
  #pause
  + Use after *free*
]

#pause

#place(bottom + center)[
  #{
    cetz-canvas({
      import cetz.draw: *

      line((0, 0), (20, 0), stroke: black + 2pt)
      line((20, 0), (19.5, 0.2), stroke: black + 2pt)
      line((20, 0), (19.5, -0.2), stroke: black + 2pt)

      circle((5, 0), radius: 4pt, fill: blue, stroke: blue)
      content((5, 1))[bug]


      (pause, )

      circle((15, 0), radius: 4pt, fill: orange, stroke: orange)
      content((15, 1))[CRASH]

      (pause, )

      content((15, -1))[not guaranteed]
      line((5.8, 1), (13.3, 1))

      line((5.8, 1), (6.1, 1.1))
      line((5.8, 1), (6.1, 0.9))

      line((13.3, 1), (13, 1.1))
      line((13.3, 1), (13, 0.9))
      content(((5.8 + 13.4)/2, 1.5))[far apart]
      
    })
  }
]

== A quick bit of history

#place(center + horizon)[
  #{
    cetz-canvas({
      import cetz.draw: *

      line((0, 0), (20, 0), stroke: black + 2pt)
      line((20, 0), (19.5, 0.2), stroke: black + 2pt)
      line((20, 0), (19.5, -0.2), stroke: black + 2pt)

      circle((5, 0), radius: 4pt, fill: orange, stroke: orange)
      content((5, 1))[Lisp]
      content((5, -1))[1959]
      content((5, -2))[GC first introduced]

      (pause,)

      circle((10, 0), radius: 4pt, fill: orange, stroke: orange)
      content((10, 1))[Smalltalk]
      content((10, -1))[1980]

      (pause,)

      circle((15, 0), radius: 4pt, fill: orange, stroke: orange)
      content((15, 1))[Java]
      content((15, -1))[1995]

      (pause,)

      circle((19, 0), radius: 4pt, fill: orange, stroke: orange)
      content((19, 5), angle: 75deg, )[JavaScript, Python, Go]
      content((19, -1))[1995]
    })
  }
]

== The heap is just a long strip

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      let obj(x, y, name) = {
        rect((x - 1, y + 0.5), (x + 1, y - 0.5), stroke: 2pt + black)
        content((x, y))[#name]
      }

      obj(1, 0.5)[$A$]
      obj(3, 0.5)[$B$]
      obj(5, 0.5)[$A_1$]
      obj(7, 0.5)[$F$]
      obj(9, 0.5)[$C$]
      obj(11, 0.5)[$D$]
      obj(13, 0.5)[$G_1$]
      obj(15, 0.5)[$D_1$]
      obj(17, 0.5)[$B_1$]
      obj(19, 0.5)[$E$]



      only("1", {
        line((20, -0.1), (20, -1), stroke: 1.5pt + black)
        line((20, -0.1), (19.9, -0.5), stroke: 1.5pt + black)
        line((20, -0.1), (20.1, -0.5), stroke: 1.5pt + black)
        content((20, -1.5), "next free")

        
        obj(21, 0.5)[]
      })

      uncover("2-", {
        obj(21, 0.5)[$G_2$]
        line((22, -0.1), (22, -1), stroke: 1.5pt + black)
        line((22, -0.1), (21.9, -0.5), stroke: 1.5pt + black)
        line((22, -0.1), (22.1, -0.5), stroke: 1.5pt + black)
        content((22, -1.5), "next free")
      })
      
    })
  ]

  #uncover("3-")[
    #place(bottom + center)[*No more space!*]
  ]

])

== Roots and reachability

#slide(repeat: 5, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon)[
    #cetz.canvas({
      import cetz.draw: *

      let root((x, y), name) = {
        rect((x - 2, y - 0.5), (x + 2, y+0.5), radius: 4pt)
        content((x, y))[#name]
      }

      let mark(x, y, color: green) = {
        rect((x - 2, y - 0.5), (x + 2, y+0.5), radius: 4pt, stroke: color)
      }

      let arrow((x1, y1), (x2, y2)) = {
        line((x1, y1), (x2, y2))

        let vec_x = if (x2 != x1) {
         (x2 - x1) / (x2 - x1) 
        } else {
          0
        }

        let vec_y = if (y2 != y1) {
         (y2 - y1) / (y2 - y1) 
        } else {
          0
        }

        line((x2, y2), (x2 - (vec_x) * 0.3, y2 + 0.1))
        line((x2, y2), (x2 - (vec_x) * 0.3, y2 - 0.1))
      }

      let arrow_v((x1, y1), (x2, y2), sign: true) = {
        line((x1, y1), (x2, y2))
        
        let new_y = if (sign) {
          y2 + 0.3
        } else {
          y2 - 0.3
        }
        line((x2, y2), (x2 + 0.1, new_y))
        line((x2, y2), (x2 - 0.1, new_y))
      }

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      content((0, 0.3))[Roots]
      line((-2.5,-0.2), (2.5, -0.2))

      root(((0, -1)))[$A$]
      root(((0, -2.5)))[$B$]
      root(((0, -4)))[$C$]
      root(((0, -5.5)))[$D$]
      root(((0, -7)))[$E$]

      arrow((2, -1), (4, -1))

      root(((6, -1)))[$A_1$]

      arrow((8, -1), (10, -1))

      root(((12, -1)))[$A_2$]

      arrow((2, -2.5), (4, -2.5))

      root(((6, -2.5)))[$B_1$]

      arrow((2, -5.5), (4, -5.5))

      root(((6, -5.5)))[$D_1$]

      root((18,-1))[$F$]

      root((18,-4))[$G_1$]
      root((18,-7))[$G_2$]

      arrow_v((17, -4.5), (17, -6.5))
      arrow_v((19, -6.5), (19, -4.5), sign: false)

      uncover("2-", {
        mark(0, -1)
        mark(0, -2.5)
        mark(0, -4)
        mark(0, -5.5)
        mark(0, -7)
      })
      uncover("3-", {
        mark(6, -1)
        mark(6, -2.5)
        mark(6, -5.5)
      })

      uncover("4-", {
        mark(12, -1)
      })

      uncover("5-", {
        mark(18, -1, color: orange + 2pt)
        mark(18, -4, color: orange + 2pt)
        mark(18, -7, color: orange + 2pt)
      })
      
    })
  ]
#place(bottom + left)[\* If A points to B that means that object A has pointer to B]
])

== Sweep and compact

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + horizon)[
    #cetz.canvas({
      import cetz.draw: *

      let uncover = uncover.with(
        cover-fn: hide.with(bounds: true),
      )

      let obj(x, y, name, color: green) = {
        rect((x - 1, y + 0.5), (x + 1, y - 0.5), stroke: 2pt + black)
        content((x, y))[#text(fill: color)[#name]]
      }

      obj(1, 0.5)[$A$]
      obj(3, 0.5)[$B$]
      obj(5, 0.5)[$A_1$]

      only("1", {
        obj(9, 0.5)[$C$]
        obj(11, 0.5)[$D$]
        obj(15, 0.5)[$D_1$]
        obj(17, 0.5)[$B_1$]
        obj(19, 0.5)[$E$]
        obj(7, 0.5, color: orange)[$F$]
        obj(13, 0.5, color: orange)[$G_1$]
        obj(21, 0.5, color: orange)[$G_2$]
      })

      uncover("2-", {
        obj(7, 0.5)[$C$]
        obj(9, 0.5)[$D$]
        obj(11, 0.5)[$D_1$]
        obj(13, 0.5)[$B_1$]
        obj(15, 0.5)[$E$]
        obj(17, 0.5, color: orange)[]
        obj(19, 0.5, color: orange)[]
        obj(21, 0.5, color: orange)[]
      })

      uncover("3-", {
        line((16, -0.1), (16, -1), stroke: 1.5pt + black)
        line((16, -0.1), (15.9, -0.5), stroke: 1.5pt + black)
        line((16, -0.1), (16.1, -0.5), stroke: 1.5pt + black)
        content((16, -1.5), "next free")
      })
    })
  ]


  #uncover("3-")[
    #place(bottom + center, dy: -1em)[Compacting is good for fast allocation!]
  ]
])

== Generations (one more interesting trick)

#slide(repeat: 3, self => [
  #let (uncover, only, alternatives) = utils.methods(self)

  #place(center + bottom)[
    #cetz.canvas({
      import cetz.draw: *

      let root((x, y), name) = {
        rect((x - 2, y - 0.5), (x + 2, y+0.5), radius: 4pt)
        content((x, y))[#name]
      }

      let mark(x, y, color: green) = {
        rect((x - 2, y - 0.5), (x + 2, y+0.5), radius: 4pt, stroke: color)
      }

      let arrow((x1, y1), (x2, y2)) = {
        line((x1, y1), (x2, y2))

        let vec_x = if (x2 != x1) {
         (x2 - x1) / (x2 - x1) 
        } else {
          0
        }

        let vec_y = if (y2 != y1) {
         (y2 - y1) / (y2 - y1) 
        } else {
          0
        }

        line((x2, y2), (x2 - (vec_x) * 0.3, y2 + 0.1))
        line((x2, y2), (x2 - (vec_x) * 0.3, y2 - 0.1))
      }

      content((0, 0))[Gen 0]
      line((-2, -0.9), (2, -0.9))


      only("1", {
        root((0, -2))[$G_2$]
        root((0, -3.5))[$G_1$]
        root((0, -5))[$F$]
        root((0, -6.5))[$E$]
      })

      only("2", {
         root((0, -2))[$F$]
      })

      only("3", {
         root((6, -5))[$F$]
      })

      line((-2, -7.5), (2, -7.5))

      content((6, 0))[Gen 1]
      line((4, -0.9), (8, -0.9))
      root((6, -2))[$B$]
      root((6, -3.5))[$C$]

      line((4, -11), (8, -11))

      content((12, 0))[Gen 2]
      line((10, -0.9), (14, -0.9))
      root((12, -2))[$A$]

      line((10, -11), (14, -11))

      
    })
  ]
])

== Memory isn't the only resource

GC manages *only* memory, fiel you have to close yourself
