extensions [nw]
turtles-own [
  prev-xcor
  prev-ycor
  current-speed
  community
]



globals [
  recolor-done
  selected
]

humans-own [ linkstome powerbalance happy? ]
undirected-link-breed [ humanlinks humanlink ]
undirected-link-breed [ hidealinks hidealink ]
undirected-link-breed [ entitylinks entitylink ]

links-own [link-type power ]

breed [ humans human ]
breed [ entities entity ]
breed [ ideas idea ]
breed [ antagonists antagonist ]


to setup
  clear-all
  random-seed 99
  set-default-shape humans "circle"
  ;; make the initial network of two turtles and an edge
  make-node nobody        ;; first node, unattached
  make-node turtle 0      ;; second node, attached to first node
  set selected nobody
  set recolor-done false
  ask patches [ if pxcor + pycor < 0 [ set pcolor grey - 1]]
  reset-ticks
end


;;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedures ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; new edge is green, old edges are gray
  ask links [ set color gray ]
  make-node find-partner         ;; find partner & use it as attachment
                                 ;; point for new node
  ask humans [
    countlinks

;      ]
  ]
  calculate_position
  resize-nodes
  link_to_other_humans_with_similar_ideas
  link_to_other_humans_with_similar_entities
  link_entities_to_humans
  link_humans_to_ideas
  cut_off-nodes
  generate_ideas
  generate_entities
 recolour_boundary_nodes
  destroy_ideas
  destroy_entities
  resize_turtles
  if layout? [ layout ]
  tick
  calculate_speed
  checkcommunities
  toggle-community-detection
  labelagents
  move_antagonist
  closeranks
  polarise
  analyse-clusters
end

to calculate_position
   ask turtles [
    set prev-xcor xcor  ; Initialize previous x-coordinate
    set prev-ycor ycor  ; Initialize previous y-coordinate
  ]
end


;; used for creating a new node
to make-node [old-node]
  if count humans < max_humans [  create-humans 1
  [
    set color red
    set happy? true
    if old-node != nobody
      [ create-humanlink-with old-node [ set color green set power random 100 ]
        ;;move-to old-node
        fd random Exploration
      ]
  ]]
end

to generate_ideas
  ask n-of 1 humans [
    if any? other humans in-radius exploration and count ideas < abs (count humans * .5)  [
      hatch-ideas 1 [
        set shape "triangle"
        set color yellow
        let new_idea self  ; Store the newly created idea in a variable
        ask one-of other humans-here [
          create-hidealink-with new_idea [ set power 100 ]
        ]
      ]
    ]
  ]
end

to generate_entities
  ask n-of 1 humans [
    if any? other humans in-radius exploration_entities and count entities < abs (count humans * .5)  [
      hatch-entities 1 [
        set shape "square"
        set color green
        let new_entity self  ; Store the newly created idea in a variable
        ask one-of other humans-here [
          create-entitylink-with new_entity [ set power 100 ]

        ]
      ]
    ]
  ]
end



;;preferential attachment
to-report find-partner
  report [one-of both-ends] of one-of links
end

;;;;;;;;;;;;;;
;;; Layout ;;;
;;;;;;;;;;;;;;

;; resize-nodes, change back and forth from size based on degree to a size of 1
to resize-nodes
    ask humans [ set size sqrt count humanlink-neighbors ]
end

to layout
  repeat 10 [
    ;; the more turtles we have to fit into the same amount of space,
    ;; the smaller the inputs to layout-spring we'll need to use
    let factor sqrt count humans
    ;; numbers here are arbitrarily chosen for pleasing appearance

    layout-spring humans links  Constant Length_  Repulsion
    layout-spring ideas links Constant Length_  Repulsion
    layout-spring entities links Constant Length_  Repulsion
    display  ;; for smooth animation
  ]
  ;; don't bump the edges of the world
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  ;; big jumps look funny, so only adjust a little each time
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask humans [ setxy (xcor - x-offset / 2) (ycor - y-offset / 2) ]
end

to-report limit-magnitude [number limit]
  if number > limit [ report limit ]
  if number < (- limit) [ report (- limit) ]
  report number
end

to link_to_other_humans_with_similar_ideas
  ask n-of 1 humans [
    let nearby-ideas ideas in-radius exploration  ; Find ideas within exploration radius
    ; Exclude self from linked-neighbors and ensure they are linked to nearby ideas
    let linked-neighbors map [? -> ?] sort (humans with [any? link-neighbors with [member? self nearby-ideas] and self != myself])
    if not empty? linked-neighbors [  ; Check if the list is not empty
      foreach linked-neighbors [
        the-human -> if not link-neighbor? the-human [  ; Check if not already linked
          create-humanlink-with the-human [ set power random 100 ]  ; Create a link with this human
        ]
      ]
    ]
  ]

  ask humans [
    set size sqrt count link-neighbors  ; Adjust size based on the number of link-neighbors
  ]
end


to link_to_other_humans_with_similar_entities
  ask n-of 1 humans [
    let nearby-entities entities in-radius exploration_entities  ; Find ideas within exploration radius
    ; Exclude self from linked-neighbors and ensure they are linked to nearby ideas
    let linked-neighbors map [? -> ?] sort (humans with [any? link-neighbors with [member? self nearby-entities] and self != myself])
    if not empty? linked-neighbors [  ; Check if the list is not empty
      foreach linked-neighbors [
        the-human -> if not link-neighbor? the-human [  ; Check if not already linked
          create-humanlink-with the-human [ set power random 100 set link-type "humanlink"]  ; Create a link with this human
        ]
      ]
    ]
  ]

end

to link_entities_to_humans
  if count entities > 1 [
    ask n-of 1 entities [
    let nearby-humans humans in-radius exploration  ; Find ideas within exploration radius
    ; Exclude self from linked-neighbors and ensure they are linked to nearby ideas
    let linked-neighbors map [? -> ?] sort (entities with [any? link-neighbors with [member? self nearby-humans] and self != myself])
    if not empty? linked-neighbors [  ; Check if the list is not empty
      foreach linked-neighbors [
        the-entity -> if not link-neighbor? the-entity [  ; Check if not already linked
          create-entitylink-with the-entity [ set power random 100 set link-type "humanentitylink"]  ; Create a link with this human
        ]
      ]
    ]
  ]
  ]
end


to link_humans_to_ideas
  if count ideas > 1 [
    ask n-of 1 ideas [
    let nearby-humans humans in-radius exploration  ; Find ideas within exploration radius
    ; Exclude self from linked-neighbors and ensure they are linked to nearby ideas
    let linked-neighbors map [? -> ?] sort (entities with [any? link-neighbors with [member? self nearby-humans] and self != myself])
    if not empty? linked-neighbors [  ; Check if the list is not empty
      foreach linked-neighbors [
        the-idea -> if not link-neighbor? the-idea [  ; Check if not already linked
          create-hidealink-with the-idea [ set power random 100 set link-type "entitylink"]  ; Create a link with this human
        ]
      ]
    ]
  ]
  ]
end

to calculate_speed
  ask turtles [
    set current-speed distancexy prev-xcor prev-ycor
    ;;print (word "Turtle ID: " who " | Initial Pos: " prev-xcor ", " prev-ycor " | Current Pos: " xcor ", " ycor " | Speed: " current-speed)
  ]
end


to countlinks
  set linkstome count link-neighbors
end


to recolour_boundary_nodes
  ifelse community-detection = false [
    ; Community detection is off, do the simple coloring
    ask humans [ ifelse count my-links = 1 [ set color blue ] [ set color red ] ]
    ask entities [ set color green ]
    ask ideas [ set color yellow ]
  ] [
    ; Community detection is on, do it only once and periodically every 10 ticks
    if not recolor-done [
      color-clusters nw:louvain-communities
      set recolor-done true  ; Set the flag to prevent re-running
    ]
  ]
  if remainder ticks 20 = 0 [ set recolor-done false ]
end


to toggle-community-detection
  if community-detection = false [
    set recolor-done false ] ; Reset recoloring flag when toggling the condition
end

to move_antagonist
  if count antagonists > 0 [ ask antagonists [
    fd 1 set heading (heading + random 45 - random 45) set color white ]]
end

to closeranks
  let affected-humans humans with [any? antagonists in-radius 5]
  ask affected-humans [
    ; Modify link attributes or set a flag for special handling
        ; Perform layout adjustment on this human and its direct neighbors
   layout-spring affected-humans links (Constant * 10) (Length_ / 10)  ( Repulsion / 10 )
  ]
end

to polarise
  if polarise_switch = true [ ; Get the list of communities using nw:louvain-communities
  let communities nw:louvain-communities print "got communities"
  if not empty? communities [
    ; Randomly select one community to act as the source of antagonists
    let antagonist-community communities print "not empty"

    ; Define all humans within a radius of 5 units from any agent in the antagonist community
    let affected-humans humans with [any? other humans in-radius group_distance with [not member? self antagonist-community] ]

    layout-spring affected-humans links (Constant * 10) (Length_ / 10) (Repulsion / 10) print "working_closeranks2"

  ]]
end



;H5
to leave_group
  ask humans [
    let sum_position sum (list xcor ycor)
    if sum_position < 0 and count my-humanlinks > 2 [
      ; Directly ask all links meeting the condition to die
      ask my-humanlinks with [power > Mobility] [
        die
        print "leaving"
      ]
    ]
  ]
end

;H4
to Restore_Identity
   ask entities [
    let sum_position sum (list xcor ycor)
    if sum_position < Discrimination_Point  [
      ; Directly ask all links meeting the condition to die
     set heading 45 + random 45 - random 45 fd random 5 print "H4"
      ]
    ]
end

;H6 Creativity

to Creativity_Hypothesis
   ask ideas [
    let sum_position sum (list xcor ycor)
    if sum_position < Discrimination_Point  [
      ; Directly ask all links meeting the condition to die
     set heading 0 + random 45 - random 45 fd random 5 print "H4"
      ]
    ]
end

to analyse-clusters ;H8
  let clusters nw:louvain-communities
  show (word "Number of clusters: " length clusters)  ; Count clusters

  ; Iterate over each cluster to calculate average positions and other properties
  foreach clusters [
    [cluster] ->
    let avg-x mean [xcor] of cluster
    let avg-y mean [ycor] of cluster
    show (word "Average position of cluster: " avg-x ", " avg-y)

    ; Example: Calculate other properties like average size
    let avg-size mean [size] of cluster
    show (word "Average size of cluster: " avg-size)
  ]
end

to Powerlink

end





;; Disaster settings ####################################################################################

to cut_off-nodes
  if count humans > 1 and death_rate > random 100 [ ask one-of humans [ die ]]
end

to destroy_ideas
  ; First, remove all ideas that have no links
  ask ideas [
    if count my-links = 0  [  ; Check if the idea has no links
      die
    ]
  ]

  ; Second, probabilistically remove one idea if there's more than one left
  if count ideas > 1 and random 100 <  perturb_ideas[  ; 5% chance if more than one idea remains
    ask one-of ideas [ die ]  ; Randomly ask one idea to die
  ]
end


to destroy_entities
  ; First, remove all entities that have no links
  ask entities [
    if count my-entitylinks = 0  [  ; Check if the idea has no links
      die
    ]
  ]

  ; Second, probabilistically remove one idea if there's more than one left
  if count entities > 1 and random 100 < perturb_entities [  ; x% chance if more than one idea remains
    ask one-of entities [ die ]  ; Randomly ask one idea to die
  ]
end

to resize_turtles
  ; Ask every turtle except antagonists to resize
  ask (turtles with [breed != antagonists]) [
    set size sqrt(count my-links)
  ]
end


to destroy_agents
  if mouse-down? [
    let mx mouse-xcor  ; Get mouse x-coordinate
    let my mouse-ycor  ; Get mouse y-coordinate
    if (mx != nobody and my != nobody) [  ; Check if the mouse is within the world coordinates
      ask patch mx my [  ; Ask the patch under the mouse
        ask turtles-here [  ; Ask any turtles on this patch
          die  ; Kill the turtle
        ]
      ]
    ]
  ]
end

to kill-links
  if mouse-down?  [
    let mx mouse-xcor  ; Get the mouse x-coordinate
    let my mouse-ycor  ; Get the mouse y-coordinate
    if (mx != nobody and my != nobody) [  ; Check if the mouse is within the world
      ask links [
        ; Get the x and y coordinates of the endpoints
        let x1 [xcor] of end1
        let y1 [ycor] of end1
        let x2 [xcor] of end2
        let y2 [ycor] of end2

        ; Calculate the distance from the mouse to the line segment
        let d distance-to-line (list x1 y1) (list x2 y2) (list mx my)

        ; Check if the mouse click is close enough to the link
        if d < 1 [  ; You can adjust this threshold to suit your interface scale
          die  ; Kill the link if the mouse is close enough
        ]
      ]
    ]
  ]
end

; Helper function to calculate distance from a point to a line segment
to-report distance-to-line [p1 p2 p0]
  ; p1 and p2 are endpoints of the line segment, p0 is the point (mx, my)
  let x0 first p0
  let y0 last p0
  let x1 first p1
  let y1 last p1
  let x2 first p2
  let y2 last p2
  let A y2 - y1
  let B x1 - x2
  let C x2 * y1 - x1 * y2
  let denominator sqrt(A ^ 2 + B ^ 2)

  ; Check if the denominator is zero, which means endpoints are the same or too close
  if denominator = 0 [
    ; Return a large number or handle differently, since the point is effectively at the endpoint
    report max-pxcor ;
  ]

  report (abs(A * x0 + B * y0 + C)) / denominator
end

;;;measures of the network

to-report network-density
  report (count links) / (count turtles * (count turtles - 1) / 2)
end

to-report degree-centrality
  report map [count link-neighbors / (count turtles - 1)] sort turtles
end

to drag
ifelse mouse-down? [
    ; if the mouse is down then handle selecting and dragging
    handle-select-and-drag
  ][
    ; otherwise, make sure the previous selection is deselected
    set selected nobody
    reset-perspective
  ]
  display ; update the display
end

to handle-select-and-drag
  ; if no turtle is selected
  ifelse selected = nobody  [
    ; pick the closet turtle
    set selected min-one-of turtles [distancexy mouse-xcor mouse-ycor]
    ; check whether or not it's close enough
    ifelse [distancexy mouse-xcor mouse-ycor] of selected > 1 [
      set selected nobody ; if not, don't select it
    ][
      watch selected ; if it is, go ahead and `watch` it
    ]
  ][
    ; if a turtle is selected, move it to the mouse
    ask selected [ setxy mouse-xcor mouse-ycor ]
  ]
end




;::::::::::::::::::::REPORTING:::::::::::::::::::::::::::::::


to checkcommunities
  foreach nw:louvain-communities [ [comm] ->
    ask comm [ set community comm ] ]

end

to color-clusters [ clusters ] ;assignment of a color for each cluster
  let n length clusters
  let hues n-values n [ i -> (360 * i / n) ]
  (foreach clusters hues [ [cluster hue] ->
    ask cluster [
      set color hsb hue 100 100
      ask my-links with [ member? other-end cluster ] [ set color hsb hue 100 75 ]]])
end

to-report modularity ;measure modularity related to grey and red members
  report nw:modularity (list (humans) (ideas) (entities))
end

;to eigenvector ;as the simulations represent the spread of a concept (due to the placement of beliefs) eigenvector centrality is represented by the inverse of its original sense
;  centrality [ ->  nw:eigenvector-centrality ]
;end
;

to labelagents
  ;ask humans [ set label community ]
end
@#$#@#$#@
GRAPHICS-WINDOW
397
10
808
422
-1
-1
4.43
1
10
1
1
1
0
0
0
1
-45
45
-45
45
1
1
1
ticks
60.0

PLOT
8
330
333
496
Degree Distribution (log-log)
log(degree)
log(# of nodes)
0.0
0.3
0.0
0.3
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of turtles\n;; for this plot, the axes are logarithmic, so we can't\n;; use \"histogram-from\"; we have to plot the points\n;; ourselves one at a time\nplot-pen-reset  ;; erase what we plotted before\n;; the way we create the network there is never a zero degree node,\n;; so start plotting at degree one\nlet degree 1\nwhile [degree <= max-degree] [\n  let matches turtles with [count link-neighbors = degree]\n  if any? matches\n    [ plotxy log degree 10\n             log (count matches) 10 ]\n  set degree degree + 1\n]"

PLOT
8
153
333
329
Degree Distribution
degree
# of nodes
1.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of humans\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of humans"

BUTTON
6
25
72
58
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
93
64
170
97
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
6
64
91
97
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
187
30
333
63
plot?
plot?
0
1
-1000

SWITCH
187
64
333
97
layout?
layout?
0
1
-1000

MONITOR
185
498
271
543
# of humans
count humans
3
1
11

SLIDER
833
79
1005
112
Exploration
Exploration
0
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
8
500
180
533
max_humans
max_humans
0
200
150.0
1
1
NIL
HORIZONTAL

PLOT
5
148
328
324
Degree distribution humans
NIL
# of nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "if not plot? [ stop ]\nlet max-degree max [count link-neighbors] of humans\nplot-pen-reset  ;; erase what we plotted before\nset-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar\nhistogram [count link-neighbors] of humans"

SLIDER
833
119
1005
152
LinkNumber
LinkNumber
0
100
3.0
1
1
NIL
HORIZONTAL

MONITOR
271
499
349
544
# ideas
count ideas
0
1
11

MONITOR
1018
74
1091
119
NIL
count links
17
1
11

SLIDER
832
158
1004
191
Perturb_ideas
Perturb_ideas
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
833
194
1005
227
Perturb_Entities
Perturb_Entities
0
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
834
29
1006
62
Exploration_Entities
Exploration_Entities
0
20
5.0
1
1
NIL
HORIZONTAL

PLOT
1105
27
1305
177
Network Density
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot network-density * 100"

PLOT
830
275
1183
449
Disturbance
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range  0 10" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [ current-speed ] of humans * 10"

BUTTON
427
473
490
506
NIL
Drag
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
355
499
416
544
# Entities
count entities
17
1
11

MONITOR
1020
170
1094
215
Link Power
mean [ power ] of links
17
1
11

SLIDER
831
232
1003
265
Death_rate
Death_rate
0
100
46.0
1
1
NIL
HORIZONTAL

SLIDER
1108
183
1280
216
Constant
Constant
0
1
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
1108
218
1280
251
Length_
Length_
0
10
3.4
0.1
1
NIL
HORIZONTAL

SLIDER
1108
255
1280
288
Repulsion
Repulsion
0
20
5.6
0.1
1
NIL
HORIZONTAL

SWITCH
641
435
806
468
Community-detection
Community-detection
0
1
-1000

BUTTON
1058
473
1159
506
Destroy Links
kill-links
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
943
473
1054
506
Destroy Agents
destroy_agents
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1299
411
1449
450
Closing ranks in response to threats - this is a social selfish herd
10
0.0
1

MONITOR
1019
28
1090
73
Modularity
modularity
17
1
11

BUTTON
497
474
623
507
Launch antagonist
ask n-of 1 patches [ sprout-antagonists 1 [ set size 5 set color white ]] 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1300
332
1450
350
Divide and conquer
10
0.0
1

BUTTON
428
518
545
551
Leave_Group H5
Leave_group
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
433
553
536
586
Mobility
Mobility
0
100
25.0
1
1
NIL
HORIZONTAL

BUTTON
625
474
760
507
Restore_Identity H4
Restore_Identity
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
654
518
752
551
Creativity H6
Creativity_Hypothesis
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
768
474
940
507
Discrimination_Point
Discrimination_Point
-50
75
1.0
1
1
NIL
HORIZONTAL

TEXTBOX
849
462
864
480
H7
10
0.0
1

TEXTBOX
1291
225
1358
243
H13 - Meaning
10
0.0
1

MONITOR
217
103
334
148
Number of groups
length nw:louvain-communities
17
1
11

SWITCH
768
516
899
549
Polarise_switch
Polarise_switch
0
1
-1000

SLIDER
902
517
1017
550
group_distance
group_distance
0
10
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
1299
353
1449
405
Selfish herd model of social identity\n\nLeaders vs pioneers
10
0.0
1

BUTTON
556
519
643
552
Voronoi
\n  ask patches [\n    set pcolor [color] of min-one-of humans [distance myself]\n  ]\n
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
548
561
668
594
Reset patch color
ask patches [ set pcolor black]\nask patches [ if pxcor + pycor < 0 [ set pcolor grey - 1]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
585
425
735
443
Health
14
0.0
1

TEXTBOX
350
198
397
246
Social Status
14
0.0
1

TEXTBOX
405
398
555
416
Low
14
9.9
1

TEXTBOX
771
18
921
36
High
14
9.9
1

@#$#@#$#@
## WHAT IS IT?

In some networks, a few "hubs" have lots of connections, while everybody else only has a few.  This model shows one way such networks can arise.

Such networks can be found in a surprisingly large range of real world situations, ranging from the connections between websites to the collaborations between actors.

This model generates these networks by a process of "preferential attachment", in which new network members prefer to make a connection to the more popular existing members.

## HOW IT WORKS

The model starts with two nodes connected by an edge.

At each step, a new node is added.  A new node picks an existing node to connect to randomly, but with some bias.  More specifically, a node's chance of being selected is directly proportional to the number of connections it already has, or its "degree." This is the mechanism which is called "preferential attachment."

## HOW TO USE IT

Pressing the GO ONCE button adds one new node.  To continuously add nodes, press GO.

The LAYOUT? switch controls whether or not the layout procedure is run.  This procedure attempts to move the nodes around to make the structure of the network easier to see.

The PLOT? switch turns off the plots which speeds up the model.

The RESIZE-NODES button will make all of the nodes take on a size representative of their degree distribution.  If you press it again the nodes will return to equal size.

If you want the model to run faster, you can turn off the LAYOUT? and PLOT? switches and/or freeze the view (using the on/off button in the control strip over the view). The LAYOUT? switch has the greatest effect on the speed of the model.

If you have LAYOUT? switched off, and then want the network to have a more appealing layout, press the REDO-LAYOUT button which will run the layout-step procedure until you press the button again. You can press REDO-LAYOUT at any time even if you had LAYOUT? switched on and it will try to make the network easier to see.

## THINGS TO NOTICE

The networks that result from running this model are often called "scale-free" or "power law" networks. These are networks in which the distribution of the number of connections of each node is not a normal distribution --- instead it follows what is a called a power law distribution.  Power law distributions are different from normal distributions in that they do not have a peak at the average, and they are more likely to contain extreme values (see Albert & Barabási 2002 for a further description of the frequency and significance of scale-free networks).  Barabási and Albert originally described this mechanism for creating networks, but there are other mechanisms of creating scale-free networks and so the networks created by the mechanism implemented in this model are referred to as Barabási scale-free networks.

You can see the degree distribution of the network in this model by looking at the plots. The top plot is a histogram of the degree of each node.  The bottom plot shows the same data, but both axes are on a logarithmic scale.  When degree distribution follows a power law, it appears as a straight line on the log-log plot.  One simple way to think about power laws is that if there is one node with a degree distribution of 1000, then there will be ten nodes with a degree distribution of 100, and 100 nodes with a degree distribution of 10.

## THINGS TO TRY

Let the model run a little while.  How many nodes are "hubs", that is, have many connections?  How many have only a few?  Does some low degree node ever become a hub?  How often?

Turn off the LAYOUT? switch and freeze the view to speed up the model, then allow a large network to form.  What is the shape of the histogram in the top plot?  What do you see in log-log plot? Notice that the log-log plot is only a straight line for a limited range of values.  Why is this?  Does the degree to which the log-log plot resembles a straight line grow as you add more nodes to the network?

## EXTENDING THE MODEL

Assign an additional attribute to each node.  Make the probability of attachment depend on this new attribute as well as on degree.  (A bias slider could control how much the attribute influences the decision.)

Can the layout algorithm be improved?  Perhaps nodes from different hubs could repel each other more strongly than nodes from the same hub, in order to encourage the hubs to be physically separate in the layout.

## NETWORK CONCEPTS

There are many ways to graphically display networks.  This model uses a common "spring" method where the movement of a node at each time step is the net result of "spring" forces that pulls connected nodes together and repulsion forces that push all the nodes away from each other.  This code is in the `layout-step` procedure. You can force this code to execute any time by pressing the REDO LAYOUT button, and pressing it again when you are happy with the layout.

## NETLOGO FEATURES

Nodes are turtle agents and edges are link agents. The model uses the ONE-OF primitive to chose a random link and the BOTH-ENDS primitive to select the two nodes attached to that link.

The `layout-spring` primitive places the nodes, as if the edges are springs and the nodes are repelling each other.

Though it is not used in this model, there exists a network extension for NetLogo that comes bundled with NetLogo, that has many more network primitives.

## RELATED MODELS

See other models in the Networks section of the Models Library, such as Giant Component.

See also Network Example, in the Code Examples section.

## CREDITS AND REFERENCES

This model is based on:
Albert-László Barabási. Linked: The New Science of Networks, Perseus Publishing, Cambridge, Massachusetts, pages 79-92.

For a more technical treatment, see:
Albert-László Barabási & Reka Albert. Emergence of Scaling in Random Networks, Science, Vol 286, Issue 5439, 15 October 1999, pages 509-512.

The layout algorithm is based on the Fruchterman-Reingold layout algorithm.  More information about this algorithm can be obtained at: http://cs.brown.edu/people/rtamassi/gdhandbook/chapters/force-directed.pdf.

For a model similar to the one described in the first suggested extension, please consult:
W. Brian Arthur, "Urban Systems and Historical Path-Dependence", Chapt. 4 in Urban systems and Infrastructure, J. Ausubel and R. Herman (eds.), National Academy of Sciences, Washington, D.C., 1988.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (2005).  NetLogo Preferential Attachment model.  http://ccl.northwestern.edu/netlogo/models/PreferentialAttachment.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2005 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2005 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
set layout? false
set plot? false
setup repeat 300 [ go ]
repeat 100 [ layout ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
