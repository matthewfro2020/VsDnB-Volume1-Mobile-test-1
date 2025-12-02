package util.plugins;

import scripting.ScriptEventDispatchState;
import flixel.FlxBasic;
import flixel.FlxG;
import modding.PolymodManager;

/**
 * A plugin that binds a set of keybinds to allow the user to re-load assets.
 */
class ReloadAssetsPlugin extends FlxBasic
{
    public override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.F3)
        {
            reload();
        }
    }

    public static function reload():Void
    {
        var state:ScriptEventDispatchState = cast FlxG.state;
        if (state != null)
        {
            state.reloadAssets();
        }
        else
        {
            PolymodManager.reloadAssets();
            FlxG.resetState();
        }
    }
}