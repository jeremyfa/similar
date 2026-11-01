import TestUtil.*;
import similar.Algorithm;
import similar.DiffableStr;
import similar.Similar;
import similar.TextDiff;
import similar.algorithms.Algorithms;
import similar.algorithms.Capture;
import similar.algorithms.Replace;
import similar.udiff.UnifiedDiff;
import similar.utils.Utils;

/**
 * Validation against the original crate: `test/refdata.jsonl` holds the
 * results of similar 2.7.0 itself (with the `unicode` feature) on generated
 * inputs, written by `tools/refgen`.
 */
class ReferenceTests {

    public function new() {}

    static var cases:Array<Dynamic> = null;

    static function load(kind:String):Array<Dynamic> {
        if (cases == null) {
            cases = [];
            for (line in haxe.Resource.getString('refdata').split('\n')) {
                if (line.length > 0)
                    cases.push(haxe.Json.parse(line));
            }
        }
        return cases.filter(c -> c.kind == kind);
    }

    static function alg(name:String):Algorithm {
        return switch (name) {
            case 'Myers': Algorithm.Myers;
            case 'Patience': Algorithm.Patience;
            default: Algorithm.Lcs;
        }
    }

    static function changes(diff:TextDiff):Array<Array<Dynamic>> {
        return [
            for (c in diff.iterAllChanges())
                ([c.tag().name(), c.oldIndex(), c.newIndex(), c.value()] : Array<Dynamic>)
        ];
    }

    static function tagged(items:Array<similar.DiffOp.TaggedValue<String>>):Array<Array<Dynamic>> {
        return [for (i in items) ([i.tag.name(), i.value] : Array<Dynamic>)];
    }

    /** The `f32` of a Rust `{:?}` float. */
    static function ratio(s:String):Float {
        return Similar.f32(Std.parseFloat(s));
    }

    public function testInts() {
        var all = load('ints');
        isTrue(all.length > 0);
        for (c in all) {
            var old:Array<Int> = c.old;
            var newSeq:Array<Int> = c.newSeq != null ? c.newSeq : Reflect.field(c, 'new');
            var a = alg(c.alg);
            var info = ' (${c.alg} ${old} ${newSeq})';

            var plain = new Capture();
            Algorithms.diffSlices(a, plain, old, newSeq);
            eq(RustDebug.compactOps(plain.ops()), c.plain, 'plain' + info);

            var raw = new Capture();
            Algorithms.diffSlices(a, new Replace(raw), old, newSeq);
            eq(RustDebug.compactOps(raw.ops()), c.raw, 'raw' + info);

            var ops = Similar.captureDiffSlices(a, old, newSeq);
            eq(RustDebug.compactOps(ops), c.ops, 'ops' + info);
            eq(RustDebug.compactGroups(Similar.groupDiffOps(ops, c.n)), c.grouped, 'grouped' + info);
            eq(Similar.getDiffRatio(ops, old.length, newSeq.length), ratio(c.ratio), 'ratio' + info);
        }
    }

    public function testLines() {
        var all = load('lines');
        isTrue(all.length > 0);
        for (c in all) {
            var old:String = c.old;
            var newText:String = Reflect.field(c, 'new');
            var a = alg(c.alg);
            var info = ' (${c.alg} ' + haxe.Json.stringify(old) + ' ' + haxe.Json.stringify(newText) + ')';
            var diff = TextDiff.configure().algorithm(a).diffLines(old, newText);
            eq(RustDebug.compactOps(diff.ops()), c.ops, 'ops' + info);
            eq(changes(diff), c.changes, 'changes' + info);
            var radius:Int = c.radius;
            eq(diff.unifiedDiff().contextRadius(radius).missingNewlineHint(c.hint).header('a/file', 'b/file').toString(), c.udiff, 'udiff' + info);
            eq(TextDiff.configure().algorithm(a).newlineTerminated(false).diffLines(old, newText).unifiedDiff().contextRadius(radius).toString(), c.udiffNt,
                'udiff not terminated' + info);
            eq(UnifiedDiff.unifiedDiff(a, old, newText, radius), c.quick, 'quick' + info);
            eq(diff.ratio(), ratio(c.ratio), 'ratio' + info);
            eq(tagged(Utils.diffLines(a, old, newText)), c.utils, 'utils' + info);
        }
    }

    function checkUnit(kind:String) {
        var all = load(kind);
        isTrue(all.length > 0);
        for (c in all) {
            var old:String = c.old;
            var newText:String = Reflect.field(c, 'new');
            var a = alg(c.alg);
            var info = ' (${c.alg} ' + haxe.Json.stringify(old) + ' ' + haxe.Json.stringify(newText) + ')';
            var config = TextDiff.configure().algorithm(a);
            var diff = switch (kind) {
                case 'words': config.diffWords(old, newText);
                case 'chars': config.diffChars(old, newText);
                case 'unicode_words': config.diffUnicodeWords(old, newText);
                default: config.diffGraphemes(old, newText);
            }
            // Like the original, the remapper throws on some inputs (Lcs on
            // two empty strings): the reference records "panic".
            var utils:Dynamic = try {
                tagged(switch (kind) {
                    case 'words': Utils.diffWords(a, old, newText);
                    case 'chars': Utils.diffChars(a, old, newText);
                    case 'unicode_words': Utils.diffUnicodeWords(a, old, newText);
                    default: Utils.diffGraphemes(a, old, newText);
                });
            }
            catch (e:Dynamic) {
                'panic';
            }
            eq(RustDebug.compactOps(diff.ops()), c.ops, 'ops' + info);
            eq(changes(diff), c.changes, 'changes' + info);
            eq(diff.ratio(), ratio(c.ratio), 'ratio' + info);
            eq(utils, c.utils, 'utils' + info);
            eq(diff.unifiedDiff().contextRadius(1).toString(), c.udiff, 'udiff' + info);
        }
    }

    public function testWords() {
        checkUnit('words');
    }

    public function testChars() {
        checkUnit('chars');
    }

    public function testUnicodeWords() {
        checkUnit('unicode_words');
    }

    public function testGraphemes() {
        checkUnit('graphemes');
    }

    public function testTokens() {
        var all = load('tokens');
        isTrue(all.length > 0);
        for (c in all) {
            var text:String = c.text;
            var info = ' (' + haxe.Json.stringify(text) + ')';
            eq(DiffableStr.tokenizeLines(text), c.lines, 'lines' + info);
            eq(DiffableStr.tokenizeLinesAndNewlines(text), c.linesAndNewlines, 'lines and newlines' + info);
            eq(DiffableStr.tokenizeWords(text), c.words, 'words' + info);
            eq(DiffableStr.tokenizeChars(text), c.chars, 'chars' + info);
            eq(DiffableStr.tokenizeUnicodeWords(text), c.unicodeWords, 'unicode words' + info);
            eq(DiffableStr.tokenizeGraphemes(text), c.graphemes, 'graphemes' + info);
            eq(DiffableStr.len(text), haxe.io.Bytes.ofString(text).length, 'len' + info);
        }
    }

    public function testCloseMatches() {
        var all = load('close');
        isTrue(all.length > 0);
        for (c in all) {
            var possibilities:Array<String> = c.possibilities;
            var info = ' (' + haxe.Json.stringify(c) + ')';
            eq(Similar.getCloseMatches(c.word, possibilities, c.n, c.cutoff), c.matches, 'matches' + info);
        }
    }

}
