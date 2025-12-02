package util;

import flixel.FlxSprite;

class ZIndex {
    public static inline var DEFAULT:Int = 0;

    public static function setZ(sprite:FlxSprite, z:Int):FlxSprite {
        Reflect.setProperty(sprite, "zIndex", z);
        return sprite;
    }

    public static function getZ(sprite:FlxSprite):Int {
        return cast Reflect.getProperty(sprite, "zIndex");
    }
}
