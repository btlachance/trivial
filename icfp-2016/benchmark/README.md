benchmark
===

Format
---

- Benchmark gets dedicated folder
- 2 required folders inside benchmark folder
  - `pre`  : code without `trivial`
  - `post` : code after adding `trivial`
- 1 optional folder
  - `base` : contains shared data files


Test Cases
---



Changes
---
(Anything to get it to typecheck?)

- fsm        : changed a few defines
               automata.rkt
               46:(define: COOPERATE 0)
               48:(define: DEFECT    1)
               163:(define: PAYOFF-TABLE

               population.rkt
               42:(define: DEF-COO 2)
- gregor     : a few arithmetic constants
- hyphenate  : 1 set!, ignored the import
               hyphenate.rkt
               51:(define: default-min-length 5)
               52:(define: default-min-left-length 2)
               53:(define: default-min-right-length 2)
               54:(define: default-joiner #\u00AD)
- modulegraph : simplified some regexp matching, no more dev assertions
- morse-code : 1 set!, 12 lines (just ignored the import)
               removed an annotation on regexp-match
- suffixtree : 2 set! to set-box!, 6 lines affected
- synth      : had to remove racket/vector imports



Other
---

shootout was a failure, the code is a little too weird
