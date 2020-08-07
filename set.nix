with {
  function = import ./function.nix;
  list = import ./list.nix;
};

rec {
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

  /* traverse :: Applicative f => (value -> f
  */
  traverse = ap: f:
    (flip match) {
      empty = ap.pure empty;
      assign = k: v: r: ap.lift2 function.identity (ap.map (assign k) (f v)) (traverse ap f r);
    };
}