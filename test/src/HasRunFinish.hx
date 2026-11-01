import similar.algorithms.DiffHookBase;

/** The `HasRunFinish` hook of the `test_finish_called` tests. */
class HasRunFinish extends DiffHookBase {

    public var ran = false;

    override public function finish():Void {
        ran = true;
    }

}
