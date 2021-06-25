rec {
  /* true :: bool
  */
  true = builtins.true;

  /* false :: bool
  */
  false = builtins.false;

  /* not :: bool -> bool
  */
  not = x: !x;

  /* ifThenElse :: bool -> a -> a -> a
  */
  ifThenElse = b: x: y: if b then x else y;

  /* xor :: bool -> bool -> bool
  */
  xor = x: y: x != y;

  /* xnor :: bool -> bool -> bool
  */
  xnor = x: y: x == y;

  /* implies :: bool -> bool -> bool
  */
  implies = x: y: x -> y;
}
