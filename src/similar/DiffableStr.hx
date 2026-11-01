// Ported from similar 2.7.0: src/text/abstraction.rs (`DiffableStr` for `str`)
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar;

import haxe.io.Bytes;
import unicode_segmentation.UnicodeSegmentation;

/**
 * The text abstraction of the crate, for Haxe strings (Rust `str`).
 *
 * A static extension: `using similar.DiffableStr;`. Lengths and slice
 * ranges are UTF-8 byte offsets like in Rust, on every target. The byte
 * slice implementation (`bytes` feature) is not ported.
 */
class DiffableStr {

    /** Splits the value into newlines with newlines attached. */
    public static function tokenizeLines(s:String):Array<String> {
        var lines = [];
        var lastPos = 0;
        var i = 0;
        var len = s.length;
        while (i < len) {
            var c = StringTools.fastCodeAt(s, i);
            if (c == '\r'.code) {
                if (i + 1 < len && StringTools.fastCodeAt(s, i + 1) == '\n'.code) {
                    lines.push(s.substring(lastPos, i + 2));
                    i++;
                    lastPos = i + 1;
                }
                else {
                    lines.push(s.substring(lastPos, i + 1));
                    lastPos = i + 1;
                }
            }
            else if (c == '\n'.code) {
                lines.push(s.substring(lastPos, i + 1));
                lastPos = i + 1;
            }
            i++;
        }

        if (lastPos < len)
            lines.push(s.substring(lastPos));

        return lines;
    }

    /** Splits the value into newlines with newlines separated. */
    public static function tokenizeLinesAndNewlines(s:String):Array<String> {
        var rv = [];
        var i = 0;
        var len = s.length;
        while (i < len) {
            var c = StringTools.fastCodeAt(s, i);
            var isNewline = c == '\r'.code || c == '\n'.code;
            var start = i;
            i++;
            while (i < len) {
                var next = StringTools.fastCodeAt(s, i);
                if ((next == '\r'.code || next == '\n'.code) != isNewline)
                    break;
                i++;
            }
            rv.push(s.substring(start, i));
        }
        return rv;
    }

    /** Tokenizes into words: runs of whitespace and runs of other characters. */
    public static function tokenizeWords(s:String):Array<String> {
        var rv = [];
        var i = 0;
        var len = s.length;
        while (i < len) {
            var isWs = isWhitespace(codePointAt(s, i));
            var start = i;
            i += codeUnits(s, i);
            while (i < len) {
                if (isWhitespace(codePointAt(s, i)) != isWs)
                    break;
                i += codeUnits(s, i);
            }
            rv.push(s.substring(start, i));
        }
        return rv;
    }

    /** Tokenizes the input into characters (Unicode scalar values). */
    public static function tokenizeChars(s:String):Array<String> {
        var rv = [];
        var i = 0;
        var len = s.length;
        while (i < len) {
            var n = codeUnits(s, i);
            rv.push(s.substr(i, n));
            i += n;
        }
        return rv;
    }

    /** Tokenizes into unicode words (word bounds of UAX #29). */
    public static function tokenizeUnicodeWords(s:String):Array<String> {
        return [for (w in UnicodeSegmentation.splitWordBounds(s)) w];
    }

    /** Tokenizes into unicode graphemes (extended grapheme clusters). */
    public static function tokenizeGraphemes(s:String):Array<String> {
        return [for (g in UnicodeSegmentation.graphemes(s, true)) g];
    }

    /** Returns the value as a string. */
    public static inline function asStr(s:String):Null<String> {
        return s;
    }

    /** Returns the value as a string. */
    public static inline function toStringLossy(s:String):String {
        return s;
    }

    /** Checks if the string ends in a newline (`\r` or `\n`). */
    public static function endsWithNewline(s:String):Bool {
        if (s.length == 0)
            return false;
        var c = StringTools.fastCodeAt(s, s.length - 1);
        return c == '\r'.code || c == '\n'.code;
    }

    /** The length of the string in UTF-8 bytes. */
    public static function len(s:String):Int {
        var rv = 0;
        var i = 0;
        var n = s.length;
        while (i < n) {
            var c = codePointAt(s, i);
            rv += utf8Len(c);
            i += codeUnits(s, i);
        }
        return rv;
    }

    /** Checks if the string is empty. */
    public static inline function isEmpty(s:String):Bool {
        return s.length == 0;
    }

    /** Slices the string by UTF-8 byte offsets (`start..end`). */
    public static function slice(s:String, start:Int, end:Int):String {
        var startUnit = unitIndex(s, start);
        var endUnit = unitIndex(s, end);
        return s.substring(startUnit, endUnit);
    }

    /** Returns the string as UTF-8 bytes. */
    public static inline function asBytes(s:String):Bytes {
        return Bytes.ofString(s);
    }

    /**
     * Compares two strings like Rust's `Ord` for `str` (UTF-8 byte order,
     * which is the code point order). Returns -1, 0 or 1.
     */
    public static function compare(a:String, b:String):Int {
        var i = 0;
        var j = 0;
        while (i < a.length && j < b.length) {
            var ca = codePointAt(a, i);
            var cb = codePointAt(b, j);
            if (ca != cb)
                return ca < cb ? -1 : 1;
            i += codeUnits(a, i);
            j += codeUnits(b, j);
        }
        var restA = i < a.length;
        var restB = j < b.length;
        return restA == restB ? 0 : (restA ? 1 : -1);
    }

    /** Rust `char::is_whitespace` (the Unicode `White_Space` property). */
    public static function isWhitespace(c:Int):Bool {
        return switch (c) {
            case 0x09 | 0x0A | 0x0B | 0x0C | 0x0D | 0x20 | 0x85 | 0xA0 | 0x1680 | 0x2028 | 0x2029 | 0x202F | 0x205F | 0x3000: true;
            default: c >= 0x2000 && c <= 0x200A;
        }
    }

    /** The code point starting at code unit `i`. */
    static function codePointAt(s:String, i:Int):Int {
        var c = StringTools.fastCodeAt(s, i);
        if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.length) {
            var lo = StringTools.fastCodeAt(s, i + 1);
            if (lo >= 0xDC00 && lo <= 0xDFFF)
                return ((c - 0xD800) << 10) + (lo - 0xDC00) + 0x10000;
        }
        return c;
    }

    /** The number of code units of the character starting at code unit `i`. */
    static function codeUnits(s:String, i:Int):Int {
        var c = StringTools.fastCodeAt(s, i);
        if (c >= 0xD800 && c <= 0xDBFF && i + 1 < s.length) {
            var lo = StringTools.fastCodeAt(s, i + 1);
            if (lo >= 0xDC00 && lo <= 0xDFFF)
                return 2;
        }
        return 1;
    }

    static inline function utf8Len(c:Int):Int {
        return c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
    }

    /** The code unit index of the UTF-8 byte offset `byteOffset`. */
    static function unitIndex(s:String, byteOffset:Int):Int {
        var bytes = 0;
        var i = 0;
        var n = s.length;
        while (i < n && bytes < byteOffset) {
            bytes += utf8Len(codePointAt(s, i));
            i += codeUnits(s, i);
        }
        if (bytes != byteOffset)
            throw 'byte index $byteOffset is not a char boundary or is out of bounds';
        return i;
    }

}
