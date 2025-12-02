package modding;

import thx.semver.Version;
import polymod.Polymod;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.TextFileFormat;
import polymod.fs.SysFileSystem;
import polymod.fs.SysFileSystem;
import play.song.SongModuleHandler;
import scripting.module.ModuleHandler;
import thx.semver.VersionRule;
import util.FileUtil;
import util.macro.ClassMacro;

/**
 * A handler for the library `Polymod`. A backend used for modding, and helps with the scripting backend.
 */
@:keep
class PolymodManager
{
    /**
     * The folder in the app that's used to scan for mods.
     */
    public static var MOD_FOLDER:String = 'mods';

    /**
     * The current API version of the game of the game.
     * Should be incremented in accordance to semantic versioning, in case any changes to the game's modding API happen. 
     */
    public static var API_VERSION:Version = '1.0.2';
    
    /**
     * The version rule of this mod's API. 
     * Used scanning and checking for mods for this mod's API. A mod's version will need to be in accordance to the rule, else it won't be loaded.
     */
    public static var API_VERSION_RULE:VersionRule = ">=1.0.0";

    /**
     * A list of all of the mods currently loaded from Polymod.
     */
    public static var loadedMods:Array<ModMetadata> = [];

    public static var modFileSystem:SysFileSystem = null;

	/**
	 * Initalizes Polymod.
	 */
	public static function initalize():Void
	{
        modFileSystem = buildFileSystem();
        
        // Imports need to be built first before configuring Polymod, or else you'll get a crash.
        buildImports();

		// Configure polymod.
        loadAllMods();
	}

    /**
     * Creates the mods folder directory in-case it doesn't already exist.
     */
    public static function createModRoot():Void
    {
        FileUtil.createDirectory(MOD_FOLDER);
    }

    /**
     * Loads a list of mods by their directory id name.
     * @param ids The list of mod directorys to load.
     */
    public static function loadModsById(ids:Array<String>)
    {
        createModRoot();

		loadedMods = Polymod.init({
			modRoot: MOD_FOLDER,
            dirs: ids,
			framework: OPENFL,
			frameworkParams: buildFrameworkParams(),
            errorCallback: PolymodErrorHandler.printError,
            apiVersionRule: API_VERSION_RULE,
            useScriptedClasses: true,
		});

        if (loadedMods.length == 0)
        {
            trace('Polymod was not able to load any mods.');
        }
        else
        {
            trace('Successfully loaded ${loadedMods.length} mod(s)!');
        }
    }

    /**
     * Initalizes Polymod while loading all mods that are found within in the game's mod folder.
     */
    public static function loadAllMods():Void
    {
        var modIds:Array<String> = getAllModIds();
        loadModsById(modIds);
    }

    /**
     * Initalizes Polymod with 0 mods.
     */
    public static function loadNoMods():Void
    {
        trace('Initalizing Polymod while loading 0 mods.');
        loadModsById([]);
    }

    /**
     * Retrieves a list of all mods, and their metadata from the game's mod folder.
     * @return An `Array<ModMetadata>`
     */
    public static function getAllMods():Array<ModMetadata>
    {
        createModRoot();
        
        var mods = Polymod.scan({
            modRoot: MOD_FOLDER,
            apiVersionRule: API_VERSION_RULE,
            errorCallback: PolymodErrorHandler.printError,
        });
        if (mods.length == 0)
        {
            trace('Polymod was able to find 0 mods.');
        }
        else
        {
            trace('Polymod found ${mods.length} mod(s) while scanning.');
        }
        return mods;
    }

    /**
     * Retrieves the ids of all mods found within the game's mod folder.
     */
    public static function getAllModIds():Array<String>
    {
        return [for (mod in getAllMods()) mod.id];
    }

	/**
	 * Builds the file system used for Polymod.
	 * @return A `SysFileSystem`
	 */
	public static function buildFileSystem():SysFileSystem
	{
		return new SysFileSystem({
			modRoot: MOD_FOLDER,
		});
	}

	/**
	 * Builds the framework parameters used for Polymod.
	 * @return A `FrameworkParams` structure.
	 */
	public static function buildFrameworkParams():FrameworkParams
	{
		return {
			assetLibraryPaths: 
            [
                'default' => 'preload',
                'shared' => 'shared',
                'songs' => 'songs'
            ],
            coreAssetRedirect: null
		}
	}
    
	static function buildParseRules():polymod.format.ParseRules
	{
		var output:polymod.format.ParseRules = polymod.format.ParseRules.getDefault();
		// Ensure TXT files have merge support.
		output.addType('txt', TextFileFormat.LINES);
		// Ensure script files have merge support.
		output.addType('hscript', TextFileFormat.PLAINTEXT);
		output.addType('hxs', TextFileFormat.PLAINTEXT);
		output.addType('hxc', TextFileFormat.PLAINTEXT);
		output.addType('hx', TextFileFormat.PLAINTEXT);

		return output;
	}

    /**
     * Clears, and re-loads all scripts from the disk.
     * Useful for hot reloading so you don't have to constantly re-open the program to test out changes.
     */
    public static function reloadAssets():Void
    {
        // Clear every script from the cache.
        ModuleHandler.clearModules();
        SongModuleHandler.clearModules();
        SongModuleHandler.clearModuleCache();

        // Forcibly re-load all mods, this re-registers scripted classes and updates any assets.
        loadAllMods();

        // Re-load all entries to include new data/scripted classes.
		data.character.CharacterRegistry.instance.loadEntries();
		data.stage.StageRegistry.instance.loadEntries();
        data.player.PlayerRegistry.instance.loadEntries();
		data.subtitle.SubtitleRegistry.instance.loadEntries();
		data.dialogue.DialogueRegistry.instance.loadEntries();
		data.dialogue.SpeakerRegistry.instance.loadEntries();
		data.song.SongRegistry.instance.loadEntries();
        
        play.song.SongModuleHandler.loadModules();
		data.language.LanguageManager.init();
		scripting.module.ModuleHandler.loadModules();
    }

    /**
     * Adds all of the default imports that Polymod should use for scripts.
     */
    public static function buildImports():Void
    {   
        Polymod.addImportAlias('util.ReflectUtil', Reflect);
        Polymod.addImportAlias('util.ReflectUtil', Type);
        
        // Blacklist powerful/dangerous classes.
        Polymod.blacklistImport(Type.getClassName(Sys));

        // Blacklist misc. classes.
        Polymod.blacklistImport('haxe.Unserializer');
        Polymod.blacklistImport('flixel.util.FlxSave');
        Polymod.blacklistImport('lime.system.CFFI'); 
        Polymod.blacklistImport('lime.system.JNI');

        Polymod.blacklistImport('openfl.desktop.NativeProcess');
        Polymod.blacklistImport('openfl.Lib');
        Polymod.blacklistImport('openfl.system.ApplicationDomain');
        Polymod.blacklistImport('openfl.net.SharedObject');

        // Blacklist HScript classes.
        for (cls in ClassMacro.listClassesInPackage('hscript'))
        {
            if (cls == null) continue;
            var className:String = Type.getClassName(cls);
            
            Polymod.blacklistImport(className);
        }

        // Blacklist any Polymod related classes.
        for (cls in ClassMacro.listClassesInPackage('polymod'))
        {
            if (cls == null) continue;
            var className:String = Type.getClassName(cls);
            
            Polymod.blacklistImport(className);
        }
        
        Polymod.blacklistImport('data.song.Highscore');
        
        /**
         * HAXE SPECIFIC
         */

        // Add default imports to normal Haxe classes.
        Polymod.addDefaultImport(Date);
        Polymod.addDefaultImport(DateTools);
        Polymod.addDefaultImport(EReg);
        Polymod.addDefaultImport(StringTools);

        /**
         * ENGINE SPECIFIC
         */
         
        // FLIXEL //

        Polymod.addDefaultImport(flixel.FlxG);
        Polymod.addDefaultImport(flixel.FlxCamera);
        Polymod.addDefaultImport(flixel.FlxSprite);
        Polymod.addDefaultImport(flixel.text.FlxText);
        Polymod.addDefaultImport(flixel.tweens.FlxEase);
        Polymod.addDefaultImport(flixel.tweens.FlxTween);
        Polymod.addDefaultImport(flixel.group.FlxGroup);
        Polymod.addDefaultImport(flixel.group.FlxSpriteGroup);
        Polymod.addDefaultImport(flixel.math.FlxPoint.FlxBasePoint, 'flixel.math.FlxPoint');
        Polymod.addDefaultImport(flixel.util.FlxTimer);
        
        // OPENFL //

        Polymod.addDefaultImport(openfl.filters.ColorMatrixFilter);
        Polymod.addDefaultImport(openfl.filters.ShaderFilter);

        // LIBRARY //
        
        Polymod.addDefaultImport(hxvlc.flixel.FlxVideo);
        Polymod.addDefaultImport(hxvlc.flixel.FlxVideoSprite);
        
        /**
         * GAME SPECIFIC
         */
        Polymod.addDefaultImport(Main);
        Polymod.addDefaultImport(Paths);
        
        Polymod.addDefaultImport(audio.GameSound);
        Polymod.addDefaultImport(audio.SoundGroup);
        Polymod.addDefaultImport(audio.SoundController);
        
        Polymod.addDefaultImport(backend.Conductor);

        Polymod.addDefaultImport(data.language.LanguageManager);
        Polymod.addDefaultImport(data.song.SongData.SongChartData);
        Polymod.addDefaultImport(data.song.SongRegistry);
        Polymod.addDefaultImport(data.stage.StageRegistry);

        Polymod.addDefaultImport(graphics.FlxAtlasSprite);
        Polymod.addDefaultImport(graphics.effects.IntervalShake);
        Polymod.addDefaultImport(graphics.shaders.RuntimeShader);
        Polymod.addDefaultImport(graphics.shaders.DropShadowShader);
        Polymod.addDefaultImport(graphics.video.VideoManager);
        
        Polymod.addDefaultImport(play.EndingState);
        Polymod.addDefaultImport(play.GameOverSubstate);
        Polymod.addDefaultImport(play.PauseSubState);
        Polymod.addDefaultImport(play.PlayState);
        Polymod.addDefaultImport(play.PlayStatePlaylist);
        Polymod.addDefaultImport(play.camera.FollowCamera);
        Polymod.addDefaultImport(play.camera.FollowCamera);
        Polymod.addDefaultImport(play.character.Character);
        Polymod.addDefaultImport(play.dialogue.Dialogue);
        Polymod.addDefaultImport(play.dialogue.Speaker);
        Polymod.addDefaultImport(play.save.Preferences);
        Polymod.addDefaultImport(play.song.Song);
        Polymod.addDefaultImport(play.song.SongModule);
        Polymod.addDefaultImport(play.song.SongModuleHandler);
        Polymod.addDefaultImport(play.stage.BGSprite);
        Polymod.addDefaultImport(play.stage.Stage);
        Polymod.addDefaultImport(play.stage.VoidBGSprite);
        Polymod.addDefaultImport(play.ui.Countdown);
        Polymod.addDefaultImport(play.ui.RatingsGroup);
        
        Polymod.addDefaultImport(scripting.HScriptAbstracts.ClassBlendMode, 'openfl.display.BlendMode');
        Polymod.addDefaultImport(scripting.HScriptAbstracts.ClassFlxAxes, 'flixel.util.FlxAxes');
        Polymod.addDefaultImport(scripting.events.ScriptEvent);
        Polymod.addDefaultImport(scripting.module.Module);

        Polymod.addDefaultImport(ui.Cursor);
        Polymod.addDefaultImport(ui.menu.story.StoryMenuState);
        Polymod.addDefaultImport(ui.menu.freeplay.FreeplayState);
        Polymod.addDefaultImport(ui.select.charSelect.CharacterSelect);

        Polymod.addDefaultImport(util.PlatformUtil);
        
        Polymod.addDefaultImport(util.FileUtil);
        Polymod.addDefaultImport(util.TweenUtil);
        
        Polymod.addDefaultImport(util.tools.MapTools);
        Polymod.addDefaultImport(util.tools.IteratorTools);
        Polymod.addDefaultImport(util.tools.Preloader);
        Polymod.addDefaultImport(util.tools.converters.SongConverter);
        
        // Import all abstract classes.
        for (alias => cls in polymod.hscript._internal.PolymodScriptClass.abstractClassImpls)
        {
            Polymod.addDefaultImport(cls, alias);
        }
    }
}