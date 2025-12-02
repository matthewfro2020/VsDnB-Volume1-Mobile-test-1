package ui.intro;

import controls.KeybindPrefs;
import controls.PlayerSettings;

import data.character.CharacterRegistry;
import data.dialogue.DialogueRegistry;
import data.dialogue.SpeakerRegistry;
import data.language.LanguageManager;
import data.player.PlayerRegistry;
import data.song.SongRegistry;
import data.subtitle.SubtitleRegistry;
import data.stage.StageRegistry;

import data.song.Highscore;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.TransitionData;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import modding.PolymodManager;
import play.save.Preferences;
import ui.menu.freeplay.FreeplayState;
import ui.select.charSelect.CharacterSelect;
import util.tools.Preloader;
import util.tools.CrashHandler;

#if desktop
import api.Discord.DiscordClient;
#end

/**
 * A state used to initalize and prepare the game to start, as well as load any game data such as the user's save data, controls, highscores, etc.
 */
class InitState extends FlxUIState
{
	public override function create()
	{
		// Bind the save data to the correct path.
		FlxG.save.bind('funkin', 'dnbteam');

		// Sets sprites to be automatically antialiased when created.
		FlxSprite.defaultAntialiasing = true;

		// Reduces physics accuracy in favor of higher FPS and animation framerate in states (DR those who know).
		FlxG.fixedTimestep = false;

		// Sometimes audio automatically mutes because of the default Flixel save data. 
		// We need this to be controlled through the preferences instead of this.
		FlxG.sound.muted = false;

		// Make sure the game auto pauses when you lose focus.
		FlxG.autoPause = true;

		// Initalize the cursor.
		Cursor.initalize();
		
		// Load the user's preferences.
		Preferences.init();

		// Initalize controls.
		PlayerSettings.init();
		KeybindPrefs.loadControls();
		
		// Load any necessary save data.
		Highscore.load();
		CharacterSelect.initSave();
		FreeplayState.initSave();

		// Initalize Discord RPC.
		#if desktop
		DiscordClient.prepare();
		#end
		
		intializeRegistries();
		initalizePlugins();
		initalizeTransitions();
		
		Preloader.initalize();
		CrashHandler.initalize();
		
		#if debug
		if (FlxG.save.data.hasSeenOptionsReminder == null || !FlxG.save.data.hasSeenOptionsReminder)
		{
			FlxG.switchState(() -> new OptionsReminderState());
		}
		else
		{
			FlxG.switchState(() -> new TitleState());
		}
		#else
		FlxG.switchState(() -> new GameSplash());
		#end
	}

	function initalizePlugins():Void
	{
		FlxG.plugins.addPlugin(new util.plugins.CrashPlugin());
		FlxG.plugins.addPlugin(new util.plugins.ReloadAssetsPlugin());
	}

	function intializeRegistries():Void
	{		
		// TODO: Move this to a registry maybe ?
		LanguageManager.init();

		CharacterRegistry.instance.loadEntries();
		StageRegistry.instance.loadEntries();
		PlayerRegistry.instance.loadEntries();
		SubtitleRegistry.instance.loadEntries();
		SongRegistry.instance.loadEntries();
		DialogueRegistry.instance.loadEntries();
		SpeakerRegistry.instance.loadEntries();

        play.song.SongModuleHandler.loadModules();
		
		scripting.module.ModuleHandler.buildModuleCallbacks();
		scripting.module.ModuleHandler.loadModules();
		scripting.module.ModuleHandler.callOnCreate();
	}

	function initalizeTransitions():Void
	{
		var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
		diamond.persist = true;
		diamond.destroyOnNoUse = false;

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, FlxPoint.get(-1, 0), {asset: diamond, width: 32, height: 32},
			new FlxRect(0, 0, FlxG.width, FlxG.height), NEW);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, FlxPoint.get(1, 0), {asset: diamond, width: 32, height: 32},
			new FlxRect(0, 0, FlxG.width, FlxG.height), NEW);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;
	}
}
