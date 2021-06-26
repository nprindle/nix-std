let
  set = import ./set.nix;
  list = import ./list.nix;
  string = import ./string.nix;
  optional = import ./optional.nix;

  joinComponents = parts:
    if list.length parts > 0 && list.index parts 0 == "/"
      then "/" + string.concatSep "/" (list.tail parts)
      else string.concatSep "/" parts;
in rec {
  inherit (builtins) baseNameOf dirOf;

  /* normalize :: string | path -> string
  */
  normalize = path: joinComponents (components path);

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
    in if parts == [ "." ]
      then parts
      else list.filter (p: p != "." && p != "") (list.reverse parts);

  /* parents :: path -> [path]

     Get the successive parents of a path.

     Can also handle path-like strings, but if the path is relative, the parents
     will only continue until the base of the relative path (usually the current
     directory).
  */
  parents = path:
    if builtins.isPath path
    then
      let
        parts = list.unfold
          (p:
            if p == /.
            then optional.nothing
            else optional.just { _0 = p; _1 = builtins.dirOf p; }
          )
          path;
      in parts ++ [ /. ]
    else
      let
        cs = components path;
        go = acc: xs:
          if list.length xs == 0
          then acc
          else go (acc ++ [(joinComponents xs)]) (list.init xs);
      in go [] cs;
}
