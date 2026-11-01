#if macro
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Embeds the upstream insta snapshots (`test/snapshots`) and the reference
 * data (`test/refdata.jsonl`) as resources.
 */
class Resources {

    public static macro function embed() {
        var dir = Context.resolvePath('Main.hx');
        dir = haxe.io.Path.directory(dir) + '/../';
        for (name in FileSystem.readDirectory(dir + 'snapshots')) {
            if (StringTools.endsWith(name, '.snap'))
                Context.addResource('snap:' + name.substr(0, name.length - 5), File.getBytes(dir + 'snapshots/' + name));
        }
        Context.addResource('refdata', File.getBytes(dir + 'refdata.jsonl'));
        return macro null;
    }

    /** The body of an insta snapshot, without its header and trailing newlines. */
    public static function snapshot(name:String):String {
        var s = haxe.Resource.getString('snap:' + name);
        if (s == null)
            throw 'missing snapshot ' + name;
        s = StringTools.replace(s, '\r\n', '\n');
        // Header: `---` ... `---`.
        var first = s.indexOf('---\n');
        var second = s.indexOf('\n---\n', first + 3);
        var body = s.substr(second + 5);
        return StringTools.rtrim(body);
    }

}
