// Ported from similar 2.7.0: src/algorithms/hook.rs (`DiffHook`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

/**
 * A trait for reacting to an edit script from the "old" version to the
 * "new" version.
 *
 * Rust returns `Result<(), Self::Error>` from every method: in Haxe a hook
 * aborts the diff by throwing. Extend `DiffHookBase` to get the default
 * implementations of the trait.
 */
interface DiffHook {

    /**
     * Called when lines with indices `oldIndex` (in the old version) and
     * `newIndex` (in the new version) start an section equal in both
     * versions, of length `len`.
     */
    function equal(oldIndex:Int, newIndex:Int, len:Int):Void;

    /**
     * Called when a section of length `oldLen`, starting at `oldIndex`,
     * needs to be deleted from the old version.
     */
    function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void;

    /**
     * Called when a section of the new version, of length `newLen` and
     * starting at `newIndex`, needs to be inserted at position `oldIndex`.
     */
    function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void;

    /**
     * Called when a section of the old version, starting at index `oldIndex`
     * and of length `oldLen`, needs to be replaced with a section of length
     * `newLen`, starting at `newIndex`, of the new version.
     */
    function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):Void;

    /** Always called at the end of the algorithm. */
    function finish():Void;

}
