# Fold Functions

Folds functions within your code. Currently comes with a toggle, fold, and unfold option that will look for functions marked with 'meta.function'. Handy because it won't fold things like comments associated with functions.

![screenshot](http://robballou.com/i/fold.gif)

*Note: this currently folds only those functions it finds at a single indentation (e.g. it will fold the top level functions)*

Heavily inspired/influnced by [Fold Comments](https://atom.io/packages/fold-comments).

## Autofolding

You can turn on the auto-folding feature with the following in your configuration file:

```coffescript
"fold-functions":
    autofold: true
    shortfileCutoff: 42
```

By default, this is setup to ignore files that are under 42 lines. This can be configured by changing the `shortfileCutoff` option to a larger or smaller number. If you wish to fold all files, even short ones, you can change this option to `0`.
