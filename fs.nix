let
  set = import ./set.nix;
  list = import ./list.nix;
in rec {
  /* exists :: path -> bool
  */
  exists = builtins.pathExists;

  /* type :: path -> "regular" | "directory" | "symlink" | "unknown"

     Returns whether the given path points to a regular file, a directory, a
     symlink, or unknown.
  */
  type = p:
    if p == /.
    then "directory"
    else (readDir (dirOf p)).${baseNameOf p};

  /* readFile :: path -> string
  */
  readFile = builtins.readFile;

  /* readDir :: path -> attrset

     Returns an attrset mapping base names to file types.
  */
  readDir = builtins.readDir;

  ls = p:
    let
      contents = set.toList (readDir p);
      withPath = list.map ({ _0, _1 }:
        { "${_0}" = { path = p + "/${_0}"; type = _1; };
      }) contents;
    in list.fold set.monoid withPath;

  listRecursive = p:
    let
      contents = set.toList (readDir p);
      visit = name: type:
        let path = p + "/${name}";
        in if type == "directory"
          then listRecursive path
          else [ { inherit name path type; } ];
    in list.concatMap ({ _0, _1 }: visit _0 _1) contents;

  tree = p:
    let
      recurse = sp:
        if sp.type == "directory" then
          sp // {
            contents = tree sp.path;
          }
        else if sp.type == "symlink" then
          sp # TODO: get this working with symlinks somehow
        else
          sp;
    in set.map (_: recurse) (ls p);
}
