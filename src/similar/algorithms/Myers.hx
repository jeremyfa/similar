// Ported from similar 2.7.0: src/algorithms/myers.rs
// Original code Copyright (c) Armin Ronacher and contributors, licensed under Apache-2.0.
// Modified: translated from Rust to Haxe. See README.md.

package similar.algorithms;

import similar.Lookup;
import similar.Range;
import similar.algorithms.AlgorithmUtils.SeqEq;
import similar.algorithms.AlgorithmUtils.commonPrefixLenBy;
import similar.algorithms.AlgorithmUtils.commonSuffixLenBy;
import similar.algorithms.DeadlineSupport.deadlineExceeded;

/**
 * Myers' diff algorithm.
 *
 * - time: `O((N+M)D)`
 * - space `O(N+M)`
 *
 * See [the original article by Eugene W. Myers](http://www.xmailserver.org/diff2.pdf)
 * describing it. The implementation of this algorithm is based on the
 * implementation by Brandon Williams.
 */
class Myers {

    /** Myers' diff algorithm: diff `old` between indices `oldRange` and `newSeq` between indices `newRange`. */
    public static function diff<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range):Void {
        diffDeadline(d, old, oldRange, newSeq, newRange, null);
    }

    /**
     * Myers' diff algorithm with deadline.
     *
     * This diff is done with an optional deadline that defines the maximal
     * execution time permitted before it bails and falls back to an approximation.
     */
    public static function diffDeadline<T>(d:DiffHook, old:Lookup<T>, oldRange:Range, newSeq:Lookup<T>, newRange:Range, deadline:Null<Float>):Void {
        diffDeadlineBy(d, (n, o) -> newSeq[n] == old[o], oldRange, newRange, deadline);
    }

    /** `diffDeadline` with a comparison function instead of the lookups. */
    public static function diffDeadlineBy(d:DiffHook, eq:SeqEq, oldRange:Range, newRange:Range, deadline:Null<Float>):Void {
        var maxD = maxD(oldRange.len(), newRange.len());
        var vb = new V(maxD);
        var vf = new V(maxD);
        conquer(d, eq, oldRange.start, oldRange.end, newRange.start, newRange.end, vf, vb, deadline);
        d.finish();
    }

    @:allow(similar) static function maxD(len1:Int, len2:Int):Int {
        // XXX look into reducing the need to have the additional '+ 1'
        return Std.int((len1 + len2 + 1) / 2) + 1;
    }

    /**
     * The divide part of a divide-and-conquer strategy: finds the middle
     * snake of an optimal D-path. Returns the start of the snake as
     * `[x, y]`, or null when the deadline is reached.
     */
    @:allow(similar) static function findMiddleSnake(eq:SeqEq, oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int, vf:V, vb:V, deadline:Null<Float>):Null<Array<Int>> {
        var n = oldEnd > oldStart ? oldEnd - oldStart : 0;
        var m = newEnd > newStart ? newEnd - newStart : 0;

        // By Lemma 1 in the paper, the optimal edit script length is odd or even as
        // `delta` is odd or even.
        var delta = n - m;
        var odd = (delta & 1) == 1;

        // The initial point at (0, -1)
        vf.set(1, 0);
        // The initial point at (N, M+1)
        vb.set(1, 0);

        // We only need to explore ceil(D/2) + 1
        var dMax = maxD(n, m);
        if (!(vf.len() >= dMax))
            throw 'assertion failed: vf.len() >= d_max';
        if (!(vb.len() >= dMax))
            throw 'assertion failed: vb.len() >= d_max';

        for (d in 0...dMax) {
            // are we running for too long?
            if (deadlineExceeded(deadline))
                break;

            // Forward path
            var k = d;
            while (k >= -d) {
                var x = if (k == -d || (k != d && vf.get(k - 1) < vf.get(k + 1))) {
                    vf.get(k + 1);
                }
                else {
                    vf.get(k - 1) + 1;
                }
                var y = x - k;

                // The coordinate of the start of a snake
                var x0 = x;
                var y0 = y;
                // While these sequences are identical, keep moving through the
                // graph with no cost
                if (x < n && y >= 0 && y < m) {
                    var advance = commonPrefixLenBy(eq, oldStart + x, oldEnd, newStart + y, newEnd);
                    x += advance;
                }

                // This is the new best x value
                vf.set(k, x);

                // Only check for connections from the forward search when N - M is
                // odd and when there is a reciprocal k line coming from the other
                // direction.
                if (odd && abs(k - delta) <= (d - 1)) {
                    if (vf.get(k) + vb.get(-(k - delta)) >= n) {
                        // Return the snake
                        return [x0 + oldStart, y0 + newStart];
                    }
                }
                k -= 2;
            }

            // Backward path
            var k = d;
            while (k >= -d) {
                var x = if (k == -d || (k != d && vb.get(k - 1) < vb.get(k + 1))) {
                    vb.get(k + 1);
                }
                else {
                    vb.get(k - 1) + 1;
                }
                var y = x - k;

                // The coordinate of the start of a snake
                if (x < n && y >= 0 && y < m) {
                    var advance = commonSuffixLenBy(eq, oldStart, oldStart + n - x, newStart, newStart + m - y);
                    x += advance;
                    y += advance;
                }

                // This is the new best x value
                vb.set(k, x);

                if (!odd && abs(k - delta) <= d) {
                    if (vb.get(k) + vf.get(-(k - delta)) >= n) {
                        // Return the snake
                        return [n - x + oldStart, m - y + newStart];
                    }
                }
                k -= 2;
            }
        }

        // deadline reached
        return null;
    }

    static inline function abs(v:Int):Int {
        return v < 0 ? -v : v;
    }

    static function conquer(d:DiffHook, eq:SeqEq, oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int, vf:V, vb:V, deadline:Null<Float>):Void {
        // Check for common prefix
        var commonPrefixLen = commonPrefixLenBy(eq, oldStart, oldEnd, newStart, newEnd);
        if (commonPrefixLen > 0)
            d.equal(oldStart, newStart, commonPrefixLen);
        oldStart += commonPrefixLen;
        newStart += commonPrefixLen;

        // Check for common suffix
        var commonSuffixLen = commonSuffixLenBy(eq, oldStart, oldEnd, newStart, newEnd);
        var commonSuffixOld = oldEnd - commonSuffixLen;
        var commonSuffixNew = newEnd - commonSuffixLen;
        oldEnd -= commonSuffixLen;
        newEnd -= commonSuffixLen;

        var oldEmpty = !(oldStart < oldEnd);
        var newEmpty = !(newStart < newEnd);
        if (oldEmpty && newEmpty) {
            // Do nothing
        }
        else if (newEmpty) {
            d.delete(oldStart, oldEnd - oldStart, newStart);
        }
        else if (oldEmpty) {
            d.insert(oldStart, newStart, newEnd - newStart);
        }
        else {
            var snake = findMiddleSnake(eq, oldStart, oldEnd, newStart, newEnd, vf, vb, deadline);
            if (snake != null) {
                var xStart = snake[0];
                var yStart = snake[1];
                conquer(d, eq, oldStart, xStart, newStart, yStart, vf, vb, deadline);
                conquer(d, eq, xStart, oldEnd, yStart, newEnd, vf, vb, deadline);
            }
            else {
                d.delete(oldStart, oldEnd - oldStart, newStart);
                d.insert(oldStart, newStart, newEnd - newStart);
            }
        }

        if (commonSuffixLen > 0)
            d.equal(commonSuffixOld, commonSuffixNew, commonSuffixLen);
    }

}

/**
 * `V` contains the endpoints of the furthest reaching `D-paths`: `V[k]` is
 * the row index of the endpoint of the furthest reaching path in diagonal
 * `k`, stored with an offset since `k` can be negative.
 */
@:allow(similar)
class V {

    var offset:Int;

    var v:Array<Int>;

    public function new(maxD:Int) {
        offset = maxD;
        v = [for (_ in 0...2 * maxD) 0];
    }

    public inline function len():Int {
        return v.length;
    }

    public inline function get(index:Int):Int {
        return v[checked(index + offset)];
    }

    public inline function set(index:Int, value:Int):Void {
        v[checked(index + offset)] = value;
    }

    inline function checked(i:Int):Int {
        if (i < 0 || i >= v.length)
            throw 'index out of bounds: the len is ${v.length} but the index is $i';
        return i;
    }

}
