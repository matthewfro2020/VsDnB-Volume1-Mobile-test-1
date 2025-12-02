package util.plugins;

import flixel.FlxG;
import flixel.FlxBasic;

/**
 * A plugin that crashes the game pressing 'CTRL + SHIFT + C' for debugging purposes.
 */
class CrashPlugin extends FlxBasic
{
    override function update(elapsed:Float)
    {
        if (FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.C)
        {
            crashGame();
        }
    }

    function crashGame()
    {
        throw "This is a test crash caused by the CrashPlugin";
    }
}