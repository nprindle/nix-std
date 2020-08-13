rec {
  /* id :: a -> a
  */
  id = x: x;

  /* const :: a -> b -> a
  */
  const = a: _: a;

  /* apply :: (a -> b) -> a -> b
  */
  apply = f: x: f x;

  /* compose :: (b -> c) -> (a -> b) -> (a -> c)
  */
  compose = bc: ab: a: bc (ab a);

  /* flip :: (a -> b -> c) -> b -> a -> c
  */
  flip = f: b: a: f a b;

  /* on :: (b -> b -> c) -> (a -> b) -> a -> a -> c
  */
  on = f: proj: x: y: f (proj x) (proj y);

  /* pipe :: a -> [a -> a] -> a
  */
  pipe = x0: fs: builtins.foldl' (flip apply) fs x0;
}
