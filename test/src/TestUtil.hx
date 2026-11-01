import haxe.io.Bytes;

/**
 * Assertions and helpers shared by the ported tests.
 */
class TestUtil {

    public static var assertions = 0;

    public static function fail(message:String, ?pos:haxe.PosInfos):Void {
        throw new TestFailure(message + ' (' + pos.fileName + ':' + pos.lineNumber + ')');
    }

    static function show(v:Dynamic):String {
        if (v == null)
            return 'null';
        if (Std.isOfType(v, String))
            return haxe.Json.stringify(v);
        if (Std.isOfType(v, Array))
            return '[' + [for (x in (v : Array<Dynamic>)) show(x)].join(', ') + ']';
        return Std.string(v);
    }

    static function same(a:Dynamic, b:Dynamic):Bool {
        if (a == null || b == null)
            return a == null && b == null;
        if (Std.isOfType(a, Array) && Std.isOfType(b, Array)) {
            var aa:Array<Dynamic> = a;
            var bb:Array<Dynamic> = b;
            if (aa.length != bb.length)
                return false;
            for (i in 0...aa.length) {
                if (!same(aa[i], bb[i]))
                    return false;
            }
            return true;
        }
        if (Reflect.isEnumValue(a) && Reflect.isEnumValue(b))
            return Type.enumEq(a, b);
        return a == b;
    }

    /**
     * `assert_eq!(a, b)`.
     */
    public static function eq(a:Dynamic, b:Dynamic, ?message:String, ?pos:haxe.PosInfos):Void {
        assertions++;
        if (!same(a, b))
            fail('expected ' + show(a) + ' == ' + show(b) + (message != null ? ' ' + message : ''), pos);
    }

    /**
     * `assert!(cond)`.
     */
    public static function isTrue(cond:Bool, ?message:String, ?pos:haxe.PosInfos):Void {
        assertions++;
        if (!cond)
            fail('assertion failed' + (message != null ? ': ' + message : ''), pos);
    }

    /** Asserts that `actual` equals the insta snapshot `name`. */
    public static function snapshot(name:String, actual:String, ?pos:haxe.PosInfos):Void {
        assertions++;
        var expected = Resources.snapshot(name);
        actual = StringTools.rtrim(actual);
        if (expected != actual)
            fail('snapshot $name differs:\n--- expected\n$expected\n--- actual\n$actual', pos);
    }

    /** Asserts that `actual` equals an inline insta snapshot (indented like the Rust source). */
    public static function inlineSnapshot(expected:String, actual:String, ?pos:haxe.PosInfos):Void {
        assertions++;
        var lines = expected.split('\n');
        while (lines.length > 0 && StringTools.trim(lines[0]) == '')
            lines.shift();
        while (lines.length > 0 && StringTools.trim(lines[lines.length - 1]) == '')
            lines.pop();
        var indent = 1000;
        for (l in lines) {
            if (StringTools.trim(l) == '')
                continue;
            var n = l.length - StringTools.ltrim(l).length;
            if (n < indent)
                indent = n;
        }
        var body = [for (l in lines) l.length >= indent ? l.substr(indent) : StringTools.trim(l)].join('\n');
        actual = StringTools.rtrim(actual);
        if (body != actual)
            fail('inline snapshot differs:\n--- expected\n$body\n--- actual\n$actual', pos);
    }

}

class TestFailure {

    public final message:String;

    public function new(message:String) {
        this.message = message;
    }

    public function toString():String {
        return message;
    }

}
