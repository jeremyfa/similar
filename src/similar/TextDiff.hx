// Ported from similar 2.7.0: src/text/mod.rs (`TextDiff`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

import similar.iter.ChangesIter;
import similar.udiff.UnifiedDiff;

/**
 * Captures diff op codes for textual diffs.
 *
 * Create one with `TextDiff.fromLines` and the other constructors, or with
 * the `TextDiffConfig` returned by `TextDiff.configure()`.
 */
class TextDiff {

    var old:Array<String>;

    var newSlices_:Array<String>;

    var ops_:Array<DiffOp>;

    var nlTerminated:Bool;

    var alg:Algorithm;

    function new(old:Array<String>, newSlices:Array<String>, ops:Array<DiffOp>, newlineTerminated:Bool, algorithm:Algorithm) {
        this.old = old;
        this.newSlices_ = newSlices;
        this.ops_ = ops;
        this.nlTerminated = newlineTerminated;
        this.alg = algorithm;
    }

    /** Configures a text differ before diffing. */
    public static function configure():TextDiffConfig {
        return new TextDiffConfig();
    }

    /** Creates a diff of lines (see `TextDiffConfig.diffLines`). */
    public static function fromLines(old:String, newText:String):TextDiff {
        return configure().diffLines(old, newText);
    }

    /** Creates a diff of words (see `TextDiffConfig.diffWords`). */
    public static function fromWords(old:String, newText:String):TextDiff {
        return configure().diffWords(old, newText);
    }

    /** Creates a diff of chars (see `TextDiffConfig.diffChars`). */
    public static function fromChars(old:String, newText:String):TextDiff {
        return configure().diffChars(old, newText);
    }

    /** Creates a diff of unicode words (see `TextDiffConfig.diffUnicodeWords`). */
    public static function fromUnicodeWords(old:String, newText:String):TextDiff {
        return configure().diffUnicodeWords(old, newText);
    }

    /** Creates a diff of graphemes (see `TextDiffConfig.diffGraphemes`). */
    public static function fromGraphemes(old:String, newText:String):TextDiff {
        return configure().diffGraphemes(old, newText);
    }

    /** Creates a diff of arbitrary slices (see `TextDiffConfig.diffSlices`). */
    public static function fromSlices(old:Array<String>, newSlices:Array<String>):TextDiff {
        return configure().diffSlices(old, newSlices);
    }

    /** The algorithm that created the diff. */
    public function algorithm():Algorithm {
        return alg;
    }

    /**
     * Returns `true` if items in the slice are newline terminated.
     *
     * This flag is used by the unified diff writer to determine if extra
     * newlines have to be added.
     */
    public function newlineTerminated():Bool {
        return nlTerminated;
    }

    /** Returns all old slices. */
    public function oldSlices():Array<String> {
        return old;
    }

    /** Returns all new slices. */
    public function newSlices():Array<String> {
        return newSlices_;
    }

    /**
     * Return a measure of the sequences' similarity in the range `0..=1`.
     *
     * A ratio of `1.0` means the two sequences are a complete match, a ratio
     * of `0.0` would indicate completely distinct sequences.
     */
    public function ratio():Float {
        return Similar.getDiffRatio(ops(), old.length, newSlices_.length);
    }

    /**
     * Iterates over the changes the op expands to, looking up the values from
     * the appropriate slices.
     */
    public function iterChanges(op:DiffOp):ChangesIter<String> {
        return op.iterChanges(old, newSlices_);
    }

    /** Returns the captured diff ops. */
    public function ops():Array<DiffOp> {
        return ops_;
    }

    /**
     * Isolate change clusters by eliminating ranges with no changes.
     *
     * This is equivalent to calling `Similar.groupDiffOps` on `ops()`.
     */
    public function groupedOps(n:Int):Array<Array<DiffOp>> {
        return Similar.groupDiffOps(ops(), n);
    }

    /** Flattens out the diff into all changes. */
    public function iterAllChanges():AllChangesIter<String> {
        return new AllChangesIter(old, newSlices_, ops());
    }

    /** Utility to return a unified diff formatter. */
    public function unifiedDiff():UnifiedDiff {
        return UnifiedDiff.fromTextDiff(this);
    }

}
