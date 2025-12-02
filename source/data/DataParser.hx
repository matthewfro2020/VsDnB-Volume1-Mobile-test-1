package data;

import flixel.util.FlxAxes;

/**
 * json2object has an annotation `jcustomparser` that allows you to customize the way certain data values are parsed
 * This is for values that aren't normally parsable such a `Dynamic`
 * 
 * Functions must be (T) -> T, with T being the type to be parsed.
 * 
 * @see https://github.com/elnabo/json2object
 */
class DataParser
{
    /**
     * Parses an axis value from the given json string.
     * @param value The json value.
     * @return An `FlxAxes`
     */
    public static function axisValue(value:String):FlxAxes
    {
        return FlxAxes.fromString(value);
    }
}