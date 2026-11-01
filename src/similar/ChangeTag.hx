// Ported from similar 2.7.0: src/types.rs (`ChangeTag`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * The tag of a change.
 */
enum abstract ChangeTag(Int) {

    /** The change indicates equality (not a change). */
    var Equal = 0;

    /** The change indicates deleted text. */
    var Delete = 1;

    /** The change indicates inserted text. */
    var Insert = 2;

    /** The `Display` form of Rust: `' '`, `'-'` or `'+'`. */
    public function sign():String {
        return switch (cast this : ChangeTag) {
            case Equal: ' ';
            case Delete: '-';
            case Insert: '+';
        }
    }

    /** The variant name (Rust `Debug`). */
    public function name():String {
        return switch (cast this : ChangeTag) {
            case Equal: 'Equal';
            case Delete: 'Delete';
            case Insert: 'Insert';
        }
    }

    @:op(A < B) static function lt(a:ChangeTag, b:ChangeTag):Bool;
    @:op(A > B) static function gt(a:ChangeTag, b:ChangeTag):Bool;

}
