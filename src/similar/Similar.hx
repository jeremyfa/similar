// Ported from similar 2.7.0: src/common.rs and `get_close_matches` of src/text/mod.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

import haxe.io.FPHelper;
import similar.algorithms.Algorithms;
import similar.algorithms.Capture;
import similar.algorithms.Compact;
import similar.algorithms.Replace;
import similar.text.TextUtils;
import similar.text.TextUtils.QuickSeqRatio;

/**
 * The top level functions of the crate.
 */
class Similar {

    /**
     * Creates a diff between old and new with the given algorithm capturing the ops.
     *
     * This always uses `Compact` + `Replace` + `Capture` and returns the
     * captured `DiffOp`s.
     */
    public static function captureDiff<T>(alg:Algorithm, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Array<DiffOp> {
        return captureDiffDeadline(alg, old, oldRange, newSeq, newRange, null);
    }

    /** Works like `captureDiff` but with an optional deadline. */
    public static function captureDiffDeadline<T>(alg:Algorithm, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range,
            deadline:Null<Float>):Array<DiffOp> {
        var capture = new Capture();
        var d = new Compact(new Replace(capture), old, newSeq);
        Algorithms.diffDeadline(alg, d, old, oldRange, newSeq, newRange, deadline);
        return capture.intoOps();
    }

    /** Creates a diff between two arrays with the given algorithm capturing the ops. */
    public static function captureDiffSlices<T>(alg:Algorithm, old:Array<T>, newSeq:Array<T>):Array<DiffOp> {
        return captureDiffSlicesDeadline(alg, old, newSeq, null);
    }

    /** Works like `captureDiffSlices` but with an optional deadline. */
    public static function captureDiffSlicesDeadline<T>(alg:Algorithm, old:Array<T>, newSeq:Array<T>, deadline:Null<Float>):Array<DiffOp> {
        return captureDiffDeadline(alg, old, new Range(0, old.length), newSeq, new Range(0, newSeq.length), deadline);
    }

    /**
     * Return a measure of similarity in the range `0..=1` (an `f32` in Rust,
     * rounded to single precision here too).
     *
     * A ratio of `1.0` means the two sequences are a complete match, a ratio
     * of `0.0` would indicate completely distinct sequences.
     */
    public static function getDiffRatio(ops:Array<DiffOp>, oldLen:Int, newLen:Int):Float {
        var matches = 0;
        for (op in ops) {
            if (op.tag() == DiffTag.Equal)
                matches += op.len;
        }
        var len = oldLen + newLen;
        if (len == 0)
            return 1.0;
        return f32(f32(2.0 * matches) / f32(len));
    }

    /** Rounds to the nearest `f32`. */
    public static inline function f32(v:Float):Float {
        return FPHelper.i32ToFloat(FPHelper.floatToI32(v));
    }

    /**
     * Isolate change clusters by eliminating ranges with no changes.
     *
     * This will leave holes behind in long periods of equal ranges so that
     * you can build things like unified diffs.
     */
    public static function groupDiffOps(ops:Array<DiffOp>, n:Int):Array<Array<DiffOp>> {
        if (ops.length == 0)
            return [];

        ops = ops.copy();
        var pendingGroup:Array<DiffOp> = [];
        var rv:Array<Array<DiffOp>> = [];

        var first = ops[0];
        if (first.tag() == DiffTag.Equal) {
            var offset = saturatingSub(first.len, n);
            ops[0] = DiffOp.equal(first.oldIndex + offset, first.newIndex + offset, first.len - offset);
        }

        var last = ops[ops.length - 1];
        if (last.tag() == DiffTag.Equal) {
            ops[ops.length - 1] = DiffOp.equal(last.oldIndex, last.newIndex, last.len - saturatingSub(last.len, n));
        }

        for (op in ops) {
            if (op.tag() == DiffTag.Equal) {
                var len = op.len;
                // End the current group and start a new one whenever
                // there is a large range with no changes.
                if (len > n * 2) {
                    pendingGroup.push(DiffOp.equal(op.oldIndex, op.newIndex, n));
                    rv.push(pendingGroup);
                    var offset = saturatingSub(len, n);
                    pendingGroup = [DiffOp.equal(op.oldIndex + offset, op.newIndex + offset, len - offset)];
                    continue;
                }
            }
            pendingGroup.push(op);
        }

        if (!(pendingGroup.length == 0 || (pendingGroup.length == 1 && pendingGroup[0].tag() == DiffTag.Equal)))
            rv.push(pendingGroup);

        return rv;
    }

    static inline function saturatingSub(a:Int, b:Int):Int {
        return a > b ? a - b : 0;
    }

    /**
     * Use the text differ to find `n` close matches.
     *
     * `cutoff` defines the threshold which needs to be reached for a word to
     * be considered similar. See `TextDiff.ratio` for more information.
     */
    public static function getCloseMatches(word:String, possibilities:Array<String>, n:Int, cutoff:Float):Array<String> {
        // The cutoff is an f32 in Rust.
        cutoff = f32(cutoff);
        var matches:Array<{key:Float, word:String}> = [];
        var seq1 = DiffableStr.tokenizeChars(word);
        var quickRatio = new QuickSeqRatio(seq1);

        for (possibility in possibilities) {
            var seq2 = DiffableStr.tokenizeChars(possibility);

            if (TextUtils.upperSeqRatio(seq1, seq2) < cutoff || quickRatio.calc(seq2) < cutoff)
                continue;

            var diff = TextDiff.fromSlices(seq1, seq2);
            var ratio = diff.ratio();
            if (ratio >= cutoff) {
                // we're putting the word itself in reverse in so that matches with
                // the same ratio are ordered lexicographically.
                // `(ratio * u32::MAX as f32) as u32`: u32::MAX rounds to 2^32 in f32,
                // and the cast saturates.
                var key = Math.ffloor(ratio * 4294967296.0);
                if (key > 4294967295.0)
                    key = 4294967295.0;
                matches.push({key: key, word: possibility});
            }
        }

        // `BinaryHeap::pop` yields the greatest first: highest key, then the
        // lexicographically smallest word.
        matches.sort((a, b) -> {
            if (a.key != b.key)
                return a.key > b.key ? -1 : 1;
            return DiffableStr.compare(a.word, b.word);
        });

        var rv = [];
        for (i in 0...n) {
            if (i < matches.length)
                rv.push(matches[i].word);
            else
                break;
        }
        return rv;
    }

}
