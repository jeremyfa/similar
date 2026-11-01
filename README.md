# similar (Haxe port)

A pure Haxe port of [similar](https://github.com/mitsuhiko/similar) **2.7.0**, the Rust diffing library by Armin Ronacher (with code inherited from Pierre-Étienne Meunier and Brandon Williams), with its `text` (default) and `unicode` features, like gpui-kit uses it.

It runs on every Haxe target. Its only dependency is the Haxe port of [unicode-segmentation](../unicode-segmentation) (grapheme and word bounds of the `unicode` feature). All credit goes to the upstream project; each Haxe module starts with a header naming the Rust file it comes from. The code is distributed under the same license as upstream, Apache-2.0 (see [LICENSE](LICENSE)).

## What is ported

- the algorithms (`similar.algorithms`): `Myers`, `Patience`, `Lcs`, the generic `Algorithms.diff` / `diffDeadline` / `diffSlices`, the hooks `DiffHook` (with the trait defaults in `DiffHookBase`), `Capture`, `Compact`, `Replace`, `NoFinishHook`, and the utilities `IdentifyDistinct`, `AlgorithmUtils.unique`, `commonPrefixLen`, `commonSuffixLen`;
- the types: `Algorithm`, `ChangeTag`, `DiffTag`, `DiffOp`, `Change`, and the iterators `ChangesIter` / `AllChangesIter`;
- the top level functions (`Similar`): `captureDiff`, `captureDiffDeadline`, `captureDiffSlices`, `captureDiffSlicesDeadline`, `getDiffRatio`, `groupDiffOps`, `getCloseMatches`;
- text diffs: `TextDiff`, `TextDiffConfig` (lines, words, chars, unicode words, graphemes, slices) and `DiffableStr` for strings;
- unified diffs (`similar.udiff`): `UnifiedDiff`, `UnifiedDiffHunk`, `UnifiedHunkHeader`, `UnifiedDiff.unifiedDiff`;
- `similar.utils`: `TextDiffRemapper` and `Utils.diffSlices`, `diffChars`, `diffWords`, `diffUnicodeWords`, `diffGraphemes`, `diffLines`.

Not ported: the `bytes` feature (diffs of byte slices with `bstr`), the `inline` feature (`InlineChange`, `iter_inline_changes`), `serde` and `wasm32_web_time`.

## Differences with the Rust API

- Names are converted to camelCase. Parameters named `new` in Rust are `newSeq` / `newText`. Getters keep their Rust form (`diff.ops()`, `change.tag()`, `op.tag()`); the fields of the `DiffOp` variants are read-only fields (`oldIndex`, `newIndex`, `oldLen`, `newLen`, `len`).
- `DiffOp` is a class with the static constructors `DiffOp.equal`, `delete`, `insert`, `replace` (Rust enum variants). Its `toString()` is the Rust `Debug` form.
- Sequences are `Lookup<T>`: an `Array<T>` (converted implicitly) or a function from an index to a value (Rust `Index<usize>`). Values are compared with Haxe `==`. Where the crate hashes values (patience, `IdentifyDistinct`, close matches), strings and integers are hashed and other values are found with `==`. The `*By` variants of the algorithms take a comparison function `(newIndex, oldIndex) -> Bool` instead.
- Ranges are `similar.Range` (`start`, `end`). Functions that return Rust tuples return `TaggedValue` (`tag`, `value`) or `DiffTagTuple` (`tag`, `oldRange`, `newRange`) structures.
- Hooks return nothing: Rust's `Result` error becomes an exception thrown by the hook.
- Text is Haxe `String`. Lengths and slice offsets of `DiffableStr` are UTF-8 byte offsets like in Rust, on every target. Iterators return null at the end of `next()`, have `collect()`, and work with Haxe `for` loops.
- Deadlines are absolute times in seconds on the `haxe.Timer.stamp()` clock (Rust `Instant`), timeouts are seconds (Rust `Duration`).
- Ratios are rounded to single precision like the Rust `f32`.
- Like upstream, the remapper of `similar.utils` fails on some inputs: the LCS diff of two empty sequences yields an empty `Delete` op, which `TextDiffRemapper.iterSlices` cannot slice (Rust panics with "slice out of bounds", the port throws the same message).

## Usage

```haxe
import similar.ChangeTag;
import similar.TextDiff;

class Main {

    static function main() {
        var diff = TextDiff.fromLines("Hello World\nThis is the second line.\nThis is the third.",
            "Hallo Welt\nThis is the second line.\nThis is life.\nMoar and more");
        for (change in diff.iterAllChanges()) {
            var sign = switch (change.tag()) {
                case Delete: "-";
                case Insert: "+";
                case Equal: " ";
            }
            Sys.print(sign + change.toString());
        }
        trace(diff.unifiedDiff().contextRadius(3).header("old", "new").toString());
    }

}
```

## Tests

The `test` folder contains a runner that does not need Ceramic:

- every `#[test]` of the crate that the ported features compile, with the upstream insta snapshots (copied in `test/snapshots`, compared with a Rust `{:#?}` printer), and the doc examples;
- a validation against the original crate: `test/refdata.jsonl` holds the results of similar 2.7.0 itself on generated inputs (900 integer sequence diffs with raw, replaced and compacted ops, grouping and ratios; 750 line diffs with changes, unified diffs and `utils`; 3000 word, char, unicode word and grapheme diffs; 250 tokenizations; 300 close match queries), written by the small Rust program in `tools/refgen` (`cargo run --offline --release > ../../test/refdata.jsonl` from that folder).

```sh
cd test
./run.sh                    # JavaScript build, run with node
haxe build-cpp.hxml && ./bin/cpp/Main
haxe -cp ../src -cp src -cp ../../unicode-segmentation/src -main Main --interp
```

Not ported: the tests of the `bytes`, `inline` and `serde` features.

## License

Apache-2.0, like upstream similar: see [LICENSE](LICENSE) (Copyright Armin Ronacher and contributors).
