// Ported from similar 2.7.0: src/udiff.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.udiff;

import haxe.io.Bytes;
import haxe.io.Output;
import similar.Algorithm;
import similar.DiffOp;
import similar.TextDiff;
import similar.iter.ChangesIter;

/**
 * Unified diff formatter.
 *
 * ```haxe
 * var textDiff = TextDiff.fromLines(oldText, newText);
 * trace(textDiff.unifiedDiff().contextRadius(10).header("old_file", "new_file").toString());
 * ```
 */
class UnifiedDiff {

    var diff:TextDiff;

    var contextRadius_:Int = 3;

    var missingNewlineHint_:Bool = true;

    var headerOld:Null<String> = null;

    var headerNew:Null<String> = null;

    function new(diff:TextDiff) {
        this.diff = diff;
    }

    /** Creates a formatter from a text diff object. */
    public static function fromTextDiff(diff:TextDiff):UnifiedDiff {
        return new UnifiedDiff(diff);
    }

    /**
     * Changes the context radius: the number of lines between changes that
     * should be emitted. This defaults to `3`.
     */
    public function contextRadius(n:Int):UnifiedDiff {
        contextRadius_ = n;
        return this;
    }

    /**
     * Sets a header to the diff: `a` and `b` are the file names that are
     * added to the top of the unified file format, accepted verbatim.
     */
    public function header(a:String, b:String):UnifiedDiff {
        headerOld = a;
        headerNew = b;
        return this;
    }

    /**
     * Controls the missing newline hint: by default a special
     * `\ No newline at end of file` marker is added to the output when a
     * file is not terminated with a final newline.
     */
    public function missingNewlineHint(yes:Bool):UnifiedDiff {
        missingNewlineHint_ = yes;
        return this;
    }

    /** Iterates over all hunks as configured. */
    public function iterHunks():Array<UnifiedDiffHunk> {
        var rv = [];
        for (ops in diff.groupedOps(contextRadius_)) {
            if (ops.length == 0)
                continue;
            rv.push(new UnifiedDiffHunk(ops, diff, missingNewlineHint_));
        }
        return rv;
    }

    /** Write the unified diff as bytes to the output stream. */
    public function toWriter(w:Output):Void {
        var bytes = Bytes.ofString(toString());
        w.writeFullBytes(bytes, 0, bytes.length);
    }

    @:allow(similar) function headerOpt(a:Null<String>, b:Null<String>):UnifiedDiff {
        if (a != null && b != null)
            header(a, b);
        return this;
    }

    /** The unified diff (Rust `Display`). */
    public function toString():String {
        var buf = new StringBuf();
        var hasHeader = headerOld != null;
        for (hunk in iterHunks()) {
            if (hasHeader) {
                hasHeader = false;
                buf.add('--- ' + headerOld + '\n');
                buf.add('+++ ' + headerNew + '\n');
            }
            buf.add(hunk.toString());
        }
        return buf.toString();
    }

    /**
     * Quick way to get a unified diff as string.
     *
     * `n` configures `contextRadius` and the header is set when
     * `headerOld` and `headerNew` are not null.
     */
    public static function unifiedDiff(alg:Algorithm, old:String, newText:String, n:Int, ?headerOld:String, ?headerNew:String):String {
        return TextDiff.configure().algorithm(alg).diffLines(old, newText).unifiedDiff().contextRadius(n).headerOpt(headerOld, headerNew).toString();
    }

}

/**
 * Unified diff hunk formatter: `toString()` renders out a single unified
 * diff's hunk.
 */
class UnifiedDiffHunk {

    var diff:TextDiff;

    var ops_:Array<DiffOp>;

    var missingNewlineHint_:Bool;

    /** Creates a new hunk for some operations. */
    public function new(ops:Array<DiffOp>, diff:TextDiff, missingNewlineHint:Bool) {
        this.diff = diff;
        this.ops_ = ops;
        this.missingNewlineHint_ = missingNewlineHint;
    }

    /** Returns the header for the hunk. */
    public function header():UnifiedHunkHeader {
        return new UnifiedHunkHeader(ops_);
    }

    /** Returns all operations in the hunk. */
    public function ops():Array<DiffOp> {
        return ops_;
    }

    /** Returns the value of the `missingNewlineHint` flag. */
    public function missingNewlineHint():Bool {
        return missingNewlineHint_;
    }

    /** Iterates over all changes in a hunk. */
    public function iterChanges():AllChangesIter<String> {
        return new AllChangesIter(diff.oldSlices(), diff.newSlices(), ops());
    }

    /** Write the hunk as bytes to the output stream. */
    public function toWriter(w:Output):Void {
        var bytes = Bytes.ofString(toString());
        w.writeFullBytes(bytes, 0, bytes.length);
    }

    /** The hunk (Rust `Display`). */
    public function toString():String {
        var buf = new StringBuf();
        var idx = 0;
        for (change in iterChanges()) {
            if (idx == 0)
                buf.add(header().toString() + '\n');
            buf.add(change.tag().sign() + change.toStringLossy());
            if (!diff.newlineTerminated())
                buf.add('\n');
            if (diff.newlineTerminated() && change.missingNewline())
                buf.add(missingNewlineHintText(missingNewlineHint_) + '\n');
            idx++;
        }
        return buf.toString();
    }

    static function missingNewlineHintText(hint:Bool):String {
        return hint ? '\n\\ No newline at end of file' : '';
    }

}

/**
 * Unified diff hunk header formatter.
 */
class UnifiedHunkHeader {

    var oldStart:Int;
    var oldEnd:Int;
    var newStart:Int;
    var newEnd:Int;

    /** Creates a hunk header from a (non empty) array of diff ops. */
    public function new(ops:Array<DiffOp>) {
        var first = ops[0];
        var last = ops[ops.length - 1];
        oldStart = first.oldRange().start;
        newStart = first.newRange().start;
        oldEnd = last.oldRange().end;
        newEnd = last.newRange().end;
    }

    static function formatRange(start:Int, end:Int):String {
        var beginning = start + 1;
        var len = end > start ? end - start : 0;
        if (len == 1)
            return '$beginning';
        if (len == 0) {
            // empty ranges begin at line just before the range
            beginning -= 1;
        }
        return '$beginning,$len';
    }

    /** The `@@ -a,b +c,d @@` line (Rust `Display`). */
    public function toString():String {
        return '@@ -' + formatRange(oldStart, oldEnd) + ' +' + formatRange(newStart, newEnd) + ' @@';
    }

}
