// Ported from similar 2.7.0: src/types.rs (`Algorithm`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * A diffing algorithm.
 */
enum abstract Algorithm(Int) {

    /** Picks the myers algorithm from `similar.algorithms.Myers`. */
    var Myers = 0;

    /** Picks the patience algorithm from `similar.algorithms.Patience`. */
    var Patience = 1;

    /** Picks the LCS algorithm from `similar.algorithms.Lcs`. */
    var Lcs = 2;

    /** Returns the default algorithm (`Myers`). */
    public static inline function defaultAlgorithm():Algorithm {
        return Myers;
    }

    public function toString():String {
        return switch (cast this : Algorithm) {
            case Myers: 'Myers';
            case Patience: 'Patience';
            case Lcs: 'Lcs';
        }
    }

}
