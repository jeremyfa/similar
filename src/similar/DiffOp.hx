// Ported from similar 2.7.0: src/types.rs (`DiffOp`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

import similar.algorithms.DiffHook;
import similar.iter.ChangesIter;

/**
 * A captured diff operation (Rust enum `DiffOp`).
 *
 * The Rust variants become the static constructors `DiffOp.equal`,
 * `DiffOp.delete`, `DiffOp.insert` and `DiffOp.replace`; `tag()` tells which
 * one it is. The variant fields are read-only fields: `oldIndex`, `newIndex`,
 * `oldLen` (0 for inserts), `newLen` (0 for deletes) and, for `Equal`, `len`
 * (equal to `oldLen` and `newLen`). Values are immutable: the crate internal
 * mutators return a new op.
 */
class DiffOp {

    final _tag:DiffTag;

    /** The starting index in the old sequence. */
    public final oldIndex:Int;

    /** The starting index in the new sequence. */
    public final newIndex:Int;

    /** The length of the old segment (0 for `Insert`). */
    public final oldLen:Int;

    /** The length of the new segment (0 for `Delete`). */
    public final newLen:Int;

    /** The length of an `Equal` segment. */
    public var len(get, never):Int;

    inline function get_len():Int {
        return _tag == Insert ? newLen : oldLen;
    }

    function new(tag:DiffTag, oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int) {
        _tag = tag;
        this.oldIndex = oldIndex;
        this.oldLen = oldLen;
        this.newIndex = newIndex;
        this.newLen = newLen;
    }

    /** A segment is equal (see `DiffHook.equal`). */
    public static inline function equal(oldIndex:Int, newIndex:Int, len:Int):DiffOp {
        return new DiffOp(DiffTag.Equal, oldIndex, len, newIndex, len);
    }

    /** A segment was deleted (see `DiffHook.delete`). */
    public static inline function delete(oldIndex:Int, oldLen:Int, newIndex:Int):DiffOp {
        return new DiffOp(DiffTag.Delete, oldIndex, oldLen, newIndex, 0);
    }

    /** A segment was inserted (see `DiffHook.insert`). */
    public static inline function insert(oldIndex:Int, newIndex:Int, newLen:Int):DiffOp {
        return new DiffOp(DiffTag.Insert, oldIndex, 0, newIndex, newLen);
    }

    /** A segment was replaced (see `DiffHook.replace`). */
    public static inline function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):DiffOp {
        return new DiffOp(DiffTag.Replace, oldIndex, oldLen, newIndex, newLen);
    }

    /** Returns the tag of the operation. */
    public inline function tag():DiffTag {
        return _tag;
    }

    /** Returns the old range. */
    public inline function oldRange():Range {
        return new Range(oldIndex, oldIndex + oldLen);
    }

    /** Returns the new range. */
    public inline function newRange():Range {
        return new Range(newIndex, newIndex + newLen);
    }

    /**
     * Transform the op into a tuple of diff tag and ranges:
     * `(tag, i1..i2, j1..j2)`.
     */
    public function asTagTuple():DiffTagTuple {
        return {tag: _tag, oldRange: oldRange(), newRange: newRange()};
    }

    /** Apply this operation to a diff hook. */
    public function applyToHook(d:DiffHook):Void {
        switch (_tag) {
            case Equal:
                d.equal(oldIndex, newIndex, oldLen);
            case Delete:
                d.delete(oldIndex, oldLen, newIndex);
            case Insert:
                d.insert(oldIndex, newIndex, newLen);
            case Replace:
                d.replace(oldIndex, oldLen, newIndex, newLen);
        }
    }

    /**
     * Iterates over all changes encoded in the diff op against old and new
     * sequences.
     */
    public function iterChanges<T>(old:Lookup<T>, newSeq:Lookup<T>):ChangesIter<T> {
        return new ChangesIter(old, newSeq, this);
    }

    /**
     * Given a diffop yields the changes it encodes against the given arrays:
     * consecutive changed slices instead of individual changes. Returns one
     * entry, or two for a `Replace` operation.
     */
    public function iterSlices<T>(old:Array<T>, newSeq:Array<T>):Array<TaggedValue<Array<T>>> {
        return switch (_tag) {
            case Equal:
                [{tag: ChangeTag.Equal, value: old.slice(oldIndex, oldIndex + oldLen)}];
            case Insert:
                [{tag: ChangeTag.Insert, value: newSeq.slice(newIndex, newIndex + newLen)}];
            case Delete:
                [{tag: ChangeTag.Delete, value: old.slice(oldIndex, oldIndex + oldLen)}];
            case Replace:
                [
                    {tag: ChangeTag.Delete, value: old.slice(oldIndex, oldIndex + oldLen)},
                    {tag: ChangeTag.Insert, value: newSeq.slice(newIndex, newIndex + newLen)}
                ];
        }
    }

    @:allow(similar) function isEmpty():Bool {
        return oldRange().isEmpty() && newRange().isEmpty();
    }

    @:allow(similar) function shiftLeft(adjust:Int):DiffOp {
        return this.adjust(-adjust, 0);
    }

    @:allow(similar) function shiftRight(adjust:Int):DiffOp {
        return this.adjust(adjust, 0);
    }

    @:allow(similar) function growLeft(adjust:Int):DiffOp {
        return this.adjust(-adjust, adjust);
    }

    @:allow(similar) function growRight(adjust:Int):DiffOp {
        return this.adjust(0, adjust);
    }

    @:allow(similar) function shrinkLeft(adjust:Int):DiffOp {
        return this.adjust(0, -adjust);
    }

    @:allow(similar) function shrinkRight(adjust:Int):DiffOp {
        return this.adjust(adjust, -adjust);
    }

    // The offsets move both indices; the length moves the lengths the
    // variant has (`len` for Equal, both for Replace).
    function adjust(offset:Int, length:Int):DiffOp {
        return new DiffOp(_tag, oldIndex + offset, _tag == Insert ? 0 : oldLen + length, newIndex + offset, _tag == Delete ? 0 : newLen + length);
    }

    public function equals(other:DiffOp):Bool {
        return other != null && other._tag == _tag && other.oldIndex == oldIndex && other.newIndex == newIndex && other.oldLen == oldLen && other.newLen == newLen;
    }

    /** The Rust `Debug` form, on one line. */
    public function toString():String {
        return switch (_tag) {
            case Equal: 'Equal { old_index: $oldIndex, new_index: $newIndex, len: $oldLen }';
            case Delete: 'Delete { old_index: $oldIndex, old_len: $oldLen, new_index: $newIndex }';
            case Insert: 'Insert { old_index: $oldIndex, new_index: $newIndex, new_len: $newLen }';
            case Replace: 'Replace { old_index: $oldIndex, old_len: $oldLen, new_index: $newIndex, new_len: $newLen }';
        }
    }

}

/**
 * The `(DiffTag, Range<usize>, Range<usize>)` tuple of `DiffOp.asTagTuple`.
 */
typedef DiffTagTuple = {

    var tag:DiffTag;

    var oldRange:Range;

    var newRange:Range;

}

/**
 * A `(ChangeTag, value)` tuple.
 */
typedef TaggedValue<T> = {

    var tag:ChangeTag;

    var value:T;

}
