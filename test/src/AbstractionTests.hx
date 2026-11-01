import TestUtil.*;
import similar.DiffableStr;

/**
 * Tests of src/text/abstraction.rs (the `str` implementation; the byte
 * slice tests need the `bytes` feature, not ported).
 */
class AbstractionTests {

    public function new() {}

    public function testSplitLines() {
        eq(DiffableStr.tokenizeLines('first\nsecond\rthird\r\nfourth\nlast'), ['first\n', 'second\r', 'third\r\n', 'fourth\n', 'last']);
        eq(DiffableStr.tokenizeLines('\n\n'), ['\n', '\n']);
        eq(DiffableStr.tokenizeLines('\n'), ['\n']);
        isTrue(DiffableStr.tokenizeLines('').length == 0);
    }

    public function testSplitWords() {
        eq(DiffableStr.tokenizeWords('foo    bar baz\n\n  aha'), ['foo', '    ', 'bar', ' ', 'baz', '\n\n  ', 'aha']);
    }

    public function testSplitChars() {
        eq(DiffableStr.tokenizeChars('abcfö❄️'), ['a', 'b', 'c', 'f', 'ö', '❄', '\u{fe0f}']);
    }

    public function testSplitGraphemes() {
        eq(DiffableStr.tokenizeGraphemes('abcfö❄️'), ['a', 'b', 'c', 'f', 'ö', '❄️']);
    }

}
