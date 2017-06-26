{ lib }: 
{
  # variant of lib.extends which uses recursive set merging instead of //
  extendsRec = f: rattrs: self: let super = rattrs self; in lib.recursiveUpdate super (f self super);

  # Can be used to extend a custom configuration. 
  # The extension `g` can access settings from the customized configuration with `super` and default values with `default`.
  # Based on lib.composeExtensions using recursive set merging instead of //.
  composeConfig =
    f: g: self: default:
      let fApplied = f self default;
          super = lib.recursiveUpdate default fApplied;
      in lib.recursiveUpdate fApplied (g self super default);
}
