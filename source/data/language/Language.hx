package data.language;

import flixel.util.FlxColor;

/**
 * A type definition that defines the properties for a language.
 */
typedef Language = 
{
	/**
	 * The readable name of the language.
	 */
	var name:String;
	
	/**
	 * The id of the language.
	 */
	var id:String;

	/**
	 * The color for this language.
	 */
	var color:FlxColor;
}