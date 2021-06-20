let
  set = import ./set.nix;
  list = import ./list.nix;
in rec {
  inherit (builtins) baseNameOf dirOf;

  /* readFile :: path -> string
  */
  readFile = builtins.readFile;

  /* exists :: path -> bool
  */
  exists = builtins.pathExists;

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

  /* type :: path -> "regular" | "directory" | "symlink" | "unknown"

     Returns whether the given path points to a regular file, a directory, a
     symlink, or unknown.
  */
  type = p:
    if p == /.
    then "directory"
    else (readDir (dirOf p)).${baseNameOf p};
}
