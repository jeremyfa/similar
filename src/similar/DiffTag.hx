// Ported from similar 2.7.0: src/types.rs (`DiffTag`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * The tag of a diff operation.
 */
enum abstract DiffTag(Int) {

    /** The diff op encodes an equal segment. */
    var Equal = 0;

    /** The diff op encodes a deleted segment. */
    var Delete = 1;

    /** The diff op encodes an inserted segment. */
    var Insert = 2;

    /** The diff op encodes a replaced segment. */
    var Replace = 3;

    /** The variant name (Rust `Debug`). */
    public function name():String {
        return switch (cast this : DiffTag) {
            case Equal: 'Equal';
            case Delete: 'Delete';
            case Insert: 'Insert';
            case Replace: 'Replace';
        }
    }

}
