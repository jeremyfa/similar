import similar.Change;
import similar.DiffOp;
import similar.Range;

/**
 * A value printed like Rust's `{:#?}`.
 */
enum DebugValue {
    DStruct(name:String, fields:Array<{name:String, value:DebugValue}>);
    DTuple(items:Array<DebugValue>);
    DList(items:Array<DebugValue>);
    DSome(value:DebugValue);
    DNone;
    DRaw(text:String);
}

/**
 * Rust `Debug` output of the crate's types, to compare with the insta
 * snapshots.
 */
class RustDebug {

    public static function op(op:DiffOp):DebugValue {
        var fields = switch (op.tag()) {
            case Equal: [f('old_index', int(op.oldIndex)), f('new_index', int(op.newIndex)), f('len', int(op.len))];
            case Delete: [f('old_index', int(op.oldIndex)), f('old_len', int(op.oldLen)), f('new_index', int(op.newIndex))];
            case Insert: [f('old_index', int(op.oldIndex)), f('new_index', int(op.newIndex)), f('new_len', int(op.newLen))];
            case Replace: [
                    f('old_index', int(op.oldIndex)),
                    f('old_len', int(op.oldLen)),
                    f('new_index', int(op.newIndex)),
                    f('new_len', int(op.newLen))
                ];
        }
        return DStruct(op.tag().name(), fields);
    }

    public static function ops(ops:Array<DiffOp>):DebugValue {
        return DList([for (o in ops) op(o)]);
    }

    public static function groups(groups:Array<Array<DiffOp>>):DebugValue {
        return DList([for (g in groups) ops(g)]);
    }

    public static function tagTuples(groups:Array<Array<DiffOp>>):DebugValue {
        return DList([
            for (g in groups) DList([
                for (o in g) {
                    var t = o.asTagTuple();
                    DTuple([DRaw(t.tag.name()), range(t.oldRange), range(t.newRange)]);
                }
            ])
        ]);
    }

    public static function change(c:Change<String>):DebugValue {
        return DStruct('Change', [
            f('tag', DRaw(c.tag().name())),
            f('old_index', c.oldIndex() == null ? DNone : DSome(int(c.oldIndex()))),
            f('new_index', c.newIndex() == null ? DNone : DSome(int(c.newIndex()))),
            f('value', str(c.value()))
        ]);
    }

    public static function changes(cs:Array<Change<String>>):DebugValue {
        return DList([for (c in cs) change(c)]);
    }

    public static inline function int(v:Int):DebugValue {
        return DRaw(Std.string(v));
    }

    public static inline function range(r:Range):DebugValue {
        return DRaw(r.toString());
    }

    public static function str(s:String):DebugValue {
        var buf = new StringBuf();
        buf.add('"');
        for (i in 0...s.length) {
            var c = StringTools.fastCodeAt(s, i);
            switch (c) {
                case '"'.code:
                    buf.add('\\"');
                case '\\'.code:
                    buf.add('\\\\');
                case '\n'.code:
                    buf.add('\\n');
                case '\r'.code:
                    buf.add('\\r');
                case '\t'.code:
                    buf.add('\\t');
                default:
                    if (c < 0x20 || c == 0x7F)
                        buf.add('\\u{' + StringTools.hex(c).toLowerCase() + '}');
                    else
                        buf.addChar(c);
            }
        }
        buf.add('"');
        return DRaw(buf.toString());
    }

    static inline function f(name:String, value:DebugValue) {
        return {name: name, value: value};
    }

    /** `{:#?}`. */
    public static function pretty(v:DebugValue, indent:String = ''):String {
        var inner = indent + '    ';
        return switch (v) {
            case DRaw(text): text;
            case DNone: 'None';
            case DSome(value): 'Some(\n' + inner + pretty(value, inner) + ',\n' + indent + ')';
            case DStruct(name, fields):
                if (fields.length == 0) name; else name + ' {\n' + [for (fl in fields) inner + fl.name + ': ' + pretty(fl.value, inner) + ',\n'].join('') + indent + '}';
            case DTuple(items):
                '(\n' + [for (it in items) inner + pretty(it, inner) + ',\n'].join('') + indent + ')';
            case DList(items):
                if (items.length == 0) '[]'; else '[\n' + [for (it in items) inner + pretty(it, inner) + ',\n'].join('') + indent + ']';
        }
    }

    /** `{:?}` of an array of ops. */
    public static function compactOps(ops:Array<DiffOp>):String {
        return '[' + [for (o in ops) o.toString()].join(', ') + ']';
    }

    public static function compactGroups(groups:Array<Array<DiffOp>>):String {
        return '[' + [for (g in groups) compactOps(g)].join(', ') + ']';
    }

}
