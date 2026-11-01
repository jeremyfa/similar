import TestUtil.*;
import similar.Algorithm;
import similar.ChangeTag;
import similar.Similar;

/**
 * Tests of src/common.rs and the doc examples of src/types.rs.
 */
class TypesTests {

    public function new() {}

    public function testNonStringIterChange() {
        var old = [1, 2, 3];
        var newSeq = [1, 2, 4];
        var ops = Similar.captureDiffSlices(Algorithm.Myers, old, newSeq);
        var changes = [for (x in ops) for (c in x.iterChanges(old, newSeq)) ([c.tag(), c.value()] : Array<Dynamic>)];
        eq(changes, [[ChangeTag.Equal, 1], [ChangeTag.Equal, 2], [ChangeTag.Delete, 3], [ChangeTag.Insert, 4]]);
    }

    public function testDocIterChanges() {
        var old = ['foo', 'bar', 'baz'];
        var newSeq = ['foo', 'bar', 'blah'];
        var ops = Similar.captureDiffSlices(Algorithm.Myers, old, newSeq);
        var changes:Array<Array<Dynamic>> = [for (x in ops) for (c in x.iterChanges(old, newSeq)) ([c.tag(), c.value()] : Array<Dynamic>)];
        eq(changes, [
            [ChangeTag.Equal, 'foo'],
            [ChangeTag.Equal, 'bar'],
            [ChangeTag.Delete, 'baz'],
            [ChangeTag.Insert, 'blah']
        ]);
    }

    public function testDocIterSlices() {
        var old = ['foo', 'bar', 'baz'];
        var newSeq = ['foo', 'bar', 'blah'];
        var ops = Similar.captureDiffSlices(Algorithm.Myers, old, newSeq);
        var changes:Array<Array<Dynamic>> = [for (x in ops) for (s in x.iterSlices(old, newSeq)) ([s.tag, s.value] : Array<Dynamic>)];
        eq(changes, [[ChangeTag.Equal, ['foo', 'bar']], [ChangeTag.Delete, ['baz']], [ChangeTag.Insert, ['blah']]]);
    }

    public function testDocCaptureDiffSlices() {
        var a = [1, 2, 3, 4, 5];
        var b = [1, 2, 3, 4, 7];
        var ops = Similar.captureDiffSlices(Algorithm.Myers, a, b);
        eq(RustDebug.compactOps(ops), '[Equal { old_index: 0, new_index: 0, len: 4 }, Replace { old_index: 4, old_len: 1, new_index: 4, new_len: 1 }]');
    }

}
