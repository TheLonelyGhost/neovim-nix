{ pkgs, ... }:

let
  /* Plugins are assumed to adhere to the following schema, denoted as
     <plugin-attrset> hereafter:

         {
           plugin = <derivation>;  # REQUIRED
           config = <viml-string>;
           dependencies = [<plugin-attrset> ...];
           weight = <priority-uint>;
         }

     `plugin` represents the vim-plugin formatted nix package.

     `config` is a string whose configuration will be observed if the
     plugin is loaded.

     `dependencies` may be zero or more <plugin-attrset> items.

     `weight` may be any integer between 0 and 100 (inclusive) where
     the lesser is determined to occur first in the overall
     configuration. Defaults to 50 so plugins of declared higher or
     lower priority reflow around unspecified priority plugins.
  */

  isValidPluginAttrset = plug:
    pkgs.lib.all (x: x) (
      # required attributes checks {{
      [
        (plug ? plugin)
      ]
      # }}
      ++
      # type checks {{ 
      (pkgs.lib.optionals (plug ? plugin) [
        (isValidPluginDerivation plug)
      ])
      ++
      (pkgs.lib.optionals (plug ? config) [
        (isValidConfig plug.config)
      ])
      ++
      (pkgs.lib.optionals (plug ? dependencies) [
        (isValidDependencies plug.dependencies)
      ])
      ++
      (pkgs.lib.optionals (plug ? weight) [
        (isValidWeight plug.weight)
      ])
      # }}
    );

  isValidPluginDerivation = deriv:
    builtins.hasAttr "name" deriv;

  defaultWeight = 50;
  isValidWeight = weight:
    pkgs.lib.any (x: x == weight) (pkgs.lib.range 0 100);

  defaultDependencies = [];
  isValidDependencies = dependencies:
    (builtins.isList dependencies)
    &&
    (pkgs.lib.all (x: isValidPluginAttrset x) dependencies);

  defaultConfig = "";
  isValidConfig = config:
    builtins.isString config;

  recurseDependencies = plugin-attrset:
    [ plugin-attrset ] ++
    (pkgs.lib.optionals (plugin-attrset ? dependencies)
      (pkgs.lib.concatMap recurseDependencies plugin-attrset.dependencies)
    );

  /* Ensures a single plugin adheres to the plugin-attrset schema under
     the following circumstances:

     1. it must have a `plugin` attribute, at which point all optional
        attributes will be set to their default values so we can rely
        on a specific structure.
     2. if not (1), assume the given item is a package (derivation) and
        assign it to `plugin` attribute, following the rest of the
        logic in (1) accordingly.
  */
  normalize = x:
    # Default values for optional attributes
    {
      optional = false;
      config = "";
      dependencies = [ ];
      weight = defaultWeight;
    } //
    # If no `plugin` attribute, must be a bare package
    (if x ? plugin then x else { plugin = x; });

  sortByWeightAlgo = a: b:
    let
      first = if a ? weight then a.weight else 50;
      second = if b ? weight then b.weight else 50;
    in
    first < second;

  /* Transforms a list of plugins in a way that validates with
     `isValidPluginAttrset`.

         plugins = normalizePlugins myManifest;
  */
  normalizePlugins = plugins:
    map normalize plugins;

  /* Recurses through each dependency (and its dependencies, etc.) to
     create a flat list of plugin-attrset. May contain duplicate plugin
     packages.

         plugins = flattenPlugins myManifest;
  */
  flattenPlugins = plugins:
    pkgs.lib.concatMap recurseDependencies plugins;

  /* Combines <plugin-attrset> type structures that have the same
     package to also have appropriately combined settings.

         plug = combinePlugins plugin-1 plugin-2;
     OR
         plug = pkgs.lib.foldl combinePlugins listOfPlugins;
  */
  combinePlugins = plug1: plug2:
    let
      # Grab the value from the first subject that has the given
      # attribute path. If none have it, defer to the provided default.
      # Prefers the first item in the list of subjects, all things
      # being equal.
      someAttr = attrPath: default: subjects:
        pkgs.lib.foldl (a: b: pkgs.lib.attrByPath attrPath (pkgs.lib.attrByPath attrPath default b) a) { } subjects;

      confGrabber = pkgs.lib.attrByPath [ "config" ] "";
      weightGrabber = pkgs.lib.attrByPath [ "weight" ] 999999; # some invalid weight

      config = pkgs.lib.concatStringsSep "\n" (pkgs.lib.filter (x: x != "") [ (confGrabber plug1) (confGrabber plug2) ]);

      weight = builtins.min (weightGrabber plug1) (weightGrabber plug2);

      plugin = someAttr [ "plugin" ] null [ plug1 plug2 ];
    in

    # null should never happen for both, but because `foldl` sometimes
    # makes the left side null (processing first element of list) _OR_
    # the right side be null (processing last element of list). Ergo we
    # say "try <first>, then try <second>, else <error-value>", then
    # enforce that error value with an assertion here.
    assert plugin != null;
    {
      inherit plugin config;
    } // pkgs.lib.optional (isValidWeight weight) {
      inherit weight;
    };

  /* A specialized `unique` lambda that is customized to handle a list
     of <plugin-attrset> items. When things are not unique, it combines
     them intelligently into a new item according to `combinePlugins`
  */
  dedupePlugins = plugins:
    let
      testMoreThanOneListItem = maybeList:
        if builtins.isList maybeList then (builtins.length maybeList) > 1 else false;

      grouped = pkgs.lib.groupBy (p: p.plugin.name) plugins;
      deduped = pkgs.lib.mapAttrsToList
          (attr: plugins:
          assert builtins.isList plugins;
          let
            len = builtins.length plugins;
          in
          assert len > 0;

          if len == 1 then
            builtins.elemAt plugins 0
          else
            pkgs.lib.foldl combinePlugins plugins
        )
        grouped;
    in
    deduped;

  sortPlugins = plugins:
    pkgs.lib.sort sortByWeightAlgo plugins;

  trimPluginAttrs = plugins:
    map (x: builtins.removeAttrs x [ "weight" "dependencies" ]) plugins;

  processPlugins = plugins:
    trimPluginAttrs (
      sortPlugins (
        dedupePlugins (
          flattenPlugins (
            normalizePlugins plugins
          )
        )
      )
    )
  ;
in
{
  inherit processPlugins sortByWeightAlgo;

  # for debugging, to be removed later:
  inherit trimPluginAttrs sortPlugins dedupePlugins combinePlugins flattenPlugins normalizePlugins normalize recurseDependencies;
  inherit isValidWeight isValidConfig isValidDependencies isValidPluginAttrset isValidPluginDerivation;
}
