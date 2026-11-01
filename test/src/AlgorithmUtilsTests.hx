import TestUtil.*;
import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils;
import similar.algorithms.IdentifyDistinct;

/**
 * Tests of src/algorithms/utils.rs.
 */
class AlgorithmUtilsTests {

    public function new() {}

    static function bytes(s:String):Array<Int> {
        var b = haxe.io.Bytes.ofString(s);
        return [for (i in 0...b.length) b.get(i)];
    }

    public function testUnique() {
        var u = [for (x in AlgorithmUtils.unique(['a', 'b', 'c', 'd', 'd', 'b'], new Range(0, 6))) ([x.value(), x.originalIndex()] : Array<Dynamic>)];
        eq(u, [['a', 0], ['c', 2]]);
    }

    public function testIntHasher() {
        var ih = new IdentifyDistinct(['', 'foo', 'bar', 'baz'], new Range(1, 4), ['', 'foo', 'blah', 'baz'], new Range(1, 4));
        eq(ih.oldLookup()[1], 0);
        eq(ih.oldLookup()[2], 1);
        eq(ih.oldLookup()[3], 2);
        eq(ih.newLookup()[1], 0);
        eq(ih.newLookup()[2], 3);
        eq(ih.newLookup()[3], 2);
        isTrue(ih.oldRange().equals(new Range(1, 4)));
        isTrue(ih.newRange().equals(new Range(1, 4)));
    }

    public function testCommonPrefixLen() {
        eq(AlgorithmUtils.commonPrefixLen(bytes(''), new Range(0, 0), bytes(''), new Range(0, 0)), 0);
        eq(AlgorithmUtils.commonPrefixLen(bytes('foobarbaz'), new Range(0, 9), bytes('foobarblah'), new Range(0, 10)), 7);
        eq(AlgorithmUtils.commonPrefixLen(bytes('foobarbaz'), new Range(0, 9), bytes('blablabla'), new Range(0, 9)), 0);
        eq(AlgorithmUtils.commonPrefixLen(bytes('foobarbaz'), new Range(3, 9), bytes('foobarblah'), new Range(3, 10)), 4);
    }

    public function testCommonSuffixLen() {
        eq(AlgorithmUtils.commonSuffixLen(bytes(''), new Range(0, 0), bytes(''), new Range(0, 0)), 0);
        eq(AlgorithmUtils.commonSuffixLen(bytes('1234'), new Range(0, 4), bytes('X0001234'), new Range(0, 8)), 4);
        eq(AlgorithmUtils.commonSuffixLen(bytes('1234'), new Range(0, 4), bytes('Xxxx'), new Range(0, 4)), 0);
        eq(AlgorithmUtils.commonSuffixLen(bytes('1234'), new Range(2, 4), bytes('01234'), new Range(2, 5)), 2);
    }

}
