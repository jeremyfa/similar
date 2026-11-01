// Ported from similar 2.7.0: src/algorithms/hook.rs (default methods of `DiffHook`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

/**
 * The default implementations of `DiffHook`: `equal`, `delete`, `insert`
 * and `finish` do nothing, `replace` calls `delete` then `insert`.
 */
class DiffHookBase implements DiffHook {

    public function new() {}

    public function equal(oldIndex:Int, newIndex:Int, len:Int):Void {}

    public function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void {}

    public function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void {}

    public function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):Void {
        delete(oldIndex, oldLen, newIndex);
        insert(oldIndex, newIndex, newLen);
    }

    public function finish():Void {}

}
