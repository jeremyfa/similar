// Ported from similar 2.7.0: src/algorithms/utils.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Lookup;
import similar.Range;

/**
 * Compares `new[newIndex]` with `old[oldIndex]` (Rust
 * `New::Output: PartialEq<Old::Output>`).
 */
typedef SeqEq = (newIndex:Int, oldIndex:Int) -> Bool;

/**
 * Represents an item in the array returned by `AlgorithmUtils.unique`.
 *
 * It compares like the underlying item does it was created from but
 * carries the index it was originally created from.
 */
class UniqueItem<T> {

    var lookup:Lookup<T>;

    var index:Int;

    public function new(lookup:Lookup<T>, index:Int) {
        this.lookup = lookup;
        this.index = index;
    }

    /** Returns the value. */
    public inline function value():T {
        return lookup[index];
    }

    /** Returns the original index. */
    public inline function originalIndex():Int {
        return index;
    }

    /** Compares the values (Rust `PartialEq`). */
    public inline function equals(other:UniqueItem<T>):Bool {
        return value() == other.value();
    }

    /** Rust `Debug` form. */
    public function toString():String {
        return 'UniqueItem { value: ' + Std.string(value()) + ', original_index: ' + index + ' }';
    }

}

/**
 * The utilities of `algorithms/utils.rs`.
 */
class AlgorithmUtils {

    /** Utility function to check if a range is empty. */
    public static inline function isEmptyRange(range:Range):Bool {
        return !(range.start < range.end);
    }

    /**
     * Returns only unique items in the sequence as array.
     *
     * Each item is wrapped in a `UniqueItem` so that both the value and the
     * index can be extracted.
     */
    public static function unique<T>(lookup:Lookup<T>, range:Range):Array<UniqueItem<T>> {
        // Rust stores `Option<usize>`: -1 stands for `None`.
        var byItem = new ValueMap<Int>();
        var order:Array<Int> = [];
        for (index in range.start...range.end) {
            var item = lookup[index];
            var entry = byItem.get(item);
            if (entry == null) {
                byItem.set(item, index);
                order.push(index);
            }
            else if (entry != -1) {
                byItem.set(item, -1);
            }
        }
        var rv = [];
        for (index in order) {
            if (byItem.get(lookup[index]) == index)
                rv.push(new UniqueItem(lookup, index));
        }
        // `order` is already sorted by original index, like the Rust sort.
        return rv;
    }

    /** Given two lookups and ranges calculates the length of the common prefix. */
    public static function commonPrefixLen<T>(old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Int {
        return commonPrefixLenBy((n, o) -> newSeq[n] == old[o], oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    /** Given two lookups and ranges calculates the length of common suffix. */
    public static function commonSuffixLen<T>(old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Int {
        return commonSuffixLenBy((n, o) -> newSeq[n] == old[o], oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    /** `commonPrefixLen` with a comparison function and plain range bounds. */
    public static function commonPrefixLenBy(eq:SeqEq, oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int):Int {
        if (!(oldStart < oldEnd) || !(newStart < newEnd))
            return 0;
        var count = 0;
        var n = newStart;
        var o = oldStart;
        while (n < newEnd && o < oldEnd && eq(n, o)) {
            n++;
            o++;
            count++;
        }
        return count;
    }

    /** `commonSuffixLen` with a comparison function and plain range bounds. */
    public static function commonSuffixLenBy(eq:SeqEq, oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int):Int {
        if (!(oldStart < oldEnd) || !(newStart < newEnd))
            return 0;
        var count = 0;
        var n = newEnd - 1;
        var o = oldEnd - 1;
        while (n >= newStart && o >= oldStart && eq(n, o)) {
            n--;
            o--;
            count++;
        }
        return count;
    }

}
