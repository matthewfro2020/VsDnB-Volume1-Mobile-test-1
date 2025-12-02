package mobile;

import flixel.FlxG;
import flixel.input.touch.FlxTouch;
import flixel.util.FlxRect;

class MobileInput {
    public static var left:Bool = false;
    public static var down:Bool = false;
    public static var up:Bool = false;
    public static var right:Bool = false;

    // Hitboxes (change if needed)
    static var leftR  = new FlxRect(0, FlxG.height * 0.45, FlxG.width * 0.25, FlxG.height * 0.55);
    static var downR  = new FlxRect(FlxG.width * 0.25, FlxG.height * 0.45, FlxG.width * 0.25, FlxG.height * 0.55);
    static var upR    = new FlxRect(FlxG.width * 0.50, FlxG.height * 0.45, FlxG.width * 0.25, FlxG.height * 0.55);
    static var rightR = new FlxRect(FlxG.width * 0.75, FlxG.height * 0.45, FlxG.width * 0.25, FlxG.height * 0.55);

    public static function update():Void {
        left = down = up = right = false;

        for (touch in FlxG.touches.list) {
            if (leftR.containsPoint(touch)) left = true;
            if (downR.containsPoint(touch)) down = true;
            if (upR.containsPoint(touch)) up = true;
            if (rightR.containsPoint(touch)) right = true;
        }
    }
}
