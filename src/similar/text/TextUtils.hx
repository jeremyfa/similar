// Ported from similar 2.7.0: src/text/utils.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.text;

import similar.Similar.f32;
import similar.algorithms.ValueMap;

/**
 * The internal utilities of `text/utils.rs`.
 */
class TextUtils {

    /** Quick and dirty way to get an upper sequence ratio. */
    public static function upperSeqRatio<T>(seq1:Array<T>, seq2:Array<T>):Float {
        var n = seq1.length + seq2.length;
        if (n == 0)
            return 1.0;
        var min = seq1.length < seq2.length ? seq1.length : seq2.length;
        return f32(f32(2.0 * min) / f32(n));
    }

}

/**
 * Internal utility to calculate an upper bound for a ratio for
 * `Similar.getCloseMatches`. This is based on Python's difflib approach of
 * considering the two sets to be multisets.
 *
 * It counts the number of matches without regard to order, which is an
 * obvious upper bound.
 */
class QuickSeqRatio {

    var counts:ValueMap<Int> = new ValueMap();

    var countsLen:Int = 0;

    public function new(seq:Array<String>) {
        for (word in seq) {
            var c = counts.get(word);
            if (c == null) {
                countsLen++;
                c = 0;
            }
            counts.set(word, c + 1);
        }
    }

    public function calc(seq:Array<String>):Float {
        var n = countsLen + seq.length;
        if (n == 0)
            return 1.0;

        var available = new ValueMap<Int>();
        var matches = 0;
        for (word in seq) {
            var x = available.get(word);
            if (x == null) {
                var c = counts.get(word);
                x = c == null ? 0 : c;
            }
            available.set(word, x - 1);
            if (x > 0)
                matches += 1;
        }

        return f32(f32(2.0 * matches) / f32(n));
    }

}
