// Ported from similar 2.7.0: src/text/mod.rs (`TextDiffConfig`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

import similar.algorithms.AlgorithmUtils.IntArraySeqEq;
import similar.algorithms.AlgorithmUtils.SeqEq;
import similar.algorithms.AlgorithmUtils.StringArraySeqEq;
import similar.algorithms.DeadlineSupport;
import similar.algorithms.IdentifyDistinct;

/**
 * A builder type config for more complex uses of `TextDiff`.
 *
 * Deadlines are absolute `haxe.Timer.stamp()` times and timeouts are in
 * seconds (Rust `Instant` and `Duration`).
 */
class TextDiffConfig {

    var alg:Algorithm = Algorithm.Myers;

    var nlTerminated:Null<Bool> = null;

    // Rust `Option<Deadline>`: an absolute deadline or a relative timeout.
    var deadlineAbsolute:Null<Float> = null;

    var deadlineRelative:Null<Float> = null;

    public function new() {}

    /** Changes the algorithm. The default algorithm is `Algorithm.Myers`. */
    public function algorithm(alg:Algorithm):TextDiffConfig {
        this.alg = alg;
        return this;
    }

    /**
     * Sets a deadline for the diff operation.
     *
     * By default a diff will take as long as it takes. For certain diff
     * algorithms like Myer's and Patience a maximum running time can be
     * defined after which the algorithm gives up and approximates.
     */
    public function deadline(deadline:Float):TextDiffConfig {
        deadlineAbsolute = deadline;
        deadlineRelative = null;
        return this;
    }

    /** Sets a timeout (in seconds) for the diff operation. */
    public function timeout(timeout:Float):TextDiffConfig {
        deadlineAbsolute = null;
        deadlineRelative = timeout;
        return this;
    }

    /**
     * Changes the newline termination flag.
     *
     * The default is automatic based on input. This flag controls the
     * behavior of `TextDiff.iterChanges` and unified diff generation with
     * regards to newlines.
     */
    public function newlineTerminated(yes:Bool):TextDiffConfig {
        nlTerminated = yes;
        return this;
    }

    /**
     * Creates a diff of lines.
     *
     * This splits the text `old` and `newText` into lines preserving
     * newlines in the input. The `newlineTerminated` flag is flipped to
     * `true` and will influence the behavior of unified diff generation.
     */
    public function diffLines(old:String, newText:String):TextDiff {
        return diff(DiffableStr.tokenizeLines(old), DiffableStr.tokenizeLines(newText), true);
    }

    /** Creates a diff of words: this splits the text into words and whitespace. */
    public function diffWords(old:String, newText:String):TextDiff {
        return diff(DiffableStr.tokenizeWords(old), DiffableStr.tokenizeWords(newText), false);
    }

    /** Creates a diff of characters. */
    public function diffChars(old:String, newText:String):TextDiff {
        return diff(DiffableStr.tokenizeChars(old), DiffableStr.tokenizeChars(newText), false);
    }

    /** Creates a diff of unicode words (according to unicode rules). */
    public function diffUnicodeWords(old:String, newText:String):TextDiff {
        return diff(DiffableStr.tokenizeUnicodeWords(old), DiffableStr.tokenizeUnicodeWords(newText), false);
    }

    /** Creates a diff of graphemes. */
    public function diffGraphemes(old:String, newText:String):TextDiff {
        return diff(DiffableStr.tokenizeGraphemes(old), DiffableStr.tokenizeGraphemes(newText), false);
    }

    /** Creates a diff of arbitrary slices. */
    public function diffSlices(old:Array<String>, newSlices:Array<String>):TextDiff {
        return diff(old, newSlices, false);
    }

    function diff(old:Array<String>, newSlices:Array<String>, newlineTerminated:Bool):TextDiff {
        var deadline = deadlineAbsolute != null ? deadlineAbsolute : (deadlineRelative != null ? DeadlineSupport.durationToDeadline(deadlineRelative) : null);
        var ops = if (old.length > 100 || newSlices.length > 100) {
            var ih = new IdentifyDistinct(old, new Range(0, old.length), newSlices, new Range(0, newSlices.length));
            if (alg == Algorithm.Patience) {
                Similar.captureDiffDeadline(alg, ih.oldLookup(), ih.oldRange(), ih.newLookup(), ih.newRange(), deadline);
            }
            else {
                // Same comparison as the lookups (both ranges start at 0), on the
                // typed id arrays: no id boxed per comparison
                final eq = new IntArraySeqEq(@:privateAccess ih.oldVec, @:privateAccess ih.newVec);
                captureDiffBy(alg, eq, ih.oldRange(), ih.newRange(), deadline);
            }
        }
        else if (alg == Algorithm.Patience) {
            Similar.captureDiffDeadline(alg, old, new Range(0, old.length), newSlices, new Range(0, newSlices.length), deadline);
        }
        else {
            // Same comparison as the lookups, on the typed string arrays: no
            // string boxed per comparison
            captureDiffBy(alg, new StringArraySeqEq(old, newSlices), new Range(0, old.length), new Range(0, newSlices.length), deadline);
        }
        return @:privateAccess new TextDiff(old, newSlices, ops, nlTerminated != null ? nlTerminated : newlineTerminated, alg);
    }

    /**
     * `Similar.captureDiffDeadline` with a typed comparison instead of the
     * lookups, for the algorithms that take one (Myers and LCS). Haxe
     * specific: the lookups go through untyped function values, which box
     * every value they return on hxcpp (and C#).
     */
    static function captureDiffBy(alg:Algorithm, eq:SeqEq, oldRange:Range, newRange:Range,
            deadline:Null<Float>):Array<DiffOp> {
        var capture = new similar.algorithms.Capture();
        var d = similar.algorithms.Compact.withEq(new similar.algorithms.Replace(capture), eq);
        if (alg == Algorithm.Lcs)
            similar.algorithms.Lcs.diffDeadlineBy(d, eq, oldRange, newRange, deadline);
        else
            similar.algorithms.Myers.diffDeadlineBy(d, eq, oldRange, newRange, deadline);
        return capture.intoOps();
    }

}
