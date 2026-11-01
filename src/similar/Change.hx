// Ported from similar 2.7.0: src/types.rs (`Change`) and its text additions
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * Represents the expanded `DiffOp` change.
 *
 * Returned by `DiffOp.iterChanges` and `TextDiff.iterChanges`. The methods
 * of the Rust text additions (`asStr`, `toStringLossy`, `missingNewline`
 * and the `Display` form `toString`) expect a `String` value.
 */
class Change<T> {

    var _tag:ChangeTag;

    var _oldIndex:Null<Int>;

    var _newIndex:Null<Int>;

    var _value:T;

    public function new(tag:ChangeTag, oldIndex:Null<Int>, newIndex:Null<Int>, value:T) {
        _tag = tag;
        _oldIndex = oldIndex;
        _newIndex = newIndex;
        _value = value;
    }

    /** Returns the change tag. */
    public inline function tag():ChangeTag {
        return _tag;
    }

    /** Returns the old index if available. */
    public inline function oldIndex():Null<Int> {
        return _oldIndex;
    }

    /** Returns the new index if available. */
    public inline function newIndex():Null<Int> {
        return _newIndex;
    }

    /** Returns the underlying changed value. */
    public inline function value():T {
        return _value;
    }

    /** Replaces the underlying value (Rust `value_mut`). */
    public inline function setValue(value:T):Void {
        _value = value;
    }

    /** Returns the value as string (always a string in this port). */
    public function asStr():Null<String> {
        return cast _value;
    }

    /** Returns the value as string. */
    public function toStringLossy():String {
        return cast _value;
    }

    /**
     * Returns `true` if this change does not end in a newline and must be
     * followed up by one if line based diffs are used.
     */
    public function missingNewline():Bool {
        return !DiffableStr.endsWithNewline(cast _value);
    }

    /**
     * The value, followed by a newline when it is missing one (Rust `Display`
     * of text changes).
     */
    public function toString():String {
        return toStringLossy() + (missingNewline() ? '\n' : '');
    }

    public function equals(other:Change<T>):Bool {
        return other != null && other._tag == _tag && other._oldIndex == _oldIndex && other._newIndex == _newIndex && other._value == _value;
    }

}
