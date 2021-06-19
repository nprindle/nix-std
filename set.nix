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

  /* map :: (key -> value -> value) -> set -> set
  */
  map = builtins.mapAttrs;

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

  /* sequence :: Applicative f => set key (f a) -> f (set key a)
  */
  sequence = ap:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.ap (ap.map (assign k) v) (sequence ap r);
    };

  /* toList :: set -> [(key, value)]
  */
  toList = s: list.map (k: { _0 = k; _1 = s.${k}; }) (keys s);
}
