import TestUtil.*;
import similar.Range;
import similar.algorithms.Capture;
import similar.algorithms.Patience;
import similar.algorithms.Replace;

/**
 * Tests of src/algorithms/patience.rs.
 */
class PatienceTests {

    public function new() {}

    public function testPatience() {
        var a = [11, 1, 2, 2, 3, 4, 4, 4, 5, 47, 19];
        var b = [10, 1, 2, 2, 8, 9, 4, 4, 7, 47, 18];
        var capture = new Capture();
        Patience.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__patience__patience', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testPatienceOutOfBoundsBug() {
        // this used to be a bug
        var a = [1, 2, 3, 4];
        var b = [1, 2, 3];
        var capture = new Capture();
        Patience.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__patience__patience_out_of_bounds_bug', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testFinishCalled() {
        var d = new HasRunFinish();
        var slice = [1, 2];
        var slice2 = [1, 2, 3];
        Patience.diff(d, slice, new Range(0, slice.length), slice2, new Range(0, slice2.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        Patience.diff(d, slice, new Range(0, slice.length), slice, new Range(0, slice.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        var empty:Array<Int> = [];
        Patience.diff(d, empty, new Range(0, 0), empty, new Range(0, 0));
        isTrue(d.ran);
    }

}
