package util;

import flixel.FlxSprite;

class FlxZSprite extends FlxSprite
{
    public var zIndex:Int = 0;

    public function new(x:Float = 0, y:Float = 0)
    {
        super(x, y);
    }
}
