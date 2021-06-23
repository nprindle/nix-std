let
  set = import ./set.nix;
  list = import ./list.nix;
  string = import ./string.nix;
  regex = import ./regex.nix;
  fixpoints = import ./fixpoints.nix;
  function = import ./function.nix;
in rec {
  inherit (builtins) baseNameOf dirOf;

  isAbsolute = path: string.hasPrefix "/" path;

  /* normalize :: string | path -> string
  */
  normalize = path:
    fixpoints.fixEq
      (function.chain [
        # remove duplicate separators
        (regex.substitute "/{2,}" "/")
        # remove intermediate "/./"
        (regex.substitute ''(.)/\./'' ''\1/'')
        # remove leading "/./" (except if path is only "/.")
        (x:
          if x == "/."
          then "/"
          else regex.substitute ''^/\./'' "/" x
        )
        # remove trailing "/." (except if path is only "/.")
        (x:
          if x == "/."
          then "/"
          else regex.substitute ''/\.$'' "" x
        )
        # remove leading "./"
        (x:
          if x == "./"
          then "."
          else string.removePrefix "./" x
        )
        # remove trailing "/" (except if path is only "/")
        (x:
          if x == "/"
          then "/"
          else string.removeSuffix "/" x
        )
      ])
      (builtins.toString path);

  /* components :: string | path -> [string]
  */
  components = path:
    let
      path' = normalize path;
      cs = regex.splitOn "/" path';
      cs' = if isAbsolute path' then list.setAt 0 "/" cs else cs;
    in cs';
}
