// Ported from similar 2.7.0: src/algorithms/utils.rs (`HashMap` of the values, Haxe specific)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import haxe.ds.IntMap;
import haxe.ds.StringMap;

/**
 * A map keyed by sequence values, standing for the Rust `HashMap` keyed by
 * `Hash + Eq` values: strings and integers are hashed, other values are
 * found by a linear search with `==`.
 */
class ValueMap<V> {

    var strings:StringMap<V> = null;
    var ints:IntMap<V> = null;
    var otherKeys:Array<Dynamic> = null;
    var otherValues:Array<V> = null;

    public function new() {}

    public function exists(key:Dynamic):Bool {
        if (Std.isOfType(key, String))
            return strings != null && strings.exists(key);
        if (Std.isOfType(key, Int))
            return ints != null && ints.exists(key);
        return otherIndex(key) != -1;
    }

    public function get(key:Dynamic):Null<V> {
        if (Std.isOfType(key, String))
            return strings != null ? strings.get(key) : null;
        if (Std.isOfType(key, Int))
            return ints != null ? ints.get(key) : null;
        var i = otherIndex(key);
        return i == -1 ? null : otherValues[i];
    }

    public function set(key:Dynamic, value:V):Void {
        if (Std.isOfType(key, String)) {
            if (strings == null)
                strings = new StringMap();
            strings.set(key, value);
        }
        else if (Std.isOfType(key, Int)) {
            if (ints == null)
                ints = new IntMap();
            ints.set(key, value);
        }
        else {
            var i = otherIndex(key);
            if (i == -1) {
                if (otherKeys == null) {
                    otherKeys = [];
                    otherValues = [];
                }
                otherKeys.push(key);
                otherValues.push(value);
            }
            else {
                otherValues[i] = value;
            }
        }
    }

    function otherIndex(key:Dynamic):Int {
        if (otherKeys == null)
            return -1;
        for (i in 0...otherKeys.length) {
            if (otherKeys[i] == key)
                return i;
        }
        return -1;
    }

}
