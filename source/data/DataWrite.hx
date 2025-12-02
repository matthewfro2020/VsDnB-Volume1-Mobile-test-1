package data;

import flixel.util.FlxAxes;

/**
 * json2object has an annotation `jcustomwrite` that allows you to customize the way certain data values are parsed.
 * This is for values that aren't normally read, and writable such a `Dynamic`.
 * 
 * Functions must be (T) -> String, with T being the type to be parsed.
 * 
 * @see https://github.com/elnabo/json2object
 */
class DataWrite
{
    /**
     * Given an `FlxAxes` value, return a readable json string.
     * @param value The `FlxAxes` value
     * @return A JSON written `String`
     */
    public static function axisValue(value:Null<FlxAxes>):String
    {
        if (value == null)
            return '';

		return switch (value)
		{
			case X: 'x';
			case Y: 'y';
			case XY: 'xy';
			default: 'none';
		} 
    }
}