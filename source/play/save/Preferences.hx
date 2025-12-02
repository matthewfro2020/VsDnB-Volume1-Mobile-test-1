package play.save;

import util.PlatformUtil;
import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxSignal.FlxTypedSignal;
import scripting.IScriptedClass.IEventDispatcher;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventType;
import scripting.events.ScriptEventDispatcher;

/**
 * A save object that contains the user's preferences from the settings.
 */
class Preferences
{
	/**
	 * The save connected to these preferences.
	 */
	public static var save(default, null):FlxSave;

	/**
	 * A map of the values of each preference incase one doesn't already exist.
	 */
	public static var defaults(default, null):Map<String, Any> =
	[
		'downscroll' => false,
		'ghostTapping' => true,
		'cutscenes' => true,

		'flashingLights' => true,
		'cameraShaking' => true,
		'cameraNoteMovement' => true,

		'masterVolume' => 1,
		'musicVolume' => 1,
		'voicesVolume' => 1,
		'sfxVolume' => 1,
		'hitsoundsVolume' => 0.7,

		'minimalUI' => false,
		'debugUI' => false,
		'timerType' => 'timeLeft',

		'gimmickWarnings' => true,
		'hitsounds' => false,
		'latencyOffsets' => 0,
		'language' => 'en-US',

		'vsync' => true,
		'fps' => 144,
		'borderless' => false,
		'darkMode' => false,

		'botplay' => false,
	];

	/**
	 * Signal fired whenever the user changes any preferences.
	 */
	public static var onPreferenceChanged(default, null):FlxTypedSignal<(preference:String, value:Any) -> Void> = new FlxTypedSignal<(preference:String, value:Any) -> Void>();

	/**
	 * Loads, and binds the save file.
	 */
	public static function init()
	{
		save = new FlxSave();
		save.bind('preferences', 'dnbteam');
		
		// Make sure the data isn't broken.
		if (save.data == null)
			save.flush();

		load();
	}

	/**
	 * Loads all of the user's preferences, and configures the game based on them.
	 */
	public static function load()
	{
		onPreferenceChanged.removeAll();
		
		for (preference => value in defaults)
		{
			if (save.data == null)
			{
				save.bind('preferences', 'dnbteam');
				save.flush();
			}

			if (!Reflect.hasField(save.data, preference))
			{
				Reflect.setProperty(Preferences, preference, value);
			}
			else
			{
				// So the accessor functions call on every preference updating them.
				Reflect.setProperty(Preferences, preference, Reflect.getProperty(Preferences, preference));
			}
		}

		// Dispatch a script event for whenever the user's preference changes.
		onPreferenceChanged.add((preference:String, value:Any) -> 
		{
			// If we're in an event dispatching state (Almost always).
			var eventHandler:IEventDispatcher = cast FlxG.state;
			if (eventHandler != null)
			{
				eventHandler?.dispatchEvent(new PreferenceScriptEvent(preference, value));
			}
		});

		FlxG.console.registerClass(Preferences);
	}

	// GENERAL //

	/**
	 * Whether to have the notes move down instead of up when playing.
	 */
	public static var downscroll(get, set):Bool;

	static function set_downscroll(value:Bool):Bool
	{
		save.data.downscroll = value;
		save.flush();
		onPreferenceChanged.dispatch('downscroll', value);
		return value;
	}

	static function get_downscroll():Bool
		return save?.data?.downscroll;

	/**
	 * Whether you're able to hit keys without being punished.
	 */
	public static var ghostTapping(get, set):Bool;

	static function set_ghostTapping(value:Bool):Bool
	{
		save.data.ghostTapping = value;
		save.flush();
		onPreferenceChanged.dispatch('ghostTapping', value);
		return value;
	}

	static function get_ghostTapping():Bool
	{
		return save?.data?.ghostTapping;
	}

	/**
	 * Whether to have cutscenes and dialogue show.
	 */
	public static var cutscenes(get, set):Bool;

	static function set_cutscenes(value:Bool):Bool
	{
		save.data.cutscenes = value;
		save.flush();
		onPreferenceChanged.dispatch('cutscenes', value);
		return value;
	}

	static function get_cutscenes():Bool
	{
		return save?.data?.cutscenes;
	}

	// ACCESSIBILITY //

	/**
	 * Whether to have the amount of flashing lights present in the mod.
	 */
	public static var flashingLights(get, set):Bool;

	static function set_flashingLights(value:Bool):Bool
	{
		save.data.flashingLights = value;
		save.flush();
		onPreferenceChanged.dispatch('flashingLights', value);
		return value;
	}

	static function get_flashingLights():Bool
	{
		return save?.data?.flashingLights;
	}

	/**
	 * Whether to have camera shaking when it's present.
	 */
	public static var cameraShaking(get, set):Bool;

	static function set_cameraShaking(value:Bool):Bool
	{
		save.data.cameraShaking = value;
		save.flush();
		onPreferenceChanged.dispatch('cameraShaking', value);
		return value;
	}

	static function get_cameraShaking():Bool
	{
		return save?.data?.cameraShaking;
	}

	/**
	 * Whether to have the camera move slightly on note hits.
	 */
	public static var cameraNoteMovement(get, set):Bool;

	static function set_cameraNoteMovement(value:Bool):Bool
	{
		save.data.cameraNoteMovement = value;
		save.flush();
		onPreferenceChanged.dispatch('cameraNoteMovement', value);
		return value;
	}

	static function get_cameraNoteMovement():Bool
	{
		return save?.data?.cameraNoteMovement;
	}

	// AUDIO //

	/**
	 * The master volume of the game.
	 */
	public static var masterVolume(get, set):Float;

	static function set_masterVolume(value:Float):Float
	{
		save.data.masterVolume = value;
		FlxG.sound.volume = value;
		save.flush();
		onPreferenceChanged.dispatch('masterVolume', value);
		return value;
	}

	static function get_masterVolume():Float
	{
		return save?.data?.masterVolume;
	}

	/**
	 * Volume of any music being played.
	 */
	public static var musicVolume(get, set):Float;

	static function set_musicVolume(value:Float):Float
	{
		save.data.musicVolume = value;
		save.flush();
		onPreferenceChanged.dispatch('musicVolume', value);
		return value;
	}

	static function get_musicVolume():Float
	{
		return save?.data?.musicVolume;
	}

	/**
	 * Volume of any vocals being played.
	 */
	public static var voicesVolume(get, set):Float;

	static function set_voicesVolume(value:Float):Float
	{
		save.data.voicesVolume = value;
		save.flush();
		onPreferenceChanged.dispatch('voicesVolume', value);
		return value;
	}

	static function get_voicesVolume():Float
	{
		return save?.data?.voicesVolume;
	}

	/**
	 * Volume of any SFX played.
	 */
	public static var sfxVolume(get, set):Float;

	static function set_sfxVolume(value:Float):Float
	{
		save.data.sfxVolume = value;
		save.flush();
		onPreferenceChanged.dispatch('sfxVolume', value);
		return value;
	}

	static function get_sfxVolume():Float
	{
		return save?.data?.sfxVolume;
	}

	/**
	 * Volume of the hitsound that play when hitting a note if they're enabled.
	 */
	public static var hitsoundsVolume(get, set):Float;

	static function set_hitsoundsVolume(value:Float):Float
	{
		save.data.hitsoundsVolume = value;
		save.flush();
		onPreferenceChanged.dispatch('hitsoundsVolume', value);
		return value;
	}

	static function get_hitsoundsVolume():Float
	{
		return save?.data?.hitsoundsVolume;
	}

	// UI //

	/**
	 * Whether a lot of the UI elements should be shown or not.
	 */
	public static var minimalUI(get, set):Bool;

	static function set_minimalUI(value:Bool):Bool
	{
		save.data.minimalUI = value;
		save.flush();
		onPreferenceChanged.dispatch('minimalUI', value);
		return value;
	}

	static function get_minimalUI():Bool
	{
		return save?.data?.minimalUI;
	}

	/**
	 * Whether debug elements like the FPS and memory counter should show.
	 */
	public static var debugUI(get, set):Bool;

	static function set_debugUI(value:Bool):Bool
	{
		save.data.debugUI = value;
		Main.fps.visible = value;
		save.flush();
		onPreferenceChanged.dispatch('debugUI', value);
		return value;
	}

	static function get_debugUI():Bool
	{
		return save?.data?.debugUI;
	}

	/**
	 * What the UI timer in-game should display.
	 */
	public static var timerType(get, set):String;

	static function set_timerType(value:String):String
	{
		save.data.timerType = value;
		save.flush();
		onPreferenceChanged.dispatch('timerType', value);
		return value;
	}

	static function get_timerType():String
	{
		return save?.data?.timerType;
	}

	/**
	 * Whether the game should show a warning with songs that have gimmicks.
	 */
	public static var gimmickWarnings(get, set):Bool;

	static function set_gimmickWarnings(value:Bool):Bool
	{
		save.data.gimmickWarnings = value;
		save.flush();
		onPreferenceChanged.dispatch('gimmickWarnings', value);
		return value;
	}

	static function get_gimmickWarnings():Bool
	{
		return save?.data?.gimmickWarnings;
	}

	// MISC //

/**
 * Whether the game should control the player (Auto-Play)
 */
public static var botplay(get, set):Bool;

static function set_botplay(value:Bool):Bool
{
    save.data.botplay = value;
    save.flush();
    onPreferenceChanged.dispatch('botplay', value);
    return value;
}

static function get_botplay():Bool
{
    return save?.data?.botplay;
}
	
	/**
	 * Whether the game should play a hitsound when hitting a note.
	 */
	public static var hitsounds(get, set):Bool;

	static function set_hitsounds(value:Bool):Bool
	{
		save.data.hitsounds = value;
		save.flush();
		onPreferenceChanged.dispatch('hitsounds', value);
		return value;
	}

	static function get_hitsounds():Bool
	{
		return save?.data?.hitsounds;
	}

	/**
	 * The amount of time, in milliseconds, in which the conductor is offset by.
	 * Used to help account for headphone latency.
	 */
	public static var latencyOffsets(get, set):Int;

	static function get_latencyOffsets():Int
	{
		return save?.data?.latencyOffsets;
	}

	static function set_latencyOffsets(value:Int):Int
	{
		save.data.latencyOffsets = value;
		save.flush();
		onPreferenceChanged.dispatch('latencyOffsets', value);

		return value;
	}
	
	/**
	 * The language you're playing the game in.
	 */
	public static var language(get, set):String;

	static function set_language(value:String):String
	{
		save.data.language = value;
		save.flush();
		onPreferenceChanged.dispatch('language', value);
		return value;
	}

	static function get_language():String
	{
		return save?.data?.language;
	}

	
	// WINDOW //
	
	/**
	 * The amount of frames per seconds the game draws, and runs on.
	 */
	public static var fps(get, set):Int;

	static function set_fps(value:Int):Int
	{
		save.data.fps = value;
		save.flush();

		if (vsync)
		{
			#if !linux
			var refreshRate:Int = FlxG.stage.window.displayMode.refreshRate;
			#else
			// For some reason displayMode.refreshRate returns 0 on linux, so we leave this at 144.
			// TODO: Find a way to get the linux refresh rate.
			var refreshRate:Int = 144;
			#end
			
			// Set the FPS to just the monitor's refresh rate if Vsync is on.
			Main.frameRate = refreshRate;
			FlxG.updateFramerate = refreshRate;
			FlxG.drawFramerate = refreshRate;
		}
		else
		{
			Main.frameRate = Preferences.fps;
			FlxG.updateFramerate = Main.frameRate;
			FlxG.drawFramerate = Main.frameRate;

			onPreferenceChanged.dispatch('fps', value);
		}
		
		return value;
	}

	static function get_fps():Int
	{
		return save?.data?.fps;
	}

	/**
	 * Whether the game should sync its framerate with it's monitor's refresh rate.
	 */
	public static var vsync(get, set):Bool;

	static function set_vsync(value:Bool):Bool
	{
		save.data.vsync = value;
		save.flush();

		if (value)
		{
			#if !linux
			var refreshRate:Int = FlxG.stage.window.displayMode.refreshRate;
			#else
			var refreshRate:Int = 144;
			#end
			
			FlxG.updateFramerate = refreshRate;
			FlxG.drawFramerate = refreshRate;
			Main.frameRate = refreshRate;
		}
		else
		{
			Main.frameRate = Preferences.fps;
			FlxG.updateFramerate = Main.frameRate;
			FlxG.drawFramerate = Main.frameRate;
		}
		onPreferenceChanged.dispatch('vsync', value);

		return value;
	}

	static function get_vsync():Bool
	{
		return save?.data?.vsync;
	}
	
	/**
	 * Whether the window shouldn't show it's border.
	 */
	public static var borderless(get, set):Bool;

	static function set_borderless(value:Bool):Bool
	{
		save.data.borderless = value;
		save.flush();

		FlxG.stage.window.borderless = value;

		onPreferenceChanged.dispatch('borderless', value);
		
		return value;
	}

	static function get_borderless():Bool
	{
		return save?.data?.borderless;
	}

	/**
	 * Whether the window border should be a dark theme, instead of the normal light theme.
	 */
	public static var darkMode(get, set):Bool;

	static function set_darkMode(value:Bool):Bool
	{
		save.data.darkMode = value;
		save.flush();

		PlatformUtil.setDarkMode(FlxG.stage.window.title, value);
		
		if (!borderless)
		{
			// Needs to be done, or else the border color won't be updated.
			FlxG.stage.window.borderless = true;
			FlxG.stage.window.borderless = borderless;
		}
		onPreferenceChanged.dispatch('darkMode', value);
		
		return value;
	}
		
	static function get_darkMode():Bool
	{
		return save?.data?.darkMode;
	}
}
