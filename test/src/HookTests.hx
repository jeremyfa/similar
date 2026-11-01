import TestUtil.*;
import similar.Algorithm;
import similar.algorithms.Algorithms;
import similar.algorithms.Capture;
import similar.algorithms.Replace;

/**
 * Tests of src/algorithms/capture.rs and src/algorithms/replace.rs.
 */
class HookTests {

    public function new() {}

    public function testCaptureHookGrouping() {
        var rng = [for (i in 1...100) i];
        var rngNew = rng.copy();
        rngNew[10] = 1000;
        rngNew[13] = 1000;
        rngNew[16] = 1000;
        rngNew[34] = 1000;

        var capture = new Capture();
        Algorithms.diffSlices(Algorithm.Myers, new Replace(capture), rng, rngNew);

        var ops = capture.intoGroupedOps(3);
        snapshot('similar__algorithms__capture__capture_hook_grouping', RustDebug.pretty(RustDebug.groups(ops)));
        snapshot('similar__algorithms__capture__capture_hook_grouping-2', RustDebug.pretty(RustDebug.tagTuples(ops)));
    }

    public function testMayersReplace() {
        var a = [
            '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n',
            'a\n',
            'b\n',
            'c\n',
            '================================\n',
            'd\n',
            'e\n',
            'f\n',
            '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n',
        ];
        var b = [
            '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n',
            'x\n',
            'b\n',
            'c\n',
            '================================\n',
            'y\n',
            'e\n',
            'f\n',
            '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n',
        ];

        var capture = new Capture();
        Algorithms.diffSlices(Algorithm.Myers, new Replace(capture), a, b);

        inlineSnapshot('
    [
        Equal {
            old_index: 0,
            new_index: 0,
            len: 1,
        },
        Replace {
            old_index: 1,
            old_len: 1,
            new_index: 1,
            new_len: 1,
        },
        Equal {
            old_index: 2,
            new_index: 2,
            len: 3,
        },
        Replace {
            old_index: 5,
            old_len: 1,
            new_index: 5,
            new_len: 1,
        },
        Equal {
            old_index: 6,
            new_index: 6,
            len: 3,
        },
    ]
    ', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

    public function testReplace() {
        var a = [0, 1, 2, 3, 4];
        var b = [0, 1, 2, 7, 8, 9];

        var capture = new Capture();
        Algorithms.diffSlices(Algorithm.Myers, new Replace(capture), a, b);
        inlineSnapshot('
    [
        Equal {
            old_index: 0,
            new_index: 0,
            len: 3,
        },
        Replace {
            old_index: 3,
            old_len: 2,
            new_index: 3,
            new_len: 3,
        },
    ]
    ', RustDebug.pretty(RustDebug.ops(capture.ops())));
    }

}
