// Ported from similar 2.7.0: src/utils.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.utils;

import similar.Algorithm;
import similar.ChangeTag;
import similar.DiffOp;
import similar.DiffOp.TaggedValue;
import similar.DiffableStr;
import similar.Range;
import similar.Similar;
import similar.TextDiff;

/**
 * Remaps token ranges of a tokenized string back to the original string.
 */
@:allow(similar)
class SliceRemapper {

    var source:String;

    // The byte range of each token: `[start0, end0, start1, end1, ...]`.
    var indexes:Array<Int>;

    public function new(source:String, slices:Array<String>) {
        this.source = source;
        indexes = [];
        var state = 0;
        for (item in slices) {
            var start = state;
            var end = start + DiffableStr.len(item);
            state = end;
            indexes.push(start);
            indexes.push(end);
        }
    }

    /** The source slice covering the tokens of `range`, or null when out of bounds. */
    public function slice(range:Range):Null<String> {
        if (range.start < 0 || range.start * 2 >= indexes.length)
            return null;
        var start = indexes[range.start * 2];
        var last = range.end - 1;
        if (last < 0 || last * 2 >= indexes.length)
            return null;
        var end = indexes[last * 2 + 1];
        return DiffableStr.slice(source, start, end);
    }

}

/**
 * A remapper that can remap diff ops to the original slices.
 *
 * When a `TextDiff` is created from two strings and the internal
 * tokenization is used, this remapper can take a range in the tokenized
 * sequences and remap it to the original string.
 */
class TextDiffRemapper {

    var old:SliceRemapper;

    var newRemapper:SliceRemapper;

    /** Creates a new remapper from strings and slices. */
    public function new(oldSlices:Array<String>, newSlices:Array<String>, old:String, newText:String) {
        this.old = new SliceRemapper(old, oldSlices);
        this.newRemapper = new SliceRemapper(newText, newSlices);
    }

    /** Creates a new remapper from a text diff and the original strings. */
    public static function fromTextDiff(diff:TextDiff, old:String, newText:String):TextDiffRemapper {
        return new TextDiffRemapper(diff.oldSlices(), diff.newSlices(), old, newText);
    }

    /** Slices into the old string. */
    public function sliceOld(range:Range):Null<String> {
        return old.slice(range);
    }

    /** Slices into the new string. */
    public function sliceNew(range:Range):Null<String> {
        return newRemapper.slice(range);
    }

    /**
     * Given a diffop yields the changes it encodes against the original
     * strings. Throws when the strings do not match the diffed ones.
     */
    public function iterSlices(op:DiffOp):Array<TaggedValue<String>> {
        var rv:Array<TaggedValue<String>> = switch (op.tag()) {
            case Equal:
                [{tag: ChangeTag.Equal, value: old.slice(new Range(op.oldIndex, op.oldIndex + op.len))}];
            case Insert:
                [{tag: ChangeTag.Insert, value: newRemapper.slice(new Range(op.newIndex, op.newIndex + op.newLen))}];
            case Delete:
                [{tag: ChangeTag.Delete, value: old.slice(new Range(op.oldIndex, op.oldIndex + op.oldLen))}];
            case Replace:
                [
                    {tag: ChangeTag.Delete, value: old.slice(new Range(op.oldIndex, op.oldIndex + op.oldLen))},
                    {tag: ChangeTag.Insert, value: newRemapper.slice(new Range(op.newIndex, op.newIndex + op.newLen))}
                ];
        }
        for (item in rv) {
            if (item.value == null)
                throw 'slice out of bounds';
        }
        return rv;
    }

}

/**
 * The simple diff functions of `similar::utils`.
 */
class Utils {

    /** Shortcut for diffing two arrays: returns the changed slices. */
    public static function diffSlices<T>(alg:Algorithm, old:Array<T>, newSeq:Array<T>):Array<TaggedValue<Array<T>>> {
        var rv = [];
        for (op in Similar.captureDiffSlices(alg, old, newSeq)) {
            for (item in op.iterSlices(old, newSeq))
                rv.push(item);
        }
        return rv;
    }

    static function remapped(diff:TextDiff, old:String, newText:String):Array<TaggedValue<String>> {
        var remapper = TextDiffRemapper.fromTextDiff(diff, old, newText);
        var rv = [];
        for (op in diff.ops()) {
            for (item in remapper.iterSlices(op))
                rv.push(item);
        }
        return rv;
    }

    /**
     * Shortcut for making a character level diff. It returns connected
     * slices of the original strings rather than character level slices.
     */
    public static function diffChars(alg:Algorithm, old:String, newText:String):Array<TaggedValue<String>> {
        return remapped(TextDiff.configure().algorithm(alg).diffChars(old, newText), old, newText);
    }

    /** Shortcut for making a word level diff (connected slices). */
    public static function diffWords(alg:Algorithm, old:String, newText:String):Array<TaggedValue<String>> {
        return remapped(TextDiff.configure().algorithm(alg).diffWords(old, newText), old, newText);
    }

    /** Shortcut for making a unicode word level diff (connected slices). */
    public static function diffUnicodeWords(alg:Algorithm, old:String, newText:String):Array<TaggedValue<String>> {
        return remapped(TextDiff.configure().algorithm(alg).diffUnicodeWords(old, newText), old, newText);
    }

    /** Shortcut for making a grapheme level diff (connected slices). */
    public static function diffGraphemes(alg:Algorithm, old:String, newText:String):Array<TaggedValue<String>> {
        return remapped(TextDiff.configure().algorithm(alg).diffGraphemes(old, newText), old, newText);
    }

    /**
     * Shortcut for making a line diff. Unlike `diffChars` or `diffSlices` it
     * returns a change tag for each line.
     */
    public static function diffLines(alg:Algorithm, old:String, newText:String):Array<TaggedValue<String>> {
        return [
            for (change in TextDiff.configure().algorithm(alg).diffLines(old, newText).iterAllChanges())
                {tag: change.tag(), value: change.value()}
        ];
    }

}
