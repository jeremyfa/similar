import TestUtil.*;
import similar.DiffOp;
import similar.Range;
import similar.algorithms.Capture;
import similar.algorithms.Lcs;
import similar.algorithms.Replace;

/**
 * Tests of src/algorithms/lcs.rs.
 */
class LcsTests {

    public function new() {}

    public function testTable() {
        var old = [2, 3];
        var newSeq = [0, 1, 2];
        var table = @:privateAccess Lcs.makeTable((n, o) -> newSeq[n] == old[o], new Range(0, 2), new Range(0, 3), null);
        eq(table.len(), 3);
        isTrue(table.has(1, 0, 1));
        isTrue(table.has(0, 0, 1));
        isTrue(table.has(2, 0, 1));
    }

    public function testDiff() {
        var a = [0, 1, 2, 3, 4];
        var b = [0, 1, 2, 9, 4];
        var capture = new Capture();
        Lcs.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__lcs__diff', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testContiguous() {
        var a = [0, 1, 2, 3, 4, 4, 4, 5];
        var b = [0, 1, 2, 8, 9, 4, 4, 7];
        var capture = new Capture();
        Lcs.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__lcs__contiguous', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testPat() {
        var a = [0, 1, 3, 4, 5];
        var b = [0, 1, 4, 5, 8, 9];
        var d = new Capture();
        Lcs.diff(d, a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__lcs__pat', RustDebug.pretty(RustDebug.ops(d.ops())));
    }

    public function testSame() {
        var a = [0, 1, 2, 3, 4, 4, 4, 5];
        var b = [0, 1, 2, 3, 4, 4, 4, 5];
        var d = new Capture();
        Lcs.diff(d, a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__lcs__same', RustDebug.pretty(RustDebug.ops(d.ops())));
    }

    public function testFinishCalled() {
        var d = new HasRunFinish();
        var slice = [1, 2];
        var slice2 = [1, 2, 3];
        Lcs.diff(d, slice, new Range(0, slice.length), slice2, new Range(0, slice2.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        Lcs.diff(d, slice, new Range(0, slice.length), slice, new Range(0, slice.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        var empty:Array<Int> = [];
        Lcs.diff(d, empty, new Range(0, 0), empty, new Range(0, 0));
        isTrue(d.ran);
    }

    public function testBadRangeRegression() {
        var d = new Capture();
        Lcs.diff(d, [0], new Range(0, 1), [0, 0], new Range(0, 2));
        var ops = d.intoOps();
        eq(ops.length, 2);
        isTrue(ops[0].equals(DiffOp.equal(0, 0, 1)));
        isTrue(ops[1].equals(DiffOp.insert(1, 1, 1)));
    }

}
