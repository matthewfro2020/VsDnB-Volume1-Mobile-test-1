package data.subtitle;

import json2object.JsonWriter;
import flixel.FlxG;
import audio.GameSound;
import flixel.util.FlxAxes;

/**
 * A data structure that defines the properties for a Subtitle.
 */
class SongSubtitleData
{
    /**
     * The semantic version number for this data object.
     */
    public var version:String;
	
	/**
	 * The base script class that subtitles will use (unless a custom one is given in their data).
	 */
	@:optional
	public var scriptClass:Null<String> = null;

	/**
	 * A list of asset paths to sounds for the subtitle will play while being typed.
     * Defaults to none.
	 */
	@:default(null)
	@:optional
	public var sounds:Null<Array<String>> = null;

	/**
	 * A list containing all of the subtitles that appear in the song.
	 */
	public var subtitles:Array<SubtitleData>;
	
	public function new() {}

    /**
     * Serializes this SubtitleData object into a json string.
     * @return A SubtitleData JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<SongSubtitleData> = new JsonWriter<SongSubtitleData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }

	/**
	 * Edits the subtitle data to make sure there's no empty/null properties.
	 * @param data The data to validate.
	 */
	public function validate():Void
	{
		for (subtitle in subtitles)
		{
			if (subtitle == null)
				subtitle = {};
			
			if (subtitle.x == null) subtitle.x = FlxG.width / 2;
			if (subtitle.y == null) subtitle.y = (FlxG.height / 2) - 200;
			
			if (subtitle.key == null) 
				subtitle.key = 'none';
			
			if (subtitle.time == null) 
				subtitle.time = 0.0;

			if (subtitle.subtitleSize == null) 
				subtitle.subtitleSize = 36;
			if (subtitle.typeSpeed == null) 
				subtitle.typeSpeed = 0.02;
			
			if (subtitle.centerScreen == null) 
				subtitle.centerScreen = true;

			if (subtitle.screenCenterAxis == null) 
				subtitle.screenCenterAxis = FlxAxes.X;

			if (subtitle.duration == null)
				subtitle.duration = 1;

			if (subtitle.scriptClass == null)
				subtitle.scriptClass = null;
			
			if (subtitle.sounds == null)
				subtitle.sounds = null;

		}
	}
}

typedef SubtitleData =
{
	/**
	 * The x position of the subtitle.
	 */
	@:default(640)
	public var ?x:Float;
    
	/**
	 * The y position of the subtitle.
	 */
	@:default(160)
	public var ?y:Float;
    
	/**
	 * The time (in seconds) in which this subtitle is supposed to appear.
	 */
	@:default(0.0)
	public var ?time:Float;
    
	/**
	 * The localization key used for the text of the subtitle.
	 * The game will fetch the text from this key in the `subtitles.txt` file that's in the user's current locale folder.
	 */
	@:default('')
	public var ?key:String;
    
	/**
	 * The size of the subtitle text.
	 */
	@:default(36)
	public var ?subtitleSize:Int;

	/**
	 * The amount of time the subtitle shows before disappearing.
	 */
	@:default(1.0)
	public var ?duration:Float;

	/**
	 * The speed the subtitle types at.
	 */
	@:default(0.02)
	public var ?typeSpeed:Float;

	/**
	 * Whether the subtitle should just be at the center at the screen.
	 */
	@:default(true)
	public var ?centerScreen:Bool;

	/**
	 * If `centerScreen` is on, the axes in which the subtitle should be centered on.
	 */
	@:jcustomwrite(data.DataWrite.axisValue)
	@:jcustomparser(data.DataParser.axisValue)
	public var ?screenCenterAxis:FlxAxes;

	/**
	 * The base script class that subtitles will use (unless a custom one is given in their data).
	 */
	public var ?scriptClass:Null<String>;

	/**
	 * A list of asset paths to sounds for the subtitle will play while being typed.
     * Defaults to none.
	 */
	@:default([])
	public var ?sounds:Array<String>;
}