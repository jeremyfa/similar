// Ported from similar 2.7.0: the `Index<usize>` bound of the crate's generic functions
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

/**
 * An indexable sequence (Rust `Index<usize>`): an `Array<T>` (converted
 * implicitly) or any function from an index to a value.
 *
 * Values are compared with Haxe `==`. Where the crate hashes them (the
 * patience algorithm, `IdentifyDistinct`), strings and integers are hashed
 * and other values are compared with `==` (see `similar.algorithms.ValueMap`).
 */
@:callable
abstract Lookup<T>((Int) -> T) from (Int) -> T to (Int) -> T {

    public inline function new(get:(Int) -> T) {
        this = get;
    }

    @:from public static inline function fromArray<T>(array:Array<T>):Lookup<T> {
        return new Lookup(i -> array[i]);
    }

    @:arrayAccess public inline function get(index:Int):T {
        return this(index);
    }

}
