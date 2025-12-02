package patch;

#if (ios || mobile || MOBILE_BUILD)
import haxe.macro.Context;
import haxe.macro.Expr;

class ThxIOSPatch
{
    /**
     * Removes thx.Nil and thx.Tuple0 from compilation.
     * Avoids conflict with Apple system macro "Nil".
     */
    public static function apply():Void
    {
        removeModule("thx.Nil");
        removeModule("thx._Tuple.Tuple0_Impl_");
        removeModule("thx._Tuple.Tuple0");
        removeModule("thx.Tuple0");
    }

    static function removeModule(path:String):Void
    {
        try {
            var m = Context.getModule(path);
            if (m != null)
            {
                Context.warning('[polymod-ios-patch] Removing problematic module: $path', Context.currentPos());
                Context.removeModule(path);
            }
        } catch(e:Dynamic) {
            // ignore if module not found
        }
    }
}
#end
