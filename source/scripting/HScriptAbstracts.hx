package scripting;

import openfl.display.BlendMode;
import flixel.util.FlxAxes;

/**
 * Class for putting Abstract enums into Classes
 */
class HScriptAbstracts
{
}

class ClassBlendMode
{
	public static var ADD(default, null):Int = cast BlendMode.ADD;
	public static var ALPHA(default, null):Int = cast BlendMode.ALPHA;
	public static var DARKEN(default, null):Int = cast BlendMode.DARKEN;
	public static var DIFFERENCE(default, null):Int = cast BlendMode.DIFFERENCE;
	public static var ERASE(default, null):Int = cast BlendMode.ERASE;
	public static var HARDLIGHT(default, null):Int = cast BlendMode.HARDLIGHT;
	public static var INVERT(default, null):Int = cast BlendMode.INVERT;
	public static var LAYER(default, null):Int = cast BlendMode.LAYER;
	public static var LIGHTEN(default, null):Int = cast BlendMode.LIGHTEN;
	public static var MULTIPLY(default, null):Int = cast BlendMode.MULTIPLY;
	public static var NORMAL(default, null):Int = cast BlendMode.NORMAL;
	public static var OVERLAY(default, null):Int = cast BlendMode.OVERLAY;
	public static var SCREEN(default, null):Int = cast BlendMode.SCREEN;
	public static var SHADER(default, null):Int = cast BlendMode.SHADER;
	public static var SUBTRACT(default, null):Int = cast BlendMode.SUBTRACT;

	@:from private static function fromString(value:String):Null<Int>
	{
		return switch (value)
		{
			case "add": ADD;
			case "alpha": ALPHA;
			case "darken": DARKEN;
			case "difference": DIFFERENCE;
			case "erase": ERASE;
			case "hardlight": HARDLIGHT;
			case "invert": INVERT;
			case "layer": LAYER;
			case "lighten": LIGHTEN;
			case "multiply": MULTIPLY;
			case "normal": NORMAL;
			case "overlay": OVERLAY;
			case "screen": SCREEN;
			case "shader": SHADER;
			case "subtract": SUBTRACT;
			default: null;
		}
	}
}

class ClassFlxAxes
{	
	public static var X    = cast FlxAxes.X;
	public static var Y    = cast FlxAxes.Y;
	public static var XY   = cast FlxAxes.XY;
	public static var NONE = cast FlxAxes.NONE;
	
	public static function fromString(axes:String):FlxAxes
	{
		return switch axes.toLowerCase()
		{
			case "x": X;
			case "y": Y;
			case "xy" | "yx" | "both": XY;
			case "none" | "" | null : NONE;
			default : throw "Invalid axes value: " + axes;
		}
	}
}