import TestUtil.*;
import similar.DiffableStr;
import similar.Range;
import similar.utils.Utils.SliceRemapper;

/**
 * Tests of src/utils.rs.
 */
class UtilsTests {

    public function new() {}

    public function testRemapper() {
        var a = 'foo bar baz';
        var words = DiffableStr.tokenizeWords(a);
        var remap = new SliceRemapper(a, words);
        eq(remap.slice(new Range(0, 3)), 'foo bar');
        eq(remap.slice(new Range(1, 3)), ' bar');
        eq(remap.slice(new Range(0, 1)), 'foo');
        eq(remap.slice(new Range(0, 5)), 'foo bar baz');
        eq(remap.slice(new Range(0, 6)), null);
    }

}
