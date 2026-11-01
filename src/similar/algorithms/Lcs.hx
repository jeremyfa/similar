// Ported from similar 2.7.0: src/algorithms/lcs.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import haxe.ds.IntMap;
import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils.SeqEq;
import similar.algorithms.AlgorithmUtils.commonPrefixLenBy;
import similar.algorithms.AlgorithmUtils.commonSuffixLenBy;
import similar.algorithms.DeadlineSupport.deadlineExceeded;

/**
 * LCS diff algorithm.
 *
 * - time: `O((NM)D log (M)D)`
 * - space `O(MN)`
 */
class Lcs {

    /** LCS diff algorithm: diff `old` between indices `oldRange` and `newSeq` between indices `newRange`. */
    public static function diff<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Void {
        diffDeadline(d, old, oldRange, newSeq, newRange, null);
    }

    /**
     * LCS diff algorithm with deadline.
     *
     * This diff is done with an optional deadline that defines the maximal
     * execution time permitted before it bails and falls back to an approximation.
     */
    public static function diffDeadline<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range, deadline:Null<Float>):Void {
        diffDeadlineBy(d, (n, o) -> newSeq[n] == old[o], oldRange, newRange, deadline);
    }

    /** `diffDeadline` with a comparison function instead of the lookups. */
    public static function diffDeadlineBy(d:DiffHook, eq:SeqEq, oldRange:Range, newRange:Range, deadline:Null<Float>):Void {
        if (newRange.isEmpty()) {
            d.delete(oldRange.start, oldRange.len(), newRange.start);
            d.finish();
            return;
        }
        else if (oldRange.isEmpty()) {
            d.insert(oldRange.start, newRange.start, newRange.len());
            d.finish();
            return;
        }

        var commonPrefixLen = commonPrefixLenBy(eq, oldRange.start, oldRange.end, newRange.start, newRange.end);
        var commonSuffixLen = commonSuffixLenBy(eq, oldRange.start + commonPrefixLen, oldRange.end, newRange.start + commonPrefixLen, newRange.end);

        // If the sequences are not different then we're done
        if (commonPrefixLen == oldRange.len() && (oldRange.len() == newRange.len())) {
            d.equal(0, 0, oldRange.len());
            d.finish();
            return;
        }

        // Like upstream, the table is built on the relative ranges.
        var maybeTable = makeTable(eq, new Range(commonPrefixLen, oldRange.len() - commonSuffixLen), new Range(commonPrefixLen, newRange.len() - commonSuffixLen),
            deadline);
        var oldIdx = 0;
        var newIdx = 0;
        var newLen = newRange.len() - commonPrefixLen - commonSuffixLen;
        var oldLen = oldRange.len() - commonPrefixLen - commonSuffixLen;

        if (commonPrefixLen > 0)
            d.equal(oldRange.start, newRange.start, commonPrefixLen);

        if (maybeTable != null) {
            var table = maybeTable;
            while (newIdx < newLen && oldIdx < oldLen) {
                var oldOrigIdx = oldRange.start + commonPrefixLen + oldIdx;
                var newOrigIdx = newRange.start + commonPrefixLen + newIdx;

                if (eq(newOrigIdx, oldOrigIdx)) {
                    d.equal(oldOrigIdx, newOrigIdx, 1);
                    oldIdx += 1;
                    newIdx += 1;
                }
                else if (table.get(newIdx, oldIdx + 1) >= table.get(newIdx + 1, oldIdx)) {
                    d.delete(oldOrigIdx, 1, newOrigIdx);
                    oldIdx += 1;
                }
                else {
                    d.insert(oldOrigIdx, newOrigIdx, 1);
                    newIdx += 1;
                }
            }
        }
        else {
            var oldOrigIdx = oldRange.start + commonPrefixLen + oldIdx;
            var newOrigIdx = newRange.start + commonPrefixLen + newIdx;
            d.delete(oldOrigIdx, oldLen, newOrigIdx);
            d.insert(oldOrigIdx, newOrigIdx, newLen);
        }

        if (oldIdx < oldLen) {
            d.delete(oldRange.start + commonPrefixLen + oldIdx, oldLen - oldIdx, newRange.start + commonPrefixLen + newIdx);
            oldIdx += oldLen - oldIdx;
        }

        if (newIdx < newLen)
            d.insert(oldRange.start + commonPrefixLen + oldIdx, newRange.start + commonPrefixLen + newIdx, newLen - newIdx);

        if (commonSuffixLen > 0)
            d.equal(oldRange.start + oldLen + commonPrefixLen, newRange.start + newLen + commonPrefixLen, commonSuffixLen);

        d.finish();
    }

    /**
     * Builds the LCS table (Rust `BTreeMap<(usize, usize), u32>`), or returns
     * null when the deadline is reached.
     */
    @:allow(similar) static function makeTable(eq:SeqEq, oldRange:Range, newRange:Range, deadline:Null<Float>):Null<LcsTable> {
        var oldLen = oldRange.len();
        var newLen = newRange.len();
        var table = new LcsTable(oldLen);

        var i = newLen - 1;
        while (i >= 0) {
            // are we running for too long?  give up on the table
            if (deadlineExceeded(deadline))
                return null;

            var j = oldLen - 1;
            while (j >= 0) {
                var val = if (eq(i, j)) {
                    table.get(i + 1, j + 1) + 1;
                }
                else {
                    var a = table.get(i + 1, j);
                    var b = table.get(i, j + 1);
                    a > b ? a : b;
                }
                if (val > 0)
                    table.insert(i, j, val);
                j--;
            }
            i--;
        }

        return table;
    }

}

/**
 * The sparse LCS table: values keyed by `(new index, old index)`, missing
 * entries read as 0.
 */
class LcsTable {

    var stride:Int;

    var map:IntMap<Int> = new IntMap();

    var count:Int = 0;

    public function new(oldLen:Int) {
        stride = oldLen + 2;
    }

    public inline function get(i:Int, j:Int):Int {
        var v = map.get(i * stride + j);
        return v == null ? 0 : v;
    }

    public function insert(i:Int, j:Int, value:Int):Void {
        var key = i * stride + j;
        if (!map.exists(key))
            count++;
        map.set(key, value);
    }

    /** The number of entries. */
    public function len():Int {
        return count;
    }

    /** Whether the table holds `value` at `(i, j)`. */
    public function has(i:Int, j:Int, value:Int):Bool {
        var v = map.get(i * stride + j);
        return v != null && v == value;
    }

}
