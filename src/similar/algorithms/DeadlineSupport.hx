// Ported from similar 2.7.0: src/deadline_support.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

/**
 * Deadlines are absolute times in seconds on the `haxe.Timer.stamp()`
 * clock (Rust `Instant`), durations are in seconds (Rust `Duration`).
 */
class DeadlineSupport {

    /** Checks if a deadline was exceeded. */
    public static function deadlineExceeded(deadline:Null<Float>):Bool {
        if (deadline == null)
            return false;
        return haxe.Timer.stamp() > deadline;
    }

    /** Converts a duration into a deadline. */
    public static function durationToDeadline(add:Float):Null<Float> {
        return haxe.Timer.stamp() + add;
    }

    /** `Instant::now()`. */
    public static inline function now():Float {
        return haxe.Timer.stamp();
    }

}
