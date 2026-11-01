import TestUtil.*;
import similar.Similar;
import similar.TextDiff;
import similar.TextDiffConfig;

/**
 * Tests of src/text/mod.rs (the serde tests need the `serde` feature, not
 * ported).
 */
class TextTests {

    public function new() {}

    public function testCapturedOps() {
        var diff = TextDiff.fromLines('Hello World\nsome stuff here\nsome more stuff here\n', 'Hello World\nsome amazing stuff here\nsome more stuff here\n');
        snapshot('similar__text__captured_ops', RustDebug.pretty(RustDebug.ops(diff.ops())));
    }

    public function testCapturedWordOps() {
        var diff = TextDiff.fromWords('Hello World\nsome stuff here\nsome more stuff here\n', 'Hello World\nsome amazing stuff here\nsome more stuff here\n');
        var changes = [for (op in diff.ops()) for (c in diff.iterChanges(op)) c];
        snapshot('similar__text__captured_word_ops', RustDebug.pretty(RustDebug.changes(changes)));
    }

    public function testUnifiedDiff() {
        var diff = TextDiff.fromLines('Hello World\nsome stuff here\nsome more stuff here\n', 'Hello World\nsome amazing stuff here\nsome more stuff here\n');
        isTrue(diff.newlineTerminated());
        snapshot('similar__text__unified_diff', diff.unifiedDiff().contextRadius(3).header('old', 'new').toString());
    }

    public function testLineOps() {
        var a = 'Hello World\nsome stuff here\nsome more stuff here\n';
        var b = 'Hello World\nsome amazing stuff here\nsome more stuff here\n';
        var diff = TextDiff.fromLines(a, b);
        isTrue(diff.newlineTerminated());
        var changes = [for (op in diff.ops()) for (c in diff.iterChanges(op)) c];
        snapshot('similar__text__line_ops', RustDebug.pretty(RustDebug.changes(changes)));
    }

    public function testVirtualNewlines() {
        var diff = TextDiff.fromLines('a\nb', 'a\nc\n');
        isTrue(diff.newlineTerminated());
        var changes = [for (op in diff.ops()) for (c in diff.iterChanges(op)) c];
        snapshot('similar__text__virtual_newlines', RustDebug.pretty(RustDebug.changes(changes)));
    }

    public function testCharDiff() {
        var diff = TextDiff.fromChars('Hello World', 'Hallo Welt');
        snapshot('similar__text__char_diff', RustDebug.pretty(RustDebug.ops(diff.ops())));
    }

    public function testRatio() {
        var diff = TextDiff.fromChars('abcd', 'bcde');
        eq(diff.ratio(), 0.75);
        var diff = TextDiff.fromChars('', '');
        eq(diff.ratio(), 1.0);
    }

    public function testGetCloseMatches() {
        var matches = Similar.getCloseMatches('appel', ['ape', 'apple', 'peach', 'puppy'], 3, 0.6);
        eq(matches, ['apple', 'ape']);
        var matches = Similar.getCloseMatches('hulo', ['hi', 'hulu', 'hali', 'hoho', 'amaz', 'zulo', 'blah', 'hopp', 'uulo', 'aulo'], 5, 0.7);
        eq(matches, ['aulo', 'hulu', 'uulo', 'zulo']);
    }

    public function testLifetimesOnIter() {
        var a = '1\n2\n3\n';
        var b = '1\n99\n3\n';
        var changes = TextDiff.fromLines(a, b).iterAllChanges().collect();
        snapshot('similar__text__lifetimes_on_iter', RustDebug.pretty(RustDebug.changes(changes)));
    }

    public function testRegressionIssue37() {
        var config = new TextDiffConfig();
        var diff = config.diffLines('\u{18}\n\n', '\n\n\r');
        var output = diff.unifiedDiff();
        eq(output.contextRadius(0).toString(), '@@ -1 +1,0 @@\n-\u{18}\n@@ -2,0 +2,2 @@\n+\n+\r');
    }

}
