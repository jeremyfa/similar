// Ported from similar 2.7.0: src/algorithms/capture.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.DiffOp;

/**
 * A `DiffHook` that captures all diff operations.
 */
class Capture implements DiffHook {

    var ops_:Array<DiffOp> = [];

    /** Creates a new capture hook. */
    public function new() {}

    /** Converts the capture hook into an array of ops. */
    public function intoOps():Array<DiffOp> {
        return ops_;
    }

    /**
     * Isolate change clusters by eliminating ranges with no changes.
     *
     * This is equivalent to calling `Similar.groupDiffOps` on `intoOps()`.
     */
    public function intoGroupedOps(n:Int):Array<Array<DiffOp>> {
        return Similar.groupDiffOps(intoOps(), n);
    }

    /** Accesses the captured operations. */
    public function ops():Array<DiffOp> {
        return ops_;
    }

    public function equal(oldIndex:Int, newIndex:Int, len:Int):Void {
        ops_.push(DiffOp.equal(oldIndex, newIndex, len));
    }

    public function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void {
        ops_.push(DiffOp.delete(oldIndex, oldLen, newIndex));
    }

    public function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void {
        ops_.push(DiffOp.insert(oldIndex, newIndex, newLen));
    }

    public function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):Void {
        ops_.push(DiffOp.replace(oldIndex, oldLen, newIndex, newLen));
    }

    public function finish():Void {}

}
