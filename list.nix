with rec {
  function = import ./function.nix;
  inherit (function) const flip compose id;

  num = import ./num.nix;
  inherit (num) min max;

  _optional = import ./optional.nix;
};

rec {
  /* List functor object
  */
  functor = {
    /* map :: (a -> b) -> [a] -> [b]
    */
    inherit map;
  };

  /* List applicative object
  */
  applicative = functor // rec {
    /* pure :: a -> [a]
    */
    pure = singleton;
    /* ap :: [a -> b] -> [a] -> [b]
    */
    ap = lift2 id;
    /* lift2 :: (a -> b -> c) -> [a] -> [b] -> [c]
    */
    lift2 = f: xs: ys: monad.bind xs (x: monad.bind ys (y: singleton (f x y)));
  };

  /* List monad object
  */
  monad = applicative // {
    /* join :: [[a]] -> [a]
    */
    join = concat;

    /* bind :: [a] -> (a -> [b]) -> [b]
    */
    bind = flip concatMap;
  };

  monadFix = monad // {
    /* fix :: (a -> [a]) -> [a]
    */
    fix = f: match (fix (compose f head)) {
      nil = nil;
      cons = x: _: cons x (fix (compose tail f));
    };
  };

  /* List semigroup object
  */
  semigroup = {
    /* append :: [a] -> [a] -> [a]
    */
    append = xs: ys: xs ++ ys;
  };

  /* List monoid object
  */
  monoid = semigroup // {
    /* empty :: [a]
    */
    empty = nil;
  };

  /* match :: [a] -> { nil :: b; cons :: a -> [a] -> b; } -> b

     Pattern match on a list. If the list is empty, 'nil' is run, and if it
     contains a value, 'cons' is run on the head and tail of the list.

     > list.match { nil = false; cons = true; } []
     false
     > list.match { nil = false; cons = true; } [ 1 2 3 ]
     true
  */
  match = xs: args:
    let u = uncons xs;
    in _optional.match u {
      nothing = args.nil;
      just = v: args.cons v._0 v._1;
    };

  /* empty :: [a] -> bool

     Check if the list is empty.

     > list.empty []
     true
  */
  empty = xs: xs == [];

  /* @partial
     head :: [a] -> a

     Get the first element of a list. Fails if the list is empty.

     > list.head [ 1 2 3 ]
     1
  */
  head = builtins.head;

  /* @partial
     tail :: [a] -> [a]

     Return the list minus the first element. Fails if the list is empty.

     > list.tail [ 1 2 3 ]
     [ 2 3 ]
  */
  tail = builtins.tail;

  /* @partial
     init :: [a] -> [a]

     Return the list minus the last element. Fails if the list is empty.

     > list.init [ 1 2 3 ]
     [ 1 2 ]
  */
  init = xs: slice 0 (length xs - 1) xs;

  /* @partial
     last :: [a] -> a

     Get the last element of a list. Fails if the list is empty.

     > list.last [ 1 2 3 ]
     3
  */
  last = xs:
    let len = length xs;
    in index xs (len - 1);

  /* take :: int -> [a] -> [a]

     Take the first n elements of a list. If there are fewer than n elements,
     return as many elements as possible.

     > list.take 3 [ 1 2 3 4 5 ]
     [ 1 2 3 ]
     > list.take 30 [ 1 2 3 4 5 ]
     [ 1 2 3 4 5 ]
  */
  take = n: slice 0 (max 0 n);

  /* drop :: int -> [a] -> [a]

     Return the list minus the first n elements. If there are fewer than n
     elements, return the empty list.

     > list.drop 3 [ 1 2 3 4 5 ]
     [ 4 5 ]
     > list.drop 30 [ 1 2 3 4 5 ]
     []
  */
  drop = n: slice (max 0 n) null;

  /* takeEnd :: int -> [a] -> [a]

     Take the last n elements of a list. If there are fewer than n elements,
     return as many elements as possible.

     > list.takeEnd 3 [ 1 2 3 4 5 ]
     [ 3 4 5 ]
     > list.takeEnd 30 [ 1 2 3 4 5 ]
     [ 1 2 3 4 5 ]
  */
  takeEnd = n: xs:
    let
      len = length xs;
      n' = min len n;
    in slice (len - n') n' xs;

  /* dropEnd :: int -> [a] -> [a]

     Return the list minus the last n elements. If there are fewer than n
     elements, return the empty list.

     > list.dropEnd 3 [ 1 2 3 4 5 ]
     [ 1 2 ]
     > list.dropEnd 30 [ 1 2 3 4 5 ]
     []
  */
  dropEnd = n: xs: slice 0 (max 0 (length xs - n)) xs;

  /* length :: [a] -> int

     Return the length of a list.

     > list.length [ 1 2 3 ]
     3
  */
  length = builtins.length;

  /* singleton :: a -> [a]

     Wrap an element in a singleton list.

     > list.singleton 3
     [ 3 ]
  */
  singleton = x: [x];

  /* map :: (a -> b) -> [a] -> [b]

     Apply a function to every element of a list, returning the resulting list.

     > list.map (x: x + 1) [ 1 2 3 ]
     [ 2 3 4 ]
  */
  map = builtins.map;

  /* for :: [a] -> (a -> b) -> [b]

     Like 'map', but with its arguments reversed.

     > list.for [ 1 2 3 ] (x: x + 1)
     [ 2 3 4 ]
  */
  for = flip map;

  /* imap :: (int -> a -> b) -> [a] -> [b]

     Apply a function to every element of a list and its index, returning the
     resulting list.

     > list.imap (x: [i x]) [ 9 8 7 ]
     [ [ 0 9 ] [ 1 8 ] [ 2 7 ] ]
  */
  imap = f: xs:
    let len = length xs;
    in generate (i: f i (index xs i)) len;

  /* modifyAt :: int -> (a -> a) -> [a] -> [a]

     Apply a function to the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.

     > list.modifyAt 1 (x: 10 * x) [ 1 2 3 ]
     [ 1 20 3 ]
  */
  modifyAt = i: f: imap (j: x: if j == i then f x else x);

  /* setAt :: int -> a -> [a] -> [a]

     Insert an element as the nth element of a list, returning the new list. If
     the index is out of bounds, return the list unchanged.

     > list.setAt 1 20 [ 1 2 3 ]
     [ 1 20 3 ]
  */
  setAt = i: x: modifyAt i (const x);

  /* insertAt :: int -> a -> [a] -> [a]

     Insert an element as the nth element of a list, returning the new list. If
     the index is out of bounds, fail with an exception.

     > list.insertAt 1 20 [ 1 2 3 ]
     [ 1 20 2 3 ]
     > list.insertAt 3 20 [ 1 2 3 ]
     [ 1 2 3 20 ]
  */
  insertAt = i: x: xs:
    let
      len = length xs;
    in if i < 0 || i > len
      then builtins.throw "std.list.insertAt: index out of bounds"
      else generate
        (j:
          if j == i then
            x
          else if j < i then
            index xs j
          else
            index xs (j - 1)
        )
        (len + 1);

  /* ifor :: [a] -> (int -> a -> b) -> [b]

     Like 'imap', but with its arguments reversed.

     > list.ifor[ 9 8 7 ] (x: [i x])
     [ [ 0 9 ] [ 1 8 ] [ 2 7 ] ]
  */
  ifor = flip imap;

  /* @partial
     elemAt :: [a] -> int -> a

     Get the nth element of a list, indexed from 0.

     > list.elemAt [ 1 2 3 ] 1
     2
  */
  elemAt = builtins.elemAt;

  /* @partial
     index :: [a] -> int -> a

     Get the nth element of a list, indexed from 0. An alias for 'elemAt'.

     > list.index [ 1 2 3 ] 1
     2
  */
  index = builtins.elemAt;

  /* concat :: [[a]] -> [a]

     Concatenate a list of lists.

     > list.concat [ [ 1 2 3 ] [ 4 5 ] [ 6 ] ]
     [ 1 2 3 4 5 6 ]
  */
  concat = builtins.concatLists;

  /* filter :: (a -> bool) -> [a] -> [a]

     Apply a predicate to a list, keeping only the elements that match the
     predicate.

     > list.filter num.even [ 1 2 3 4 5 ]
     [ 2 4 ]
  */
  filter = builtins.filter;

  /* elem :: a -> [a] -> bool

     Check if an element is contained in a list.

     > list.elem 7 [ 1 2 3 ]
     false
     > list.elem 7 [ 1 2 3 7 ]
     true
  */
  elem = builtins.elem;

  /* notElem :: a -> [a] -> bool

     Check if an element is not contained in a list.

     > list.notElem 7 [ 1 2 3 ]
     true
     > list.notElem 7 [ 1 2 3 7 ]
     false
  */
  notElem = x: xs: !(builtins.elem x xs);

  /* generate :: (int -> a) -> int -> [a]

     Generate a list given a length and a function to apply to each index.

     > list.generate (i: i * 2) 7
     [ 0 2 4 6 8 10 12 ]
  */
  generate = builtins.genList;

  /* permutations :: [a] -> [[a]]

     Compute all permutations of the input list.

     > list.permutations [ 1 2 3 ]
     [ [ 1 2 3 ] [ 2 1 3 ] [ 2 3 1 ] [ 1 3 2 ] [ 3 1 2 ] [ 3 2 1 ] ]
  */
  permutations = xs: match xs {
    nil = [[]];
    cons = y: ys:
      let perms = permutations ys;
      in concatMap (p: generate (i: insertAt i y p) (length p + 1)) perms;
  };

  /* subsequences :: [a] -> [[a]]

     Compute all non-contiguous ordered subsequences of the list, in which each
     elements corresponds to an element of the powerset of the indices of the
     list.

     > list.subsequences [ 1 2 3 ]
     [ [ ] [ 3 ] [ 2 ] [ 2 3 ] [ 1 ] [ 1 3 ] [ 1 2 ] [ 1 2 3 ] ]
  */
  subsequences = xs: match xs {
    nil = [[]];
    cons = y: ys:
      let seqs = subsequences ys;
      in seqs ++ map (cons y) seqs;
  };

  /* windows :: int -> [a] -> [[a]]

     Create a new list containing all sublists of the original list of length
     `n`, overlapping allowed.

     If there are fewer than `n` elements, returns the empty list.

     Fails if the window size is zero or negative.

     > list.windows 3 (list.range 1 6)
     [[1 2 3] [2 3 4] [3 4 5] [4 5 6]]
  */
  windows = n: xs:
    let
      len = builtins.length xs;
      resultLen = max 0 (len - n + 1);
    in
      if n <= 0
      then builtins.throw "std.list.windows: invalid window size"
      else generate (i: slice i n xs) (len - n + 1);

  /* chunks :: { bias :: "left" | "right", dropExtra :: bool } -> int -> [a] -> [[a]]

     Divide the input list into non-overlapping sublists of size `n`.

     `bias` is either "left" or "right", and will bias the creation of chunks to
     that side, such that any extra chunks of size less than n will be on the
     opposite side. By default, chunks are left-biased.

     If `dropExtra` is true, then any extra chunks of size less than n will be
     discarded. If it is false, then a chunk of size smaller than `n` will be
     left on the opposite side of `bias`. By default, `dropExtra` is false.

     Fails if the chunk size is zero or negative.

     > list.chunks { bias = "left"; dropExtra = false; } 3 (list.range 1 8)
     [ [ 1 2 3 ] [ 4 5 6 ] [ 7 8 ] ]
     > list.chunks { bias = "right"; dropExtra = false; } 3 (list.range 1 8)
     [ [ 1 2 ] [ 3 4 5 ] [ 6 7 8 ] ]
     > list.chunks { bias = "left"; dropExtra = true; } 3 (list.range 1 8)
     [ [ 1 2 3 ] [ 4 5 6 ] ]
     > list.chunks { bias = "right"; dropExtra = true; } 3 (list.range 1 8)
     [ [ 3 4 5 ] [ 6 7 8 ] ]
  */
  chunks = { bias ? "left", dropExtra ? false }: n: xs:
    if bias != "left" && bias != "right" then
      builtins.throw "std.list.chunks: invalid bias side"
    else if n <= 0 then
      builtins.throw "std.list.chunks: invalid chunk size"
    else
      let
        len = builtins.length xs;
        numChunks = num.quot len n;
        leftoverSize = num.rem len n;
        hasLeftover = leftoverSize != 0;
      in
        if !hasLeftover || (dropExtra && bias == "right") then
          generate (i: slice (i * n + leftoverSize) n xs) numChunks
        else if dropExtra then
          # bias == "left", dropExtra = true
          generate (i: slice (i * n) n xs) numChunks
        else if bias == "left" then
          # bias == "left", dropExtra = false
          generate (i: slice (i * n) n xs) (numChunks + 1)
        else
          # bias == "right", dropExtra = false
          generate
            (i:
              if i == 0
              then slice 0 leftoverSize xs
              else slice ((i - 1) * n + leftoverSize) n xs)
            (numChunks + 1);

  /* nil :: [a]

     The empty list, []
  */
  nil = [];

  /* cons :: a -> [a] -> [a]

     Prepend an element to a list

     > list.cons 1 [ 2 3 ]
     [ 1 2 3 ]
  */
  cons = x: xs: [x] ++ xs;

  /* uncons :: [a] -> optional (a, [a])

     Split a list into its head and tail.
  */
  uncons = xs: if (length xs == 0)
    then _optional.nothing
    else _optional.just {
      _0 = builtins.head xs;
      _1 = builtins.tail xs;
    };

  /* snoc :: [a] -> a -> [a]

     Append an element to a list

     > list.snoc [ 1 2 ] 3
     [ 1 2 3 ]
  */
  snoc = xs: x: xs ++ [x];

  /* foldr :: (a -> b -> b) -> b -> [a] -> b

     Right-associative fold over a list, starting at a given accumulator.

     > list.foldr (x: y: x + y) 0 [ 1 2 3 4 ]
     10
  */
  foldr = k: z0: xs:
    let len = length xs;
        go = n:
          if n == len
          then z0
          else k (index xs n) (go (n + 1));
    in go 0;

  /* foldl' :: (b -> a -> b) -> b -> [a] -> b

     Strict left-associative fold over a list, starting at a given accumulator.

     > list.foldl' (x: y: x + y) 0 [ 1 2 3 4 ]
     10
  */
  foldl' = builtins.foldl';

  /* foldMap :: Monoid m => (a -> m) -> [a] -> m

     Apply a function to each element of a list, turning it into a monoid, and
     append all the results using the provided monoid.

     > list.foldMap string.monoid builtins.toJSON [ 1 2 3 4 5 ]
     "12345"
  */
  foldMap = m: f: foldr (compose m.append f) m.empty;

  /* fold :: Monoid m => [m] -> m

     Append all elements of a list using a provided monoid.

     > list.fold monoid.max [ 1 7 3 4 5 ]
     7
  */
  fold = m: foldr m.append m.empty;

  /* sum :: [number] -> number

     Sum a list of numbers.

     > list.sum [ 1 2 3 4 ]
     10
  */
  sum = foldl' (x: y: builtins.add x y) 0;

  /* product :: [number] -> number

     Take the product of a list of numbers.

     > list.product [ 1 2 3 4 ]
     24
  */
  product = foldl' (x: y: builtins.mul x y) 1;

  /* concatMap :: (a -> [b]) -> [a] -> [b]

     Apply a function returning a list to every element of a list, and
     concatenate the resulting lists.

     > list.concatMap (x: [ x x ]) [ 1 2 3 ]
     [ 1 1 2 2 3 3 ]
  */
  concatMap = builtins.concatMap;

  /* any :: (a -> bool) -> [a] -> bool

     Check if any element of a list matches a predicate.

     > list.any num.even [ 1 2 3 ]
     true
     > list.any num.odd [ 2 4 6 ]
     false
  */
  any = builtins.any;

  /* all :: (a -> bool) -> [a] -> bool

     Check if every element of a list matches a predicate. Note that if a list
     is empty, the predicate matches every element vacuously.

     > list.all num.even [ 2 4 6 ]
     true
     > list.all num.odd [ 1 2 3 ]
     false
  */
  all = builtins.all;

  /* none :: (a -> bool) -> [a] -> bool

     Check that none of the elements in a list match the given predicate. Note
     that if a list is empty, none of the elements match the predicate
     vacuously.
  */
  none = p: xs: builtins.all (x: !p x) xs;

  /* count :: (a -> bool) -> [a] -> int

     Count the number of times a predicate holds on the elements of a list.

     > list.count num.even [ 1 2 3 4 5 ]
     2
  */
  count = p: foldl' (c: x: if p x then c + 1 else c) 0;

  /* optional :: bool -> a -> [a]

     Optionally wrap an element in a singleton list. If the condition is true,
     return the element in a singleton list, otherwise return the empty list.

     > list.optional true "foo"
     [ "foo" ]
     > list.optional false "foo"
     []
  */
  optional = b: x: if b then [x] else [];

  /* optionals :: bool -> [a] -> [a]

     Optionally keep a list. If the condition is true, return the list
     unchanged, otherwise return an empty list.

     > list.optionals true [ 1 2 3 ]
     [ 1 2 3 ]
     > list.optionals false [ 1 2 3 ]
     []
  */
  optionals = b: xs: if b then xs else [];

  /* replicate :: int -> a -> [a]

     Create a list containing n copies of an element.

     > list.replicate 4 0
     [ 0 0 0 0 ]
  */
  replicate = n: x: generate (const x) n;

  /* sublist :: nullable int -> nullable int -> [a] -> [a]

     Extract a slice from the input list, starting and ending at the provided
     index bounds, inclusive. A null starting bound implies index 0, and a null
     ending bound implies the last index.

     Fails if either of the indices are non-null and out of bounds. If the
     starting index is greater than the ending index, it will simply return the
     empty list.

     > list.sublist 2 3 [ 1 2 3 4 5 ]
     [ 3 4 ]
     > list.sublist 2 null [ 1 2 3 4 5 ]
     [ 3 4 5 ]
     > list.sublist null 2 [ 1 2 3 4 5 ]
     [ 1 2 3 ]
     > list.sublist null null [ 1 2 3 4 5 ]
     [ 1 2 3 4 5 ]
  */
  sublist = start: end: xs:
    let
      start' = if start == null then 0 else start;
      len = length xs;
      sublistLen = if end == null then null else end - start' + 1;
    in
      if start != null && (start < 0 || start >= len) then
        builtins.throw "std.list.sublist: start index out of bounds"
      else if (end != null && (end < 0 || end >= len)) then
        builtins.throw "std.list.sublist: end index out of bounds"
      else slice start' sublistLen xs;

  /* slice :: int -> nullable int -> [a] -> [a]

     Extract a sublist from a list given a starting position and a length. If
     the starting position is past the end of the list, return the empty list.
     If there are fewer than the requested number of elements after the starting
     position, take as many as possible. If the requested length is null, ignore
     the length and return until the end of the list. If the requested length is
     less than 0, the length used will be 0.

     Fails if the given offset is negative.

     > list.slice 2 2 [ 1 2 3 4 5 ]
     [ 3 4 ]
     > list.slice 2 30 [ 1 2 3 4 5 ]
     [ 3 4 5 ]
     > list.slice 1 null [ 1 2 3 4 5 ]
     [ 2 3 4 5 ]
  */
  slice = offset: len: xs:
    if offset < 0 then
      throw "std.list.slice: negative start position"
    else
      let
        remaining = max 0 (length xs - offset);
        len' = if len == null then remaining else min (max len 0) remaining;
      in generate (i: index xs (i + offset)) len';

  /* range :: int -> int -> [int]

     Generate an ascending range from the first number to the second number,
     inclusive.

     > list.range 4 9
     [ 4 5 6 7 8 9 ]
  */
  range = first: last:
    if first > last
    then []
    else generate (n: first + n) (last - first + 1);

  /* partition :: (a -> bool) -> [a] -> ([a], [a])

     Partition a list into the elements which do and do not match a predicate.

     > list.partition num.even [ 1 2 3 4 5 ]
     { _0 = [ 2 4 ]; _1 = [ 1 3 5 ]; }
  */
  partition = p: xs:
    let bp = builtins.partition p xs;
    in { _0 = bp.right; _1 = bp.wrong; };

  /* traverse :: Applicative f => (a -> f b) -> [a] -> f [b]

     Apply a function to every element of a list, and sequence the results using
     the provided applicative functor.
  */
  traverse = ap: f: foldr (x: ap.lift2 cons (f x)) (ap.pure nil);

  /* sequence :: Applicative f => [f a] -> f [a]

     Use the provided applicative functor to sequence every element of a list of
     applicatives.
  */
  sequence = ap: foldr (x: ap.lift2 cons x) (ap.pure nil);

  /* zipWith :: (a -> b -> c) -> [a] -> [b] -> [c]

     Zip two lists together with the provided function. The resulting list has
     length equal to the length of the shorter list.

     > list.zipWith builtins.add [ 1 2 3 ] [ 4 5 6 7 ]
     [ 5 7 9 ]
  */
  zipWith = f: xs0: ys0:
    let len = min (length xs0) (length ys0);
    in generate (n: f (index xs0 n) (index ys0 n)) len;

  /* zip :: [a] -> [b] -> [(a, b)]

     Zip two lists together into a list of tuples. The resulting list has length
     equal to the length of the shorter list.

     > list.zip [ 1 2 3 ] [ 4 5 6 7 ]
     [ { _0 = 1; _1 = 4; } { _0 = 2; _1 = 5; } { _0 = 3; _1 = 6; } ]
  */
  zip = zipWith (x: y: { _0 = x; _1 = y; });

  /* reverse :: [a] -> [a]

     Reverse a list.

     > list.reverse [ 1 2 3 ]
     [ 3 2 1 ]
  */
  reverse = xs:
    let len = length xs;
    in generate (n: index xs (len - n - 1)) len;

  /* unfold :: (b -> optional (a, b)) -> b -> [a]

     Build a list by repeatedly applying a function to a starting value. On each
     step, the function should produce a tuple of the next value to add to the
     list, and the value to pass to the next iteration. To finish building the
     list, the function should return null.

     > list.unfold (n: if n == 0 then optional.nothing else optional.just { _0 = n; _1 = n - 1; }) 10
     [ 10 9 8 7 6 5 4 3 2 1 ]
  */
  unfold = f: x0:
    let
      go = xs: next:
        _optional.match next {
          nothing = xs;
          just = v: go (xs ++ [v._0]) (f v._1);
        };
    in go [] (f x0);

  /* findIndex :: (a -> bool) -> [a] -> optional int

     Find the index of the first element matching the predicate, or
     `optional.nothing` if no element matches the predicate.

     > list.findIndex num.even [ 1 2 3 4 ]
     { _tag = "just"; value = 1; }
     > list.findIndex num.even [ 1 3 5 ]
     { _tag = "nothing"; }
  */
  findIndex = pred: xs:
    let
      len = length xs;
      go = i:
        if i >= len
        then { _tag = "nothing"; } #_optional.nothing
        else if pred (index xs i)
             then { _tag = "just"; value = i; } #_optional.just i
             else go (i + 1);
    in go 0;

  /* findLastIndex :: (a -> bool) -> [a] -> optional int

     Find the index of the last element matching the predicate, or
     `optional.nothing` if no element matches the predicate.

     > list.findLastIndex num.even [ 1 2 3 4 ]
     { _tag = "just"; value = 3; }
     > list.findLastIndex num.even [ 1 3 5 ]
     { _tag = "nothing"; }
  */
  findLastIndex = pred: xs:
    let
      len = length xs;
      go = i:
        if i < 0
        then _optional.nothing
        else if pred (index xs i)
             then _optional.just i
             else go (i - 1);
    in go (len - 1);

  /* find :: (a -> bool) -> [a] -> optional a

     Find the first element matching the predicate, or `optional.nothing` if no
     element matches the predicate.

     > list.find num.even [ 1 2 3 4 ]
     { _tag = "just"; value = 2; }
     > list.find num.even [ 1 3 5 ]
     { _tag = "nothing"; }
  */
  find = pred: xs:
    _optional.match (findIndex pred xs) {
      nothing = _optional.nothing;
      just = i: _optional.just (index xs i);
    };

  /* findLast :: (a -> bool) -> [a] -> optional a

     Find the last element matching the predicate, or `optional.nothing` if no
     element matches the predicate.

     > list.find num.even [ 1 2 3 4 ]
     { _tag = "just"; value = 4; }
     > list.find num.even [ 1 3 5 ]
     { _tag = "nothing"; }
  */
  findLast = pred: xs:
    _optional.match (findLastIndex pred xs) {
      nothing = _optional.nothing;
      just = i: _optional.just (index xs i);
    };

  /* splitAt :: int -> [a] -> ([a], [a])

     Split a list at an index, returning a tuple of the list of values before
     and after the index.

     > list.splitAt 1 [ 1 2 3 ]
     { _0 = [ 1 ]; _1 = [ 2 3 ]; }
  */
  splitAt = n: xs: { _0 = take n xs; _1 = drop n xs; };

  /* takeWhile :: (a -> bool) -> [a] -> [a]

     Return the longest prefix of the list matching the predicate.

     > list.takeWhile num.even [ 2 4 6 9 10 11 12 14 ]
     [ 2 4 6 ]
  */
  takeWhile = pred: xs:
    _optional.match (findIndex (x: !pred x) xs) {
      nothing = xs;
      just = i: take i xs;
    };

  /* dropWhile :: (a -> bool) -> [a] -> [a]

     Discard the longest prefix of the list matching the predicate.

     > list.dropWhile num.even [ 2 4 6 9 10 11 12 14 ]
     [ 9 10 11 12 14 ]
  */
  dropWhile = pred: xs:
    _optional.match (findIndex (x: !pred x) xs) {
      nothing = xs;
      just = i: drop i xs;
    };

  /* takeWhileEnd :: (a -> bool) -> [a] -> [a]

     Return the longest suffix of the list matching the predicate.

     > list.takeWhileEnd num.even [ 2 4 6 9 10 11 12 14 ]
     [ 12 14 ]
  */
  takeWhileEnd = pred: xs:
    _optional.match (findLastIndex (x: !pred x) xs) {
      nothing = xs;
      just = i: drop (i + 1) xs;
    };

  /* dropWhileEnd :: (a -> bool) -> [a] -> [a]

     Discard the longest suffix of the list matching the predicate.

     > list.dropWhileEnd num.even [ 2 4 6 9 10 11 12 14 ]
     [ 2 4 6 9 10 11 ]
  */
  dropWhileEnd = pred: xs:
    _optional.match (findLastIndex (x: !pred x) xs) {
      nothing = xs;
      just = i: take (i + 1) xs;
    };

  /* span :: (a -> bool) -> [a] -> ([a], [a])

     Find the longest prefix satisfying the given predicate, and return a tuple
     of this prefix and the rest of the list.

     > list.span num.even [ 2 4 6 9 10 11 12 14 ]
     { _0 = [ 2 4 6 ]; _1 = [ 9 10 11 12 14 ]; }
  */
  span = pred: xs:
    _optional.match (findIndex (x: !pred x) xs) {
      nothing = { _0 = xs; _1 = []; };
      just = n: splitAt n xs;
    };

  /* break :: (a -> bool) -> [a] -> ([a], [a])

     Find the longest prefix that does not satisfy the given predicate, and
     return a tuple of this prefix and the rest of the list.

     > list.break num.odd [ 2 4 6 9 10 11 12 14 ]
     { _0 = [ 2 4 6 ]; _1 = [ 9 10 11 12 14 ]; }
  */
  break = pred: xs:
    _optional.match (findIndex pred xs) {
      nothing = { _0 = xs; _1 = []; };
      just = n: splitAt n xs;
    };

  /* padLeft :: int -> a -> [a]

     Pad a list to the left to a given length, adding copies of the padding
     element on the left side if necessary. Does not shorten the list if the
     target length is shorter than the original list.

     > list.padLeft 5 0 [ 1 0 ]
     [ 0 0 0 1 0 ]
     > list.padLeft 3 1 [ 1 0 1 0 1 ]
     [ 1 0 1 0 1 ]
  */
  padLeft = n: fill: xs:
    let
      listLen = length xs;
      padLen = num.max 0 (n - listLen);
      padding = take padLen (replicate padLen fill);
    in if padLen > 0
      then padding ++ xs
      else xs;

  /* padRight :: int -> a -> [a]

     Pad a list to the right to a given length, adding copies of the padding
     element on the right side if necessary. Does not shorten the list if the
     target length is shorter than the original list.

     > list.padRight 5 0 [ 0 1 ]
     [ 0 1 0 0 0 ]
     > list.padRight 3 1 [ 1 0 1 0 1 ]
     [ 1 0 1 0 1 ]
  */
  padRight = n: fill: xs:
    let
      listLen = length xs;
      padLen = num.max 0 (n - listLen);
      padding = take padLen (replicate padLen fill);
    in if padLen > 0
      then xs ++ padding
      else xs;

  # TODO: dictionary passing? "default" Ord instance?
  /* insert :: Ord a => a -> [a] -> [a]

     Insert an element into a list in the first position where it is less than
     or equal to the next element. If the input list is sorted, the result will
     also be sorted.
  */
  insert = x: xs: _optional.match (findIndex (y: x <= y) xs) {
    nothing = xs ++ [x];
    just = i: insertAt i x xs;
  };
  # TODO: insertBy

  # TODO: dictionary passing? "default" Eq instance?
  /* nub :: Eq a => [a] -> [a]

     Remove all duplicate elements from a list. The first occurrence of each
     element is kept.
  */
  nub = nubBy (x: y: x == y);

  /* nubBy :: (a -> a -> bool) -> [a] -> [a]

     Like `nub`, but using a custom comparison function.
  */
  nubBy = f:
    let
      go = seen: acc: xs:
        match xs {
          nil = acc;
          cons = y: ys:
            if any (f y) seen
            then go seen acc ys
            else go ([y] ++ seen) (acc ++ [y]) ys;
        };
    in go [] [];
}
