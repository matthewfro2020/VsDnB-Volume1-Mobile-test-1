package data.subtitle;

import audio.GameSound;
import flixel.util.FlxAxes;

typedef LegacySubtitleData =
{
	/**
	 * The x position of the subtitle.
	 */
	var ?x:Float;
    
	/**
	 * The y position of the subtitle.
	 */
	var ?y:Float;
    
	/**
	 * The step time at which this subtitle happens at.
	 */
	var ?stepTime:Int;
    
	/**
	 * The text displayed within the subtitle.
	 */
	var ?text:String;
    
	/**
	 * The size of the subtitle text.
	 */
	var ?subtitleSize:Int;

	/**
	 * The amount of time the subtitle shows before disappearing.
	 */
	var ?duration:Float;

	/**
	 * The speed the subtitle types at.
	 */
	var ?typeSpeed:Float;

	/**
	 * Whether the subtitle should just be at the center at the screen.
	 */
	var ?centerScreen:Bool;

	/**
	 * If `centerScreen` is on, the axes in which the subtitle should be centered on.
	 */
	var ?screenCenter:FlxAxes;

	/**
	 * The sounds this subtitle will play while being typed.
     * Defaults to none.
	 */
	var ?sounds:Array<GameSound>;
}