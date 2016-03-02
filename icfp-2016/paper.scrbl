#lang scribble/sigplan @onecolumn @preprint

@(require "common.rkt")

@authorinfo["Ben Greenman and Matthias Felleisen"
            "Northeastern University, Boston, USA"
            ""]

@title{Functional Pearl: Do you see what I see?}
@subtitle{Improving a simple type system with dependent macros}
@; should say "value-dependent"?
@; TODO subtitle doesn't appear in the right place

@abstract{
  A simple type system with macros is nearly as good as a dependent type
   system, at least for some common programming tasks.
  By analyzing program syntax and propogating constants
   before type-checking, we can express many of the practical
   motivations for dependent types without any programmer annotations
   or extensions to the underlying type system.

  Our syntax-dependent subtypes are not proving theorems,
   but they detect certain run-time errors at compile-time and
   cooperate with type inference.
}

@;@category["D.3.3" "Programming Languages" "Language Constructs and Features"]
@;@terms{Performance, Experimentation, Measurement}
@;@keywords{Gradual typing, performance evaluation}

@include-section{intro.scrbl}
@include-section{solution.scrbl}

@;@section[#:style 'unnumbered]{Acknowledgments}
@; acks here

@generate-bibliography[#:sec-title "References"]
