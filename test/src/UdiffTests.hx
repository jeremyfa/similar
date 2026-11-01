import TestUtil.*;
import similar.TextDiff;

/**
 * Tests of src/udiff.rs.
 */
class UdiffTests {

    public function new() {}

    public function testUnifiedDiff() {
        var diff = TextDiff.fromLines('a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\nn\no\np\nq\nr\ns\nt\nu\nv\nw\nx\ny\nz\nA\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\nO\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ',
            'a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl\nm\nn\no\np\nq\nr\nS\nt\nu\nv\nw\nx\ny\nz\nA\nB\nC\nD\nE\nF\nG\nH\nI\nJ\nK\nL\nM\nN\no\nP\nQ\nR\nS\nT\nU\nV\nW\nX\nY\nZ');
        snapshot('similar__udiff__unified_diff', diff.unifiedDiff().header('a.txt', 'b.txt').toString());
    }

    public function testEmptyUnifiedDiff() {
        var diff = TextDiff.fromLines('abc', 'abc');
        eq(diff.unifiedDiff().header('a.txt', 'b.txt').toString(), '');
    }

    public function testUnifiedDiffNewlineHint() {
        var diff = TextDiff.fromLines('a\n', 'b');
        snapshot('similar__udiff__unified_diff_newline_hint', diff.unifiedDiff().header('a.txt', 'b.txt').toString());
        snapshot('similar__udiff__unified_diff_newline_hint-2', diff.unifiedDiff().missingNewlineHint(false).header('a.txt', 'b.txt').toString());
    }

}
