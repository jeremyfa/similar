// Ported from similar 2.7.0: `std::ops::Range<usize>` as used by the crate
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * A half-open range of indices `start..end` (Rust `Range<usize>`).
 */
class Range {

    public final start:Int;

    public final end:Int;

    public inline function new(start:Int, end:Int) {
        this.start = start;
        this.end = end;
    }

    /** The number of indices in the range (0 when `end <= start`, like Rust's `ExactSizeIterator`). */
    public inline function len():Int {
        return end > start ? end - start : 0;
    }

    /** `!(start < end)`, `is_empty_range` of the crate. */
    public inline function isEmpty():Bool {
        return !(start < end);
    }

    public function equals(other:Range):Bool {
        return other != null && other.start == start && other.end == end;
    }

    /** Rust `Debug` form: `start..end`. */
    public function toString():String {
        return start + '..' + end;
    }

}
