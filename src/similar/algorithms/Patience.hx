// Ported from similar 2.7.0: src/algorithms/patience.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils.UniqueItem;
import similar.algorithms.AlgorithmUtils.unique;

/**
 * Patience diff algorithm.
 *
 * - time: `O(N log N + M log M + (N+M)D)`
 * - space: `O(N+M)`
 *
 * Tends to give more human-readable outputs. See [Bram Cohen's blog
 * post](https://bramcohen.livejournal.com/73318.html) describing it.
 *
 * This is based on the patience implementation of [pijul](https://pijul.org/)
 * by Pierre-Étienne Meunier.
 */
class Patience {

    /** Patience diff algorithm: diff `old` between indices `oldRange` and `newSeq` between indices `newRange`. */
    public static function diff<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Void {
        diffDeadline(d, old, oldRange, newSeq, newRange, null);
    }

    /**
     * Patience diff algorithm with deadline.
     *
     * This diff is done with an optional deadline that defines the maximal
     * execution time permitted before it bails and falls back to an approximation.
     */
    public static function diffDeadline<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range, deadline:Null<Float>):Void {
        var oldIndexes = unique(old, oldRange);
        var newIndexes = unique(newSeq, newRange);

        var hook = new Replace(new PatienceHook(d, old, oldRange.start, oldRange.end, oldIndexes, newSeq, newRange.start, newRange.end, newIndexes, deadline));
        Myers.diffDeadlineBy(hook, (n, o) -> newIndexes[n].value() == oldIndexes[o].value(), new Range(0, oldIndexes.length),
            new Range(0, newIndexes.length), deadline);
    }

}

private class PatienceHook<T> extends DiffHookBase {

    var d:DiffHook;
    var old:Lookup<T>;
    var oldCurrent:Int;
    var oldEnd:Int;
    var oldIndexes:Array<UniqueItem<T>>;
    var newSeq:Lookup<T>;
    var newCurrent:Int;
    var newEnd:Int;
    var newIndexes:Array<UniqueItem<T>>;
    var deadline:Null<Float>;

    public function new(d:DiffHook, old:Lookup<T>, oldCurrent:Int, oldEnd:Int, oldIndexes:Array<UniqueItem<T>>, newSeq:Lookup<T>, newCurrent:Int,
            newEnd:Int, newIndexes:Array<UniqueItem<T>>, deadline:Null<Float>) {
        super();
        this.d = d;
        this.old = old;
        this.oldCurrent = oldCurrent;
        this.oldEnd = oldEnd;
        this.oldIndexes = oldIndexes;
        this.newSeq = newSeq;
        this.newCurrent = newCurrent;
        this.newEnd = newEnd;
        this.newIndexes = newIndexes;
        this.deadline = deadline;
    }

    override public function equal(oldIx:Int, newIx:Int, len:Int):Void {
        for (i in 0...len) {
            var o = oldIx + i;
            var n = newIx + i;
            var a0 = oldCurrent;
            var b0 = newCurrent;
            while (oldCurrent < oldIndexes[o].originalIndex() && newCurrent < newIndexes[n].originalIndex()
                && newSeq[newCurrent] == old[oldCurrent]) {
                oldCurrent += 1;
                newCurrent += 1;
            }
            if (oldCurrent > a0)
                d.equal(a0, b0, oldCurrent - a0);
            var noFinishD = new NoFinishHook(d);
            Myers.diffDeadline(noFinishD, old, new Range(oldCurrent, oldIndexes[o].originalIndex()), newSeq,
                new Range(newCurrent, newIndexes[n].originalIndex()), deadline);
            oldCurrent = oldIndexes[o].originalIndex();
            newCurrent = newIndexes[n].originalIndex();
        }
    }

    override public function finish():Void {
        Myers.diffDeadline(d, old, new Range(oldCurrent, oldEnd), newSeq, new Range(newCurrent, newEnd), deadline);
    }

}
