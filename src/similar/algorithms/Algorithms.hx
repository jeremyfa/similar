// Ported from similar 2.7.0: src/algorithms/mod.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Algorithm;
import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils.SeqEq;

/**
 * The generic interface of the diff algorithms (`similar::algorithms`).
 */
class Algorithms {

    /**
     * Creates a diff between old and new with the given algorithm.
     *
     * Diffs `old`, between indices `oldRange` and `newSeq` between indices `newRange`.
     */
    public static function diff<T>(alg:Algorithm, d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Void {
        diffDeadline(alg, d, old, oldRange, newSeq, newRange, null);
    }

    /**
     * Creates a diff between old and new with the given algorithm with deadline.
     *
     * Note that not all algorithms behave well if they reach the deadline
     * (LCS for instance produces a very simplistic diff when the deadline is
     * reached in all cases).
     */
    public static function diffDeadline<T>(alg:Algorithm, d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range,
            deadline:Null<Float>):Void {
        switch (alg) {
            case Myers:
                similar.algorithms.Myers.diffDeadline(d, old, oldRange, newSeq, newRange, deadline);
            case Patience:
                similar.algorithms.Patience.diffDeadline(d, old, oldRange, newSeq, newRange, deadline);
            case Lcs:
                similar.algorithms.Lcs.diffDeadline(d, old, oldRange, newSeq, newRange, deadline);
        }
    }

    /** Shortcut for diffing arrays with a specific algorithm. */
    public static function diffSlices<T>(alg:Algorithm, d:DiffHook, old:Array<T>, newSeq:Array<T>):Void {
        diff(alg, d, old, new Range(0, old.length), newSeq, new Range(0, newSeq.length));
    }

    /** Shortcut for diffing arrays with a specific algorithm and a deadline. */
    public static function diffSlicesDeadline<T>(alg:Algorithm, d:DiffHook, old:Array<T>, newSeq:Array<T>, deadline:Null<Float>):Void {
        diffDeadline(alg, d, old, new Range(0, old.length), newSeq, new Range(0, newSeq.length), deadline);
    }

}
