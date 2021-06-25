let
  set = import ./set.nix;
  list = import ./list.nix;
  string = import ./string.nix;
  optional = import ./optional.nix;
in rec {
  inherit (builtins) baseNameOf dirOf;

  /* normalize :: string | path -> string
  */
  normalize = path:
    let
      parts = components path;
    in if list.length parts > 0 && list.index parts 0 == "/"
      then "/" + string.concatSep "/" (list.tail parts)
      else string.concatSep "/" parts;

  /* components :: string | path -> [string]
  */
  components = path:
    let
      parts =
        list.unfold
          (mp:
            optional.match mp {
              nothing = optional.nothing;
              just = p:
                let
                  b = builtins.baseNameOf p;
                  d = builtins.dirOf p;
                in
                  if (d == "/" && b == "") || (d == "." && b == ".")
                  then optional.just { _0 = d; _1 = optional.nothing; }
                  else optional.just { _0 = b; _1 = optional.just d; };
            }
          )
          (optional.just path);
    in list.filter (p: p != "." && p != "") (list.reverse parts);
}
