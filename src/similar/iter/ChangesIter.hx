// Ported from similar 2.7.0: src/iter.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.iter;

import similar.Change;
import similar.ChangeTag;
import similar.DiffOp;
import similar.DiffTag;
import similar.Lookup;

/**
 * Iterator for `DiffOp.iterChanges`.
 *
 * `next()` returns the next change, or null at the end. It also works with
 * Haxe `for` loops.
 */
class ChangesIter<T> {

    var old:Lookup<T>;
    var newSeq:Lookup<T>;
    var oldRangeEnd:Int;
    var newRangeEnd:Int;
    var oldIndex:Int;
    var newIndex:Int;
    var oldI:Int;
    var newI:Int;
    var tag:DiffTag;

    public function new(old:Lookup<T>, newSeq:Lookup<T>, op:DiffOp) {
        this.old = old;
        this.newSeq = newSeq;
        var t = op.asTagTuple();
        tag = t.tag;
        oldRangeEnd = t.oldRange.end;
        newRangeEnd = t.newRange.end;
        oldIndex = t.oldRange.start;
        newIndex = t.newRange.start;
        oldI = t.oldRange.start;
        newI = t.newRange.start;
    }

    public function next():Null<Change<T>> {
        switch (tag) {
            case Equal:
                if (oldI < oldRangeEnd) {
                    var value = old[oldI];
                    oldI++;
                    oldIndex++;
                    newIndex++;
                    return new Change(ChangeTag.Equal, oldIndex - 1, newIndex - 1, value);
                }
                return null;
            case Delete:
                if (oldI < oldRangeEnd) {
                    var value = old[oldI];
                    oldI++;
                    oldIndex++;
                    return new Change(ChangeTag.Delete, oldIndex - 1, null, value);
                }
                return null;
            case Insert:
                if (newI < newRangeEnd) {
                    var value = newSeq[newI];
                    newI++;
                    newIndex++;
                    return new Change(ChangeTag.Insert, null, newIndex - 1, value);
                }
                return null;
            case Replace:
                if (oldI < oldRangeEnd) {
                    var value = old[oldI];
                    oldI++;
                    oldIndex++;
                    return new Change(ChangeTag.Delete, oldIndex - 1, null, value);
                }
                else if (newI < newRangeEnd) {
                    var value = newSeq[newI];
                    newI++;
                    newIndex++;
                    return new Change(ChangeTag.Insert, null, newIndex - 1, value);
                }
                return null;
        }
    }

    /** Collects the remaining changes. */
    public function collect():Array<Change<T>> {
        var rv = [];
        while (true) {
            var c = next();
            if (c == null)
                break;
            rv.push(c);
        }
        return rv;
    }

    public inline function iterator():ChangeIterator<T> {
        return new ChangeIterator(next);
    }

}

/**
 * Iterator for `TextDiff.iterAllChanges`.
 */
class AllChangesIter<T> {

    var old:Lookup<T>;
    var newSeq:Lookup<T>;
    var ops:Array<DiffOp>;
    var opIndex:Int = 0;
    var currentIter:Null<ChangesIter<T>> = null;

    public function new(old:Lookup<T>, newSeq:Lookup<T>, ops:Array<DiffOp>) {
        this.old = old;
        this.newSeq = newSeq;
        this.ops = ops;
    }

    public function next():Null<Change<T>> {
        while (true) {
            if (currentIter != null) {
                var rv = currentIter.next();
                if (rv != null)
                    return rv;
                currentIter = null;
            }
            if (opIndex < ops.length) {
                currentIter = new ChangesIter(old, newSeq, ops[opIndex]);
                opIndex++;
            }
            else {
                return null;
            }
        }
    }

    /** Collects the remaining changes. */
    public function collect():Array<Change<T>> {
        var rv = [];
        while (true) {
            var c = next();
            if (c == null)
                break;
            rv.push(c);
        }
        return rv;
    }

    public inline function iterator():ChangeIterator<T> {
        return new ChangeIterator(next);
    }

}

/**
 * Adapts a `next()` returning null at the end to a Haxe iterator.
 */
class ChangeIterator<T> {

    var nextFn:() -> Null<Change<T>>;
    var pending:Null<Change<T>>;

    public inline function new(nextFn:() -> Null<Change<T>>) {
        this.nextFn = nextFn;
        pending = nextFn();
    }

    public inline function hasNext():Bool {
        return pending != null;
    }

    public inline function next():Change<T> {
        var rv = pending;
        pending = nextFn();
        return rv;
    }

}
