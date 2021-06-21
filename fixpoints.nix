rec {
  /* fix :: (a -> a) -> a
  */
  fix = f: let x = f x; in x;

  /* until :: (a -> bool) -> (a -> a) -> a -> a
  */
  until = p: f: x0:
    let
      go = x: if p x then x else go (f x);
    in go x0;

  /* fixEq :: Eq a => (a -> a) -> a -> a
  */
  fixEq = f:
    let go = x: let x' = f x; in if x' == x then x' else go x';
    in go;
}
