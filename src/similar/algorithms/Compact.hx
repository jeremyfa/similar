// Ported from similar 2.7.0: src/algorithms/compact.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.DiffOp;
import similar.DiffTag;
import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils.SeqEq;
import similar.algorithms.AlgorithmUtils.commonPrefixLenBy;
import similar.algorithms.AlgorithmUtils.commonSuffixLenBy;

/**
 * Performs semantic cleanup operations on a diff (based on the compaction
 * logic from diffy by Brandon Williams).
 *
 * This merges similar ops together but also tries to move hunks up and
 * down the diff with the desire to connect as many hunks as possible.
 * It still needs to be combined with `Replace` to get actual replace diff
 * ops out.
 */
class Compact extends DiffHookBase {

    var d:DiffHook;
    var ops:Array<DiffOp> = [];
    var eq:SeqEq;

    /** Creates a new compact hook wrapping another hook. */
    // Not generic: C# has no generic constructors (Haxe's C# output does not compile)
    public function new(d:DiffHook, old:Lookup<Dynamic>, newSeq:Lookup<Dynamic>) {
        super();
        this.d = d;
        this.eq = (n, o) -> newSeq[n] == old[o];
    }

    /** Creates a compact hook comparing with `eq` instead of lookups. */
    public static function withEq(d:DiffHook, eq:SeqEq):Compact {
        var rv = new Compact(d, new Lookup<Int>(i -> i), new Lookup<Int>(i -> i));
        rv.eq = eq;
        return rv;
    }

    /** Extracts the inner hook. */
    public function intoInner():DiffHook {
        return d;
    }

    /** The wrapped hook (Rust `AsRef`). */
    public function asRef():DiffHook {
        return d;
    }

    override public function equal(oldIndex:Int, newIndex:Int, len:Int):Void {
        ops.push(DiffOp.equal(oldIndex, newIndex, len));
    }

    override public function delete(oldIndex:Int, oldLen:Int, newIndex:Int):Void {
        ops.push(DiffOp.delete(oldIndex, oldLen, newIndex));
    }

    override public function insert(oldIndex:Int, newIndex:Int, newLen:Int):Void {
        ops.push(DiffOp.insert(oldIndex, newIndex, newLen));
    }

    override public function finish():Void {
        cleanupDiffOpsBy(eq, ops);
        for (op in ops)
            op.applyToHook(d);
        d.finish();
    }

    /**
     * Walks through all edits and shifts them up and then down, trying to see
     * if they run into similar edits which can be merged.
     */
    public static function cleanupDiffOps<T>(old:Lookup<T>, newSeq:Lookup<T>, ops:Array<DiffOp>):Void {
        cleanupDiffOpsBy((n, o) -> newSeq[n] == old[o], ops);
    }

    /** `cleanupDiffOps` with a comparison function. */
    public static function cleanupDiffOpsBy(eq:SeqEq, ops:Array<DiffOp>):Void {
        // First attempt to compact all Deletions
        var pointer = 0;
        while (pointer < ops.length) {
            if (ops[pointer].tag() == DiffTag.Delete) {
                pointer = shiftDiffOpsUp(ops, eq, pointer);
                pointer = shiftDiffOpsDown(ops, eq, pointer);
            }
            pointer += 1;
        }

        // Then attempt to compact all Insertions
        var pointer = 0;
        while (pointer < ops.length) {
            if (ops[pointer].tag() == DiffTag.Insert) {
                pointer = shiftDiffOpsUp(ops, eq, pointer);
                pointer = shiftDiffOpsDown(ops, eq, pointer);
            }
            pointer += 1;
        }
    }

    static inline function suffixLenOf(eq:SeqEq, oldRange:Range, newRange:Range):Int {
        return commonSuffixLenBy(eq, oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    static inline function prefixLenOf(eq:SeqEq, oldRange:Range, newRange:Range):Int {
        return commonPrefixLenBy(eq, oldRange.start, oldRange.end, newRange.start, newRange.end);
    }

    static function shiftDiffOpsUp(ops:Array<DiffOp>, eq:SeqEq, pointer:Int):Int {
        while (pointer - 1 >= 0 && pointer - 1 < ops.length) {
            var prevOp = ops[pointer - 1];
            var thisOp = ops[pointer];
            var thisTag = thisOp.tag();
            var prevTag = prevOp.tag();
            if (thisTag == DiffTag.Insert && prevTag == DiffTag.Equal) {
                // Shift Inserts Upwards
                var suffixLen = suffixLenOf(eq, prevOp.oldRange(), thisOp.newRange());
                if (suffixLen > 0) {
                    if (pointer + 1 < ops.length && ops[pointer + 1].tag() == DiffTag.Equal) {
                        ops[pointer + 1] = ops[pointer + 1].growLeft(suffixLen);
                    }
                    else {
                        ops.insert(pointer + 1, DiffOp.equal(prevOp.oldRange().end - suffixLen, thisOp.newRange().end - suffixLen, suffixLen));
                    }
                    ops[pointer] = ops[pointer].shiftLeft(suffixLen);
                    ops[pointer - 1] = ops[pointer - 1].shrinkLeft(suffixLen);

                    if (ops[pointer - 1].isEmpty()) {
                        ops.splice(pointer - 1, 1);
                        pointer -= 1;
                    }
                }
                else if (ops[pointer - 1].isEmpty()) {
                    ops.splice(pointer - 1, 1);
                    pointer -= 1;
                }
                else {
                    // We can't shift upwards anymore
                    break;
                }
            }
            else if (thisTag == DiffTag.Delete && prevTag == DiffTag.Equal) {
                // Shift Deletions Upwards
                // check common suffix for the amount we can shift
                var suffixLen = suffixLenOf(eq, prevOp.oldRange(), thisOp.newRange());
                if (suffixLen != 0) {
                    if (pointer + 1 < ops.length && ops[pointer + 1].tag() == DiffTag.Equal) {
                        ops[pointer + 1] = ops[pointer + 1].growLeft(suffixLen);
                    }
                    else {
                        var oldRange = prevOp.oldRange();
                        ops.insert(pointer + 1, DiffOp.equal(oldRange.end - suffixLen, thisOp.newRange().end - suffixLen, oldRange.len() - suffixLen));
                    }
                    ops[pointer] = ops[pointer].shiftLeft(suffixLen);
                    ops[pointer - 1] = ops[pointer - 1].shrinkLeft(suffixLen);

                    if (ops[pointer - 1].isEmpty()) {
                        ops.splice(pointer - 1, 1);
                        pointer -= 1;
                    }
                }
                else if (ops[pointer - 1].isEmpty()) {
                    ops.splice(pointer - 1, 1);
                    pointer -= 1;
                }
                else {
                    // We can't shift upwards anymore
                    break;
                }
            }
            else if ((thisTag == DiffTag.Insert && prevTag == DiffTag.Delete) || (thisTag == DiffTag.Delete && prevTag == DiffTag.Insert)) {
                // Swap the Delete and Insert
                ops[pointer - 1] = thisOp;
                ops[pointer] = prevOp;
                pointer -= 1;
            }
            else if (thisTag == DiffTag.Insert && prevTag == DiffTag.Insert) {
                // Merge the two ranges
                ops[pointer - 1] = ops[pointer - 1].growRight(thisOp.newRange().len());
                ops.splice(pointer, 1);
                pointer -= 1;
            }
            else if (thisTag == DiffTag.Delete && prevTag == DiffTag.Delete) {
                ops[pointer - 1] = ops[pointer - 1].growRight(thisOp.oldRange().len());
                ops.splice(pointer, 1);
                pointer -= 1;
            }
            else {
                throw 'internal error: entered unreachable code: unexpected tag';
            }
        }
        return pointer;
    }

    static function shiftDiffOpsDown(ops:Array<DiffOp>, eq:SeqEq, pointer:Int):Int {
        while (pointer + 1 < ops.length) {
            var nextOp = ops[pointer + 1];
            var thisOp = ops[pointer];
            var thisTag = thisOp.tag();
            var nextTag = nextOp.tag();
            if (thisTag == DiffTag.Insert && nextTag == DiffTag.Equal) {
                // Shift Inserts Downwards
                var prefixLen = prefixLenOf(eq, nextOp.oldRange(), thisOp.newRange());
                if (prefixLen > 0) {
                    if (pointer - 1 >= 0 && ops[pointer - 1].tag() == DiffTag.Equal) {
                        ops[pointer - 1] = ops[pointer - 1].growRight(prefixLen);
                    }
                    else {
                        ops.insert(pointer, DiffOp.equal(nextOp.oldRange().start, thisOp.newRange().start, prefixLen));
                        pointer += 1;
                    }
                    ops[pointer] = ops[pointer].shiftRight(prefixLen);
                    ops[pointer + 1] = ops[pointer + 1].shrinkRight(prefixLen);

                    if (ops[pointer + 1].isEmpty())
                        ops.splice(pointer + 1, 1);
                }
                else if (ops[pointer + 1].isEmpty()) {
                    ops.splice(pointer + 1, 1);
                }
                else {
                    // We can't shift upwards anymore
                    break;
                }
            }
            else if (thisTag == DiffTag.Delete && nextTag == DiffTag.Equal) {
                // Shift Deletions Downwards
                // check common suffix for the amount we can shift
                var prefixLen = prefixLenOf(eq, nextOp.oldRange(), thisOp.newRange());
                if (prefixLen > 0) {
                    if (pointer - 1 >= 0 && ops[pointer - 1].tag() == DiffTag.Equal) {
                        ops[pointer - 1] = ops[pointer - 1].growRight(prefixLen);
                    }
                    else {
                        ops.insert(pointer, DiffOp.equal(nextOp.oldRange().start, thisOp.newRange().start, prefixLen));
                        pointer += 1;
                    }
                    ops[pointer] = ops[pointer].shiftRight(prefixLen);
                    ops[pointer + 1] = ops[pointer + 1].shrinkRight(prefixLen);

                    if (ops[pointer + 1].isEmpty())
                        ops.splice(pointer + 1, 1);
                }
                else if (ops[pointer + 1].isEmpty()) {
                    ops.splice(pointer + 1, 1);
                }
                else {
                    // We can't shift downwards anymore
                    break;
                }
            }
            else if ((thisTag == DiffTag.Insert && nextTag == DiffTag.Delete) || (thisTag == DiffTag.Delete && nextTag == DiffTag.Insert)) {
                // Swap the Delete and Insert
                ops[pointer] = nextOp;
                ops[pointer + 1] = thisOp;
                pointer += 1;
            }
            else if (thisTag == DiffTag.Insert && nextTag == DiffTag.Insert) {
                // Merge the two ranges
                ops[pointer] = ops[pointer].growRight(nextOp.newRange().len());
                ops.splice(pointer + 1, 1);
            }
            else if (thisTag == DiffTag.Delete && nextTag == DiffTag.Delete) {
                ops[pointer] = ops[pointer].growRight(nextOp.oldRange().len());
                ops.splice(pointer + 1, 1);
            }
            else {
                throw 'internal error: entered unreachable code: unexpected tag';
            }
        }
        return pointer;
    }

}
