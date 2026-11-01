import TestUtil.*;
import similar.Algorithm;
import similar.ChangeTag;
import similar.Similar;
import similar.TextDiff;
import similar.algorithms.Algorithms;
import similar.algorithms.Capture;
import similar.algorithms.IdentifyDistinct;
import similar.algorithms.Replace;
import similar.utils.Utils;
import similar.utils.Utils.TextDiffRemapper;

/**
 * The doc examples of the crate.
 */
class DocTests {

    public function new() {}

    static function pairs(changes:Iterable<similar.Change<String>>):Array<Array<Dynamic>> {
        return [for (c in changes) ([c.tag(), c.value()] : Array<Dynamic>)];
    }

    static function tagged(items:Array<similar.DiffOp.TaggedValue<Dynamic>>):Array<Array<Dynamic>> {
        return [for (i in items) ([i.tag, i.value] : Array<Dynamic>)];
    }

    // src/lib.rs
    public function testLibTextDiffing() {
        var diff = TextDiff.fromLines('Hello World\nThis is the second line.\nThis is the third.',
            'Hallo Welt\nThis is the second line.\nThis is life.\nMoar and more');
        var out = new StringBuf();
        for (change in diff.iterAllChanges()) {
            var sign = switch (change.tag()) {
                case Delete: '-';
                case Insert: '+';
                case Equal: ' ';
            }
            out.add(sign + change.toString());
        }
        eq(out.toString(),
            '-Hello World\n+Hallo Welt\n This is the second line.\n-This is the third.\n+This is life.\n+Moar and more\n');
    }

    // src/algorithms/mod.rs
    public function testAlgorithmsExample() {
        var a = [1, 2, 3, 4, 5];
        var b = [1, 2, 3, 4, 7];
        var capture = new Capture();
        Algorithms.diffSlices(Algorithm.Myers, new Replace(capture), a, b);
        eq(RustDebug.compactOps(capture.intoOps()), RustDebug.compactOps(Similar.captureDiffSlices(Algorithm.Myers, a, b)));
    }

    // src/algorithms/utils.rs
    public function testIdentifyDistinct() {
        var old = ['foo', 'bar', 'baz'];
        var newSeq = ['foo', 'blah', 'baz'];
        var h = new IdentifyDistinct(old, new similar.Range(0, old.length), newSeq, new similar.Range(0, newSeq.length));
        var ops = Similar.captureDiff(Algorithm.Myers, h.oldLookup(), h.oldRange(), h.newLookup(), h.newRange());
        eq(RustDebug.compactOps(ops), '[Equal { old_index: 0, new_index: 0, len: 1 }, Replace { old_index: 1, old_len: 1, new_index: 1, new_len: 1 }, Equal { old_index: 2, new_index: 2, len: 1 }]');
    }

    // src/text/mod.rs
    public function testConfigDiffLines() {
        var diff = TextDiff.configure().diffLines('a\nb\nc', 'a\nb\nC');
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, 'a\n'],
            [ChangeTag.Equal, 'b\n'],
            [ChangeTag.Delete, 'c'],
            [ChangeTag.Insert, 'C']
        ]);
    }

    public function testConfigDiffWords() {
        var diff = TextDiff.configure().diffWords('foo bar baz', 'foo BAR baz');
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, 'foo'],
            [ChangeTag.Equal, ' '],
            [ChangeTag.Delete, 'bar'],
            [ChangeTag.Insert, 'BAR'],
            [ChangeTag.Equal, ' '],
            [ChangeTag.Equal, 'baz']
        ]);
    }

    public function testConfigDiffChars() {
        var diff = TextDiff.configure().diffChars('abcdef', 'abcDDf');
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, 'a'],
            [ChangeTag.Equal, 'b'],
            [ChangeTag.Equal, 'c'],
            [ChangeTag.Delete, 'd'],
            [ChangeTag.Delete, 'e'],
            [ChangeTag.Insert, 'D'],
            [ChangeTag.Insert, 'D'],
            [ChangeTag.Equal, 'f']
        ]);
    }

    public function testConfigDiffUnicodeWords() {
        var diff = TextDiff.configure().diffUnicodeWords('ah(be)ce', 'ah(ah)ce');
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, 'ah'],
            [ChangeTag.Equal, '('],
            [ChangeTag.Delete, 'be'],
            [ChangeTag.Insert, 'ah'],
            [ChangeTag.Equal, ')'],
            [ChangeTag.Equal, 'ce']
        ]);
    }

    public function testConfigDiffGraphemes() {
        var diff = TextDiff.configure().diffGraphemes('💩🇦🇹🦠', '💩🇦🇱❄️');
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, '💩'],
            [ChangeTag.Delete, '🇦🇹'],
            [ChangeTag.Delete, '🦠'],
            [ChangeTag.Insert, '🇦🇱'],
            [ChangeTag.Insert, '❄️']
        ]);
    }

    public function testConfigDiffSlices() {
        var diff = TextDiff.configure().diffSlices(['foo', 'bar', 'baz'], ['foo', 'BAR', 'baz']);
        eq(pairs(diff.iterAllChanges()), [
            [ChangeTag.Equal, 'foo'],
            [ChangeTag.Delete, 'bar'],
            [ChangeTag.Insert, 'BAR'],
            [ChangeTag.Equal, 'baz']
        ]);
    }

    public function testRatio() {
        eq(TextDiff.fromChars('abcd', 'bcde').ratio(), 0.75);
    }

    public function testGetCloseMatches() {
        eq(Similar.getCloseMatches('appel', ['ape', 'apple', 'peach', 'puppy'], 3, 0.6), ['apple', 'ape']);
    }

    // src/utils.rs
    public function testTextDiffRemapper() {
        var old = 'yo! foo bar baz';
        var newText = 'yo! foo bor baz';
        var diff = TextDiff.fromWords(old, newText);
        var remapper = TextDiffRemapper.fromTextDiff(diff, old, newText);
        var changes = [for (x in diff.ops()) for (s in remapper.iterSlices(x)) ([s.tag, s.value] : Array<Dynamic>)];
        eq(changes, [
            [ChangeTag.Equal, 'yo! foo '],
            [ChangeTag.Delete, 'bar'],
            [ChangeTag.Insert, 'bor'],
            [ChangeTag.Equal, ' baz']
        ]);
    }

    public function testUtilsDiffSlices() {
        var old = ['foo', 'bar', 'baz'];
        var newSeq = ['foo', 'bar', 'BAZ'];
        eq(tagged(cast Utils.diffSlices(Algorithm.Myers, old, newSeq)), [
            [ChangeTag.Equal, ['foo', 'bar']],
            [ChangeTag.Delete, ['baz']],
            [ChangeTag.Insert, ['BAZ']]
        ]);
    }

    public function testUtilsDiffChars() {
        eq(tagged(cast Utils.diffChars(Algorithm.Myers, 'foobarbaz', 'fooBARbaz')), [
            [ChangeTag.Equal, 'foo'],
            [ChangeTag.Delete, 'bar'],
            [ChangeTag.Insert, 'BAR'],
            [ChangeTag.Equal, 'baz']
        ]);
    }

    public function testUtilsDiffWords() {
        eq(tagged(cast Utils.diffWords(Algorithm.Myers, 'foo bar baz', 'foo bor baz')), [
            [ChangeTag.Equal, 'foo '],
            [ChangeTag.Delete, 'bar'],
            [ChangeTag.Insert, 'bor'],
            [ChangeTag.Equal, ' baz']
        ]);
    }

    public function testUtilsDiffUnicodeWords() {
        var old = 'The quick ("brown") fox can\'t jump 32.3 feet, right?';
        var newText = 'The quick ("brown") fox can\'t jump 9.84 meters, right?';
        eq(tagged(cast Utils.diffUnicodeWords(Algorithm.Myers, old, newText)), [
            [ChangeTag.Equal, 'The quick ("brown") fox can\'t jump '],
            [ChangeTag.Delete, '32.3'],
            [ChangeTag.Insert, '9.84'],
            [ChangeTag.Equal, ' '],
            [ChangeTag.Delete, 'feet'],
            [ChangeTag.Insert, 'meters'],
            [ChangeTag.Equal, ', right?']
        ]);
    }

    public function testUtilsDiffGraphemes() {
        var old = 'The flag of Austria is 🇦🇹';
        var newText = 'The flag of Albania is 🇦🇱';
        eq(tagged(cast Utils.diffGraphemes(Algorithm.Myers, old, newText)), [
            [ChangeTag.Equal, 'The flag of A'],
            [ChangeTag.Delete, 'ustr'],
            [ChangeTag.Insert, 'lban'],
            [ChangeTag.Equal, 'ia is '],
            [ChangeTag.Delete, '🇦🇹'],
            [ChangeTag.Insert, '🇦🇱']
        ]);
    }

    public function testUtilsDiffLines() {
        eq(tagged(cast Utils.diffLines(Algorithm.Myers, 'foo\nbar\nbaz\nblah', 'foo\nbar\nbaz\nblurgh')), [
            [ChangeTag.Equal, 'foo\n'],
            [ChangeTag.Equal, 'bar\n'],
            [ChangeTag.Equal, 'baz\n'],
            [ChangeTag.Delete, 'blah'],
            [ChangeTag.Insert, 'blurgh']
        ]);
    }

}
