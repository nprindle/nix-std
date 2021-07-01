with rec {
  function = import ./function.nix;
  inherit (function) id flip;
  list = import ./list.nix;
};

rec {
  semigroup = {
    append = x: y: x // y;
  };

  monoid = semigroup // {
    inherit empty;
  };

  /* empty :: set
  */
  empty = {};

  /* assign :: key -> value -> set -> set
  */
  assign = k: v: r: r // { "${k}" = v; };

  /* merge :: set -> set -> set
  */
  merge = a1: a2: a1 // a2;

  /* mergeRecursive :: set -> set -> set
  */
  mergeRecursive =
    let
      go = a1: a2:
        builtins.foldl'
        (acc: k:
          let
            v1 = a1.${k};
            v2 = a2.${k};
            v' =
              if builtins.hasAttr k acc && builtins.isAttrs v1 && builtins.isAttrs v2
              then go v1 v2
              else v2;
          in acc // { ${k} = v'; }
        )
        a1
        (builtins.attrNames a2);
    in go;

  /* contains :: key -> set -> bool
  */
  contains = k: s: s ? "${k}";

  /* remove :: key -> set -> set
  */
  remove = k: a: builtins.removeAttrs a [k];

  /* removeAll :: [key] -> set -> set
  */
  removeAll = ks: a: builtins.removeAttrs a ks;

  match = o: { empty, assign }:
    if o == {}
    then empty
    else match1 o { inherit assign; };

  # O(log(keys))
  match1 = o: { assign }:
    let k = list.head (keys o);
        v = o."${k}";
        r = builtins.removeAttrs o [k];
    in assign k v r;

  /* keys :: set -> [key]
  */
  keys = builtins.attrNames;

  /* values :: set -> [value]
  */
  values = builtins.attrValues;

  /* mapWithKey :: (key -> value -> value) -> set -> set
  */
  mapWithKey = builtins.mapAttrs;

  /* map :: (value -> value) -> set -> set
  */
  map = f: mapWithKey (_: f);

  /* mapKeysWith :: (value -> value -> value) -> (key -> key) -> set -> set
  */
  mapKeysWith = f: g:
    (flip match) {
      empty = empty;
      assign = k: v: r:
        let
          rest = mapKeysWith f g r;
          newKey = g k;
        in assign newKey
          (if contains newKey rest then f rest."${newKey}" v else v)
          rest;
    };

  /* filter :: (key -> value -> bool) -> set -> set
  */
  filter = builtins.filterAttrs;

  /* traverse :: Applicative f => (a -> f b) -> set key a -> f (set key b)
  */
  traverse = ap: f:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.ap (ap.map (assign k) (f v)) (traverse ap f r);
    };

  /* traverseWithKey :: Applicative f => (key -> a -> f b) -> set key a -> f (set key b)
  */
  traverseWithKey = ap: f:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.ap (ap.map (assign k) (f k v)) (traverse ap f r);
    };

  /* sequence :: Applicative f => set key (f a) -> f (set key a)
  */
  sequence = ap:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.ap (ap.map (assign k) v) (sequence ap r);
    };

  /* toList :: set -> [(key, value)]

     Convert a set to a list of key-value tuples.
  */
  toList = s: list.map (k: { _0 = k; _1 = s.${k}; }) (keys s);

  /* fromList :: [(key, value)] -> set

     Convert a list of key-value tuples to a set. If two pairs have the same
     key, the later one will take precedence, and the first will be discarded
     from the final result.
  */
  fromList = list.foldl' (as: { _0, _1 }: as // { "${_0}" = _1; }) {};

  /* intersect :: set -> set -> set
  */
  intersect = builtins.intersectAttrs;
}
