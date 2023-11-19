breed [ foragers forager ] ; foragers are the main agents in the model
breed [ fruit-bushes fruit-bush ] ; bushes that are foraged from
breed [ deaths death ] ; red marks representing homicides

foragers-own
[
  energy ; metabolic energy
  genome ; list encoding parameters that is heritable
  foraging? ; boolean status whether forager is foraging
  fleeing? ; boolean status whether forager is fleeing
  fleeing-turns ; number of turns remaining to flee if fleeing
  age ; age of forager in ticks
  speed ; speed attribute determines movement
  strength ; strength attribute determines fighting success
  intelligence ; intelligence attribute determines group foraging rate
  reactive-aggression ; determines likelihood to threaten on arrival
  proactive-aggression ; determines likelihood to defend
  
  max-strength ; Максимальне значення сили здобувача
  poisoned? ; вказує, чи здобувач отруєний
  poison-recovery-ticks ; кількість тактів до відновлення після отруєння
  normal-speed ; збереження нормальної швидкості для відновлення після отруєння
]

fruit-bushes-own
[
  amount ; amount of energy in bush
  poisonous? ; indicates if the bush is poisonous
  dead ; indicates if the bush is dead
]

deaths-own
[
  age ; persistence of red-X
]

globals
[
  murder-count ; total number of homicides
  starvation-count ; total number of starvation events
  age-death-count ; total deaths from old age
  death-count ; total of all deaths
  poisoning-count ;
  murder-rate ; rate of murders to all deaths
  starvation-rate ; rate of starvation events to all deaths
  age-death-rate ; rate of deaths from old age to all deaths
  poisoning-rate ;
  total-foraged ; total amount foraged
  num-forages ; total number of forages
  avg-forage ; average yield of forages
  total-population ; total foragers in all ticks
  average-population ; average foragers alive in any given tick

  speed-reduction-after-poisoning ;
  poison-recovery-duration ; Тривалість періоду відновлення після отруєння
]

to setup ; initial setup
  clear-all
  ask patches [ set pcolor 53 ]
  grow-fruit-bushes initial-fruit-bushes
  create-foragers initial-foragers
  [
    set shape "person"
    set color gray
    set size 2
    set xcor random-xcor
    set ycor random-ycor
    set energy 100
    set genome new-genome 240
    set foraging? false
    set fleeing? false
    set strength get-strength
    set speed get-speed
    set intelligence get-intelligence
    set reactive-aggression get-reactive-aggression
    set proactive-aggression get-proactive-aggression
    set age 0
    set max-strength 60
    set poisoned? false
    set normal-speed speed
  ]
  set total-population 0
  set murder-count 0
  set death-count 0
  set poisoning-count 0
  set poisoning-rate 0
  set murder-rate 0
  set num-forages 0
  set total-foraged 0
  set avg-forage 0
  set speed-reduction-after-poisoning 20 ;
  set poison-recovery-duration 20
 
  reset-ticks
end

to grow-fruit-bushes [ num-bushes ] ; procedure to create fruit-bushes on a grid without overlap
  ask n-of num-bushes patches with ; only spawn new bushes on patches spaced 3 apart
  [
    pxcor mod 3 = 0
    and pycor mod 3 = 0
    and (abs (pycor - max-pycor)) > 1 ; avoid being to closer to the edge
    and (abs (pxcor - max-pxcor)) > 1
    and (abs (pycor - min-pycor)) > 1
    and (abs (pxcor - min-pxcor)) > 1
    and not any? fruit-bushes-here
  ]
  [
    sprout-fruit-bushes 1
    [
      set shape "Bush"
      set color ifelse-value (random-float 1 < bush-probability-poisonous) [ black ] [ one-of [ red blue orange yellow ] ]
      set amount 500 + random 501
      set size 3
      set poisonous? (color = black) ;
      set dead false ;
    ]
  ]
end

to go
  if not any? foragers [ stop ]
  ask deaths ; draw red Xs on the view
  [
    set age age + 1
    if age > 10 [ die ]
  ]
  if random 100 < bush-growth-chance [ grow-fruit-bushes 1 ]
  move-foragers ; producer to handle foragers' actions
  if-else (murder-count + age-death-count + starvation-count) = 0
  [
    set murder-rate 0
    set starvation-rate 0
    set age-death-rate 0
  ]
  [
    set murder-rate 100 * murder-count / (murder-count + age-death-count + starvation-count + poisoning-count)
    set starvation-rate 100 * starvation-count / (murder-count + age-death-count + starvation-count + poisoning-count)
    set age-death-rate 100 * age-death-count / (murder-count + age-death-count + starvation-count + poisoning-count)
    set poisoning-rate 100 * poisoning-count / (murder-count + age-death-count + starvation-count + poisoning-count)
    
  ]
  if-else num-forages = 0
    [ set avg-forage 0 ]
  [ set avg-forage total-foraged / num-forages ]
  
  set total-population total-population + count foragers
  if-else ticks = 0
    [ set average-population 0 ]
  [ set average-population total-population / ticks ]
  tick
end

to move-foragers ; forager procedure
  ask foragers
  [
    if poisoned? [
      set poison-recovery-ticks poison-recovery-ticks - 1
      if poison-recovery-ticks <= 0 [
        set poisoned? false
        set speed normal-speed
      ]
    ]
    if-else fleeing? ; if they are fleeing only move randomly
    [
      lt (random 31) - 15
      fd (speed / 60)
      set fleeing-turns fleeing-turns - 1
      if fleeing-turns = 0 [ set fleeing? false ]
    ]
    [
      if-else any? fruit-bushes in-radius 0.1 and foraging?
      [
        forage
      ]
      [
        set foraging? false
        if-else any? fruit-bushes in-radius 5
        [ ; face nearest fruit-bush in radius of 5 units
          face min-one-of fruit-bushes in-radius 5 [distance myself]
        ]
        [
          lt (random 31) - 15
        ]
        if-else any? fruit-bushes in-radius 1
        [ ; arrive at any fruit-bush closer than 1 unit away
          move-to one-of fruit-bushes in-radius 1
          arrive
        ]
        [
          fd (speed / 60)
          set energy energy - 1
        ]
        if energy < 0
        [
          set starvation-count starvation-count + 1
          die
        ]
        if energy > 200
        [ ; reproduce
          set energy energy - 100
          hatch-foragers 1
          [
            set genome mutate [genome] of myself rate-of-mutation
            set shape "person"
            set color gray
            set size 2
            set energy 100
            set foraging? false
            set fleeing? false
            set strength get-strength
            set speed get-speed
            set intelligence get-intelligence
            set reactive-aggression get-reactive-aggression
            set proactive-aggression get-proactive-aggression
            set age 0
          ]
        ]
      ]
    ]
    set age age + 1
    if age > max-age
    [
      set age-death-count age-death-count + 1
      die
    ]
    if-else show-energy?
      [ set label precision energy 0 ]
    [ set label " " ]
    (ifelse
      visualization = "Strength"
      [
        set color scale-color red strength 0 40
      ]
      visualization = "Speed"
      [
        set color scale-color green speed 0 40
      ]
      visualization = "Intelligence"
      [
        set color scale-color blue intelligence 0 40
      ]
      visualization = "Reactive Aggression"
      [
        set color scale-color orange reactive-aggression 0 40
      ]
      visualization = "Proactive Aggression"
      [
        set color scale-color 115 proactive-aggression 0 40
      ]
      [
        set color grey
    ])
  ]
end

to arrive ; forager procedure
  if-else any? other foragers in-radius 0.1
  [
    if-else random-float 1 < (reactive-aggression / 60)
    [ ; determines whether arriving forager threatens
      let count-fighters 0
      let total-strength 0
      ask other foragers in-radius 0.1
      [
        if-else random-float 1 < (proactive-aggression / 60)
        [ ; determines if other forager fights back
          set count-fighters count-fighters + 1
          set total-strength total-strength + strength
        ]
        [ ; they relent
          set foraging? false
          set fleeing? true
          set fleeing-turns ticks-to-flee
        ]
      ]
      if-else count-fighters > 0
      [
        if-else random-float 1 < (strength / ((total-strength * 0.75) + strength))
        [
          set murder-count murder-count + count-fighters
          ask other foragers in-radius 0.1 with [foraging?]
          [
            hatch-deaths 1 [set color red set shape "x" set age 0]
            die
          ]
        ]
        [
          set murder-count murder-count + 1
          hatch-deaths 1 [set color red set shape "x" set age 0]
          die
        ]
      ]
      [
        set foraging? true
      ]
    ]
    [ ; arriving forager cooperates
      let okay? true
      if (count other foragers in-radius 0.1) = 1
      [ ; if there is more than one forager present
        ; assume they have already cooperated
        ask other foragers in-radius 0.1
        [
          if random-float 1 < (reactive-aggression / 60)
          [ ; they threaten me
            set okay? false
          ]
        ]
      ]
      if-else okay?
      [
        set foraging? true
      ]
      [
        set fleeing? true
        set fleeing-turns ticks-to-flee
      ]
    ]
  ]
  [
    set foraging? true
  ]
end

to forage ; forager procedure
  let forage-rate 0
  let target-bush nobody
  if-else any? other foragers in-radius 0.1 with [foraging?]
  [
    let i-n sum [intelligence] of foragers in-radius 0.1 with [foraging?]
    let i-d (count foragers in-radius 0.1 with [foraging?]) * 20
    let i-ratio i-n / i-d
    set forage-rate i-ratio * 10 * collaboration-bonus
  ]
  [
    set forage-rate 10
  ]
  
  if any? fruit-bushes in-radius 0.1 and foraging?
  [
    set target-bush one-of fruit-bushes in-radius 0.1
    ifelse [amount] of target-bush > 0 and not [dead] of target-bush
    [
      ask target-bush
      [
        set amount amount - 10
        if (amount < 0) [ set dead true ] ; Позначити кущ як мертвий, якщо ресурси вичерпано
      ]
      
      if-else [poisonous?] of target-bush
      [
        if-else (random-float 1 < probability-die-poison)
        [ 
          set poisoning-count poisoning-count + 1
          die
        ]
        [
          let survival-probability 0.5 + (strength / max-strength) ; Залежність від сили
          if-else (random-float 1 < survival-probability)
          [
            set poisoned? true
            set poison-recovery-ticks poison-recovery-duration
            set speed (speed - speed-reduction-after-poisoning)
          ]
          [
            set poisoning-count poisoning-count + 1
            die
          ]
        ]
      ]
      [
        set energy (energy + forage-rate)
        set num-forages (num-forages + 1)
        set total-foraged (total-foraged + forage-rate)
      ]
    ]
    [
      remove-depleted-bush target-bush
    ]
  ]
end


to remove-depleted-bush [bush]
  ask bush [
    die  ;
  ]
end

to-report new-genome [ size-of ]
  let a-genome []
  repeat size-of [set a-genome lput random 2 a-genome]
  report a-genome
end

to-report mutate [ a-genome mutation-rate ]
  let n-genome []
  foreach a-genome [ x ->
    let roll random-float 100
    if-else roll < mutation-rate [
      if-else x = 1 [set n-genome lput 0 n-genome]
      [set n-genome lput 1 n-genome]
    ]
    [
      set n-genome lput x n-genome
    ]
  ]
  report n-genome
end

to-report divider1 ; forager reporter
  let s 0
  let c 0
  repeat 60 [set s s + item c genome set c c + 1]
  report s
end

to-report divider2 ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 60) genome set c c + 1 ]
  report s
end

to-report get-intelligence ; forager reporter
  report min (list divider1 divider2)
end

to-report get-speed ; forager reporter
  report abs (divider1 - divider2)
end

to-report get-strength ; forager reporter
  report 60 - (max (list divider1 divider2))
end

to-report get-reactive-aggression ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 120) genome set c c + 1 ]
  report s
end

to-report get-proactive-aggression ; forager reporter
  let s 0
  let c 0
  repeat 60 [ set s s + item (c + 180) genome set c c + 1 ]
  report s
end
