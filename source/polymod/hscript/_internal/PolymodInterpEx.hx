package polymod.hscript._internal;

import hscript.Interp;
import hscript.Expr;
import haxe.io.Bytes;
import haxe.ds.StringMap;

/**
 *  SAFE MOBILE PATCH
 *  ------------------
 *  Fixes:
 *  - Missing curExpr on Android/iOS
 *  - Bad reflection calls
 *  - Crashes when parsing script classes
 *  - Exceptions during async load
 *  - Interp recursion depth
 */
class PolymodInterpEx extends Interp {

    /** Replacement for curExpr which is missing on some platforms */
    public var lastExpr:Expr = null;

    /** Prevent recursive crashes */
    static inline var MAX_DEPTH:Int = 3000;
    var depth:Int = 0;

    /** Script class registration storage */
    public static var _scriptClassDescriptors:Array<Dynamic> = [];

    public function new() {
        super();

        // Android/iOS crash fix → avoid Reflect on private Interp state
        #if (android || ios)
        this.allowRecursion = false;
        #end
    }

    /** Expression override with safe depth + tracking */
    override function expr(e:Expr):Dynamic {
        lastExpr = e;

        depth++;
        if (depth > MAX_DEPTH)
            error("Maximum script recursion depth reached (" + MAX_DEPTH + ")");

        var out = null;
        try {
            out = super.expr(e);
        } catch (err:Dynamic) {
            handleScriptError(err, e);
        }

        depth--;
        return out;
    }

    /**  
     * Mobile-safe error reporter  
     * Without this, Android logs die silently  
     */
    function handleScriptError(err:Dynamic, e:Expr):Void {
        var pos = (e != null && e.pos != null) ? e.pos.toString() : "unknown";

        #if (android || ios)
        trace("[POLYMOD/HScript ERROR] " + err + " @ " + pos);
        #else
        haxe.Log.trace("[HScript] " + err + " @ " + pos);
        #end

        throw err;
    }

    /** Safe async eval hook */
    public static function registerScriptClassByPathAsync(path:String):Void {
        haxe.Timer.delay(() -> {
            try registerScriptClassByPath(path) catch(e) trace("Error: " + e);
        }, 1);
    }

    /** Script class loader (synchronous) */
    public static function registerScriptClassByPath(path:String):Void {
        var script:String = polymod.Polymod.assetLibrary.getText(path);
        if (script == null || script == "") return;

        var p = new PolymodInterpEx();
        try {
            p.execute(script);
            _scriptClassDescriptors.push(p);
        } catch (e:Dynamic) {
            trace("[PolymodInterpEx] Script parse error: " + e);
        }
    }

    /** Soft fallback for incompatible HScript functions */
    public function safeCall(method:String, args:Array<Dynamic>):Dynamic {
        var fn:Dynamic = get(method);
        if (fn == null)
            return null;
        return Reflect.callMethod(null, fn, args);
    }
}
