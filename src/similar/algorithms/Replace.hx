// Ported from similar 2.7.0: src/algorithms/replace.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

/**
 * A `DiffHook` that combines deletions and insertions to give blocks of
 * maximal length, and replacements when appropriate.
 *
 * It will replace `DiffHook.insert` and `DiffHook.delete` events when
 * possible with `DiffHook.replace` events.
 */
class Replace implements DiffHook {

    var d:DiffHook;

    // The pending (old index, old len, new index) of a deletion, (old index,
    // new index, new len) of an insertion and (old index, new index, len) of
    // an equal run; `has*` stands for Rust's `Option`.
    var hasDel = false;
    var delOldIndex = 0;
    var delOldLen = 0;
    var delNewIndex = 0;

    var hasIns = false;
    var insOldIndex = 0;
    var insNewIndex = 0;
    var insNewLen = 0;

    var hasEq = false;
    var eqOldIndex = 0;
    var eqNewIndex = 0;
    var eqLen = 0;

    /** Creates a new replace hook wrapping another hook. */
    public function new(d:DiffHook) {
        this.d = d;
    }

    /** Extracts the inner hook. */
    public function intoInner():DiffHook {
        return d;
    }

    /** The wrapped hook (Rust `AsRef`). */
    public function asRef():DiffHook {
        return d;
    }

    function flushEq():Void {
        if (hasEq) {
            hasEq = false;
            d.equal(eqOldIndex, eqNewIndex, eqLen);
        }
    }

    function flushDelIns():Void {
        if (hasDel) {
            hasDel = false;
            if (hasIns) {
                hasIns = false;
                d.replace(delOldIndex, delOldLen, insNewIndex, insNewLen);
            }
            else {
                d.delete(delOldIndex, delOldLen, delNewIndex);
            }
        }
        else if (hasIns) {
            hasIns = false;
            d.insert(insOldIndex, insNewIndex, insNewLen);
        }
    }

    public function equal(oldIndex:Int, newIndex:Int, len:Int):Void {
        flushDelIns();
        if (hasEq) {
            eqLen = eqLen + len;
        }
        else {
            hasEq = true;
            eqOldIndex = oldIndex;
            eqNewIndex = newIndex;
            eqLen = len;
        }
    }

    public function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void {
        flushEq();
        if (hasDel) {
            delOldLen = delOldLen + oldLen;
        }
        else {
            hasDel = true;
            delOldIndex = oldIndex;
            delOldLen = oldLen;
            delNewIndex = newIndex;
        }
    }

    public function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void {
        flushEq();
        if (hasIns) {
            insNewLen = newLen + insNewLen;
        }
        else {
            hasIns = true;
            insOldIndex = oldIndex;
            insNewIndex = newIndex;
            insNewLen = newLen;
        }
    }

    public function replace(oldIndex:Int, oldLen:Int, newIndex:Int, newLen:Int):Void {
        flushEq();
        d.replace(oldIndex, oldLen, newIndex, newLen);
    }

    public function finish():Void {
        flushEq();
        flushDelIns();
        d.finish();
    }

}
