/**
 * Created with IntelliJ IDEA.
 * User: William
 * Date: 18/03/13
 * Time: 09:41
 * To change this template use File | Settings | File Templates.
 */
package utils.toollib {

public final class Bezier {

    //==================================
    //     Generating Methods
    //==================================
    public static function generate(points:*, segments:int = 100):Vector.<Object> {
        var curve:Vector.<Object> = new Vector.<Object>();
        var t:Number = 0, step:Number = 1 / segments;

        switch (points.length) {
            case 0:     return curve;
            case 1:     curve.push(points[0]); return curve;
            case 2:     for (t = 0; t <= 1; t+=step) { curve.push(equationLinear(points[0],points[1], t)); } break;
            case 3:     for (t = 0; t <= 1; t+=step) { curve.push(equationQuadratic(points[0],points[1], points[2], t)); } break;
            case 4:     for (t = 0; t <= 1; t+=step) { curve.push(equationCubic(points[0],points[1],points[2],points[3], t)); } break;
            default:    for (t = 0; t <= 1; t+=step) { curve.push(equationN(points, t)); } break;
        }
        return curve;
    }

    public static function generate_interpolated(points:*, segments:int = 100, K:Number = 1):Vector.<Object> {
        var iPoints:Vector.<Object> = interpolatePoints(points, K);
        var curve:Vector.<Object> = new Vector.<Object>();
        var nArcs:int = points.length - 1;
        var step:Number = nArcs / segments;
        for (var arc:int = 0; arc < nArcs; arc++) {
            var i0:int = 3*arc,
                i1:int = i0 + 1,
                i2:int = i0 + 2,
                i3:int = i0 + 3;
            for (var t:Number = 0; t <= 1; t+=step) {
                curve.push(equationCubic(iPoints[i0],iPoints[i1], iPoints[i2],iPoints[i3], t));
            }
        }
        return curve;
    }

    public static function generate_deCasteljau(points:*, thresholdDistance:Number):Vector.<Object> {
        var curve:Vector.<Object> = new Vector.<Object>();
        curve.push(points[0]);
        deCasteljau(curve, thresholdDistance, points, points[0], points[points.length-1], 0, 1);
        curve.push(points[points.length-1]);
        return curve;
    }

    //==================================
    //     Tools
    //==================================
    public static function interpolatePoints(points:*, K:Number = 1):Vector.<Object> {
        var iPoints:Vector.<Object> = new Vector.<Object>();
        var p0:Object, p1:Object, p2:Object;
        var c1x:Number, c1y:Number, c2x:Number, c2y:Number, l1:Number, l2:Number, k:Number, mx:Number, my:Number;

        for (var i:int = 0; i < points.length; i++) {
            switch(i) {
                case 0: {
                    p1 = points[i];
                    p2 = points[i+1];

                    c2x = (p1.x + p2.x) / 2;
                    c2y = (p1.y + p2.y) / 2;

                    iPoints.push(
                            p1,
                            {x: p1.x + (c2x - p1.x) * K , y: p1.y + (c2y - p1.y) * K}
                    );

                    break;
                }
                case points.length-1: {
                    p0 = points[i-1];
                    p1 = points[i];

                    c1x = (p0.x + p1.x) / 2;
                    c1y = (p0.y + p1.y) / 2;

                    iPoints.push(
                            {x: p1.x + (c1x - p1.x) * K, y: p1.y + (c1y - p1.y) * K},
                            p1
                    );
                    break;
                }
                default: {
                    p0 = points[i-1];
                    p1 = points[i];
                    p2 = points[i+1];

                    c1x = (p0.x + p1.x) / 2; c1y = (p0.y + p1.y) / 2;
                    c2x = (p1.x + p2.x) / 2; c2y = (p1.y + p2.y) / 2;

                    l1 = ToolMath.hypothenuse(p1.x - p0.x, p1.y - p0.y);
                    l2 = ToolMath.hypothenuse(p2.x - p1.x, p2.y - p1.y);

                    k = l1 / (l1 + l2);

                    mx = c1x + (c2x - c1x) * k;
                    my = c1y + (c2y - c1y) * k;

                    iPoints.push(
                            {x: p1.x + (c1x - mx) * K, y: p1.y + (c1y - my) * K},
                            p1,
                            {x: p1.x + (c2x - mx) * K, y: p1.y + (c2y - my) * K}
                    );
                    break;
                }
            }
        }

        return iPoints;
    }

    private static function deCasteljau(output:*, threshold:Number, points:*, pleft:Object, pright:Object, t0:Number = 0, t1:Number = 1):void {
        var t:Number = (t0 + t1) / 2;
        var p:Object = equationN(points, t);
        var l:Object = ToolGeometry.getLineCoefficients(pleft, pright);
        if(Math.abs(ToolGeometry.distancePointToLine(l.a, l.b, l.c, p.x, p.y)) <= threshold) {
            output.push(p);
        } else {
            deCasteljau(output, threshold, points, pleft, p, t0, t);
            output.push(p);
            deCasteljau(output, threshold, points, p, pright, t, t1);
        }
    }


    //==================================
    //     Equations
    //==================================
    public static function equationLinear(p0:Object, p1:Object, t:Number):Object {
        return {
            x:(1-t)*p0.x + t*p1.x,
            y:(1-t)*p0.y + t*p1.y
        };
    }

    public static function equationQuadratic(p0:Object, p1:Object, p2:Object, t:Number):Object {
        var t1:Number = 1 - t;
        return {
            x:(t1*t1)*p0.x + 2*(t1*t)*p1.x + (t*t)*p2.x,
            y:(t1*t1)*p0.y + 2*(t1*t)*p1.y + (t*t)*p2.y
        };
    }

    public static function equationCubic(p0:Object, p1:Object, p2:Object, p3:Object, t:Number):Object {
        var t1:Number = 1 - t;
        return {
            x:(t1*t1*t1)*p0.x + 3*(t1*t1*t)*p1.x + 3*(t1*t*t)*p2.x + (t*t*t)*p3.x,
            y:(t1*t1*t1)*p0.y + 3*(t1*t1*t)*p1.y + 3*(t1*t*t)*p2.y + (t*t*t)*p3.y
        };
    }

    public static function equationN(points:*, t:Number):Object {
        var p:Object = {x:0, y:0};
        var n:int = points.length - 1;
        var t1:Number = 1 - t;
        var tt:Number = 1;
        var tt1:Number = Math.pow(t1, n);

        for (var i:int = 0; i <= n; i++) {
            //var cte:Number = ToolMath.binomialCoefficient(n, i) * Math.pow(t1, n - i) * Math.pow(t, i);
            var cte:Number = ToolMath.binomialCoefficient(n, i) * tt1 * tt;
            tt1 /= t1;
            tt *= t;

            p.x += cte * points[i].x;
            p.y += cte * points[i].y;
        }
        return p;
    }


}
}
