import TestUtil.*;
import similar.Lookup;
import similar.Range;
import similar.algorithms.Capture;
import similar.algorithms.Myers;
import similar.algorithms.Replace;

/**
 * Tests of src/algorithms/myers.rs.
 */
class MyersTests {

    public function new() {}

    static function bytes(s:String):Array<Int> {
        var b = haxe.io.Bytes.ofString(s);
        return [for (i in 0...b.length) b.get(i)];
    }

    public function testFindMiddleSnake() {
        var a = bytes('ABCABBA');
        var b = bytes('CBABAC');
        var maxD = @:privateAccess Myers.maxD(a.length, b.length);
        var vf = new similar.algorithms.Myers.V(maxD);
        var vb = new similar.algorithms.Myers.V(maxD);
        var snake = @:privateAccess Myers.findMiddleSnake((n, o) -> b[n] == a[o], 0, a.length, 0, b.length, vf, vb, null);
        eq(snake[0], 4);
        eq(snake[1], 1);
    }

    public function testDiff() {
        var a = [0, 1, 2, 3, 4];
        var b = [0, 1, 2, 9, 4];
        var capture = new Capture();
        Myers.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__myers__diff', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testContiguous() {
        var a = [0, 1, 2, 3, 4, 4, 4, 5];
        var b = [0, 1, 2, 8, 9, 4, 4, 7];
        var capture = new Capture();
        Myers.diff(new Replace(capture), a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__myers__contiguous', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testPat() {
        var a = [0, 1, 3, 4, 5];
        var b = [0, 1, 4, 5, 8, 9];
        var d = new Capture();
        Myers.diff(d, a, new Range(0, a.length), b, new Range(0, b.length));
        snapshot('similar__algorithms__myers__pat', RustDebug.pretty(RustDebug.ops(d.ops())));
    }

    public function testDeadlineReached() {
        var a = [for (i in 0...100) i];
        var b = [for (i in 0...100) i];
        b[10] = 99;
        b[50] = 99;
        b[25] = 99;

        // Every index access takes a millisecond (Rust sleeps in `SlowIndex`).
        function slow(arr:Array<Int>):Lookup<Int> {
            return new Lookup(i -> {
                var end = haxe.Timer.stamp() + 0.001;
                while (haxe.Timer.stamp() < end) {}
                return arr[i];
            });
        }

        // don't give it enough time to do anything interesting
        var capture = new Capture();
        Myers.diffDeadline(new Replace(capture), slow(a), new Range(0, a.length), slow(b), new Range(0, b.length), haxe.Timer.stamp() + 0.05);
        snapshot('similar__algorithms__myers__deadline_reached', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testFinishCalled() {
        var d = new HasRunFinish();
        var slice = [1, 2];
        var slice2 = [1, 2, 3];
        Myers.diff(d, slice, new Range(0, slice.length), slice2, new Range(0, slice2.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        Myers.diff(d, slice, new Range(0, slice.length), slice, new Range(0, slice.length));
        isTrue(d.ran);

        var d = new HasRunFinish();
        var empty:Array<Int> = [];
        Myers.diff(d, empty, new Range(0, 0), empty, new Range(0, 0));
        isTrue(d.ran);
    }

}
