// Ported from similar 2.7.0: src/algorithms/hook.rs (`NoFinishHook`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

/**
 * Wrapper `DiffHook` that prevents calls to `DiffHook.finish`.
 */
class NoFinishHook implements DiffHook {

    var d:DiffHook;

    /** Wraps another hook. */
    public function new(d:DiffHook) {
        this.d = d;
    }

    /** Extracts the inner hook. */
    public function intoInner():DiffHook {
        return d;
    }

    public inline function equal(oldIndex:Int, newIndex:Int, len:Int):Void {
        d.equal(oldIndex, newIndex, len);
    }

    public inline function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void {
        d.delete(oldIndex, oldLen, newIndex);
    }

    public inline function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void {
        d.insert(oldIndex, newIndex, newLen);
    }

    public inline function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):Void {
        d.replace(oldIndex, oldLen, newIndex, newLen);
    }

    public function finish():Void {}

}
