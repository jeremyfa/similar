// Ported from similar 2.7.0: src/algorithms/utils.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Lookup;
import similar.Range;

/**
 * Compares `new[newIndex]` with `old[oldIndex]` (Rust
 * `New::Output: PartialEq<Old::Output>`).
 *
 * Haxe specific: an object with a typed `eq` method rather than a function
 * value, so that hxcpp and C# call it without boxing the indices. A function
 * `(newIndex:Int, oldIndex:Int) -> Bool` converts to it implicitly.
 */
@:forward(eq)
abstract SeqEq(SeqEqBase) from SeqEqBase to SeqEqBase {

    @:from static inline function fromFunction(f:(newIndex:Int, oldIndex:Int) -> Bool):SeqEq {
        return new FunctionSeqEq(f);
    }

}

/** The comparison object behind `SeqEq`. */
abstract class SeqEqBase {

    /** Whether `new[newIndex]` equals `old[oldIndex]`. */
    public abstract function eq(newIndex:Int, oldIndex:Int):Bool;

}

/** A `SeqEq` calling a comparison function. */
class FunctionSeqEq extends SeqEqBase {

    var f:(newIndex:Int, oldIndex:Int) -> Bool;

    public function new(f:(newIndex:Int, oldIndex:Int) -> Bool) {
        this.f = f;
    }

    public function eq(newIndex:Int, oldIndex:Int):Bool {
        return f(newIndex, oldIndex);
    }

}

/**
 * A `SeqEq` comparing the values of two lookups with `==`. Not generic: the
 * lookups return untyped values on every target anyway, and a type parameter
 * would only add casts on C#.
 */
class LookupSeqEq extends SeqEqBase {

    var old:Lookup<Dynamic>;
    var newSeq:Lookup<Dynamic>;

    public function new(old:Lookup<Dynamic>, newSeq:Lookup<Dynamic>) {
        this.old = old;
        this.newSeq = newSeq;
    }

    public function eq(newIndex:Int, oldIndex:Int):Bool {
        return newSeq[newIndex] == old[oldIndex];
    }

}

/** A `SeqEq` comparing the items of two string arrays, without boxing them. */
class StringArraySeqEq extends SeqEqBase {

    var old:Array<String>;
    var newSeq:Array<String>;

    public function new(old:Array<String>, newSeq:Array<String>) {
        this.old = old;
        this.newSeq = newSeq;
    }

    public function eq(newIndex:Int, oldIndex:Int):Bool {
        return newSeq[newIndex] == old[oldIndex];
    }

}

/** A `SeqEq` comparing the items of two int arrays, without boxing them. */
class IntArraySeqEq extends SeqEqBase {

    var old:Array<Int>;
    var newSeq:Array<Int>;

    public function new(old:Array<Int>, newSeq:Array<Int>) {
        this.old = old;
        this.newSeq = newSeq;
    }

    public function eq(newIndex:Int, oldIndex:Int):Bool {
        return newSeq[newIndex] == old[oldIndex];
    }

}

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
        return commonPrefixLenBy(new LookupSeqEq(old, newSeq), oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    /** Given two lookups and ranges calculates the length of common suffix. */
    public static function commonSuffixLen<T>(old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Int {
        return commonSuffixLenBy(new LookupSeqEq(old, newSeq), oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    /** `commonPrefixLen` with a comparison function and plain range bounds. */
    public static function commonPrefixLenBy(eq:SeqEq, oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int):Int {
        if (!(oldStart < oldEnd) || !(newStart < newEnd))
            return 0;
        var count = 0;
        var n = newStart;
        var o = oldStart;
        while (n < newEnd && o < oldEnd && eq.eq(n, o)) {
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
        while (n >= newStart && o >= oldStart && eq.eq(n, o)) {
            n--;
            o--;
            count++;
        }
        return count;
    }

}
