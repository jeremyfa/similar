// Ported from similar 2.7.0: src/algorithms/utils.rs (`IdentifyDistinct`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Lookup;
import similar.Range;

/**
 * A utility to convert distinct items to unique integers.
 *
 * This can be helpful on larger inputs to speed up the comparisons
 * performed by doing a first pass where the data set gets reduced to
 * (small) integers. The indexes are the same as with the passed source
 * ranges. Rust is generic over the integer type: Haxe uses `Int`.
 */
class IdentifyDistinct {

    var oldOffset:Int;
    var oldVec:Array<Int>;
    var newOffset:Int;
    var newVec:Array<Int>;

    /** Creates an int hasher for two sequences. */
    public function new<T>(old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range) {
        var map = new ValueMap<Int>();
        var oldSeq = [];
        var newSeqIds = [];
        var nextId = 0;

        for (idx in oldRange.start...oldRange.end) {
            var item = old[idx];
            var id = map.get(item);
            if (id == null) {
                id = nextId;
                nextId = nextId + 1;
                map.set(item, id);
            }
            oldSeq.push(id);
        }

        for (idx in newRange.start...newRange.end) {
            var item = newSeq[idx];
            var id = map.get(item);
            if (id == null) {
                id = nextId;
                nextId = nextId + 1;
                map.set(item, id);
            }
            newSeqIds.push(id);
        }

        oldOffset = oldRange.start;
        oldVec = oldSeq;
        newOffset = newRange.start;
        newVec = newSeqIds;
    }

    /** Returns a lookup for the old side. */
    public function oldLookup():Lookup<Int> {
        var vec = oldVec;
        var offset = oldOffset;
        return new Lookup(i -> vec[i - offset]);
    }

    /** Returns a lookup for the new side. */
    public function newLookup():Lookup<Int> {
        var vec = newVec;
        var offset = newOffset;
        return new Lookup(i -> vec[i - offset]);
    }

    /** Convenience method to get back the old range. */
    public function oldRange():Range {
        return new Range(oldOffset, oldOffset + oldVec.length);
    }

    /** Convenience method to get back the new range. */
    public function newRange():Range {
        return new Range(newOffset, newOffset + newVec.length);
    }

}
