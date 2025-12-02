package play.song;

import flixel.FlxG;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import util.SortUtil;

/**
 * Handler for adding, loading, and retrieving song modules.
 * Shares a lot of the same functionaility as `ModuleHandler`
 */
class SongModuleHandler
{
    /**
     * A list of all of the song modules scripted classes.
     */
    static var songModuleCache:Map<String, Map<String, Array<String>>> = [];

    /**
     * Stores a list of the current song modules that are loaded.
     * This should ONLY be populated when the user's currently in a song.
     */
    static var loadedSongModules:Array<SongModule> = [];
    
    /**
     * Loads all modules from the asset cache.
     */
    public static function loadModules():Void
    {
        // Clear any modules currently in the cache.
        clearModules();
        clearModuleCache();

        var moduleScriptClasses:Array<String> = ScriptedSongModule.listScriptClasses();
        var modulesLoaded:Int = 0;
        
        for (moduleClass in moduleScriptClasses)
        {
            // Create the song module with generic arguments, they don't matter.
            var module:ScriptedSongModule = ScriptedSongModule.init(moduleClass, moduleClass, 0, 'warmup');
            if (module != null)
            {
                if (!songModuleCache.exists(module.songId))
                {
                    // Make a new variation cache.
                    songModuleCache.set(module.songId, new Map<String, Array<String>>());
                }
                addModuleToVariation(moduleClass, module.songId, module.variation);
                modulesLoaded++;
            }
            module = null;
        }
        log('Successfully loaded ${modulesLoaded} song module(s) from ${songModuleCache.size()} songs');

        FlxG.console.registerClass(SongModuleHandler);
    }

    /**
     * Fetches, and loads all of the song modules with a given song id, and (optional) variation id.
     * @param songId The song id the variation's from.
     * @param variationId The variation to get the modules from.
     */
    public static function loadVariationModules(songId:String, variationId:Null<String>):Void
    {
        // Clear any song modules before loading anything.
        clearModules();
        
        var moduleClasses:Array<String> = getVariationModules(songId, variationId);

        // Instantiate the modules.
        for (moduleCls in moduleClasses)
        {
            var module:ScriptedSongModule = ScriptedSongModule.init(moduleCls, moduleCls, 0, songId, variationId);
            if (module != null)
            {
                loadedSongModules.push(module);
            }
        }
        // Make sure the modules are correctly ordered.
        reorderModules();

        log('Loaded ${loadedSongModules.length} song module(s) for song ${songId} (${variationId})');
    }

    /**
     * Appends a module to the cache given a song variation id. 
     * @param moduleClass The scripted class name of the module to add.
     * @param songId The id of the song to add into the cache.
     * @param variationId The id of the song variation. 
     */
    public static function addModuleToVariation(moduleClass:String, songId:String, variationId:Null<String>):Void
    {
        variationId = Song.validateVariation(variationId);

		var variationCache:Map<String, Array<String>> = songModuleCache.get(songId);
		if (variationCache.exists(variationId))
		{
			// Module classes for this variation exist, so just append the module to the variation cache.
			var songModules:Array<String> = variationCache.get(variationId);
			songModules.push(moduleClass);

			variationCache.set(variationId, songModules);
			songModuleCache.set(songId, variationCache);
		}
		else
		{
			// Populate the variation.
			songModuleCache.get(songId).set(variationId, [moduleClass]);
		}
    }

    /**
     * Retrieves a list of song modules from the given song's variation.
     * @param songId The song the variation's from.
     * @param variation The variation to fetch the song modules from.
     */
    public static function getVariationModules(songId:String, variationId:Null<String>):Array<String>
    {
        variationId = Song.validateVariation(variationId);

        var variationCache = songModuleCache?.get(songId) ?? null;
        if (variationCache != null)
        {
            return variationCache?.get(variationId) ?? [];
        }
        return [];
    }
    
    /**
     * Given a song module id, return the first song module from the currently loaded ones.
     * @param id The id of the song module to fetch.
     * @return A `SongModule` from the 
     */
    public static function getModule(id:String):SongModule
    {
        for (module in loadedSongModules)
        {
            if (module.moduleId == id)
            {
                return module;
            }
        }
        return null;
    }

    /**
     * Enables a module if incase it's de-activated.
     * @param id The id of the module to enable.
     */
    public static function enableModule(id:String, songId:String, variation:Null<String>):Void
    {
        var module:SongModule = getModule(id);
        module.activate();
    }

    /**
     * Disables a module with the given id.
     * @param id The id of the module to de-activate.
     */
    public static function disableModule(id:String, songId:String, variation:Null<String>):Void
    {
        var module:SongModule = getModule(id);
        module.deactivate();
    }

    /**
     * Re-orders ALL of the loaded song modules based on their priority.
     */
    public static function reorderModules():Void
    {
        loadedSongModules?.sort(sortByPriority);
    }

	/**
	 * Sorts all song modules based on their priority priority.
	 * @param module The first module being compared.
	 * @param module2 The second module being compared.
     * 
	 * @return `Int` telling whether they should be swapped, or not.
	 */
	static function sortByPriority(a:SongModule, b:SongModule):Int
	{
        if (a == null || b == null)
            return 0;
	
        if (a.priority != b.priority)
		{
			return a.priority - b.priority;
		}
		else
		{
			return SortUtil.alphabetically(a.moduleId, b.moduleId);
		}
	}
    
    /**
     * Clears every song module from the cache.
     * This'll Calls the `DESTROY` script event before they're destroyed.
     */
    public static function clearModules():Void
	{
        if (loadedSongModules.length > 0)
        {
            var event = new ScriptEvent(DESTROY, false);
            
            // Call the destroy event on all modules before destroying them.
            callOnModules(event);
        }

        for (module in loadedSongModules)
            module = null;
        
        loadedSongModules = [];
    }

    /**
     * Clears all scripted module classes from the cache.
     * Used for hot reloading to be able to edit any song module scripts.
     */
    public static function clearModuleCache():Void
    {
        songModuleCache.clear();
        songModuleCache = [];
    }

    /**
     * Calls a script event to every currently loaded song module.
     * @param event The script event to dispatch.
     */
    public static function callOnModules(event:ScriptEvent)
    {
        forEachModule((module:SongModule) -> 
        {
            callOnModule(module, event);
        });
    }

    /**
     * Dispatches a script event to a specific module with a given id.
     * @param module The module to call.
     * @param event The event to dispatch to the module.
     */
    public static function callOnModule(module:SongModule, event:ScriptEvent)
    {
        // If the module isn't activated, then it can't receive the script event.
        if (module != null && module.enabled)
        {
            ScriptEventDispatcher.callEvent(module, event);
        }
    }

    /**
     * Iterates through each of the currently loaded song modules to call a function for each.
     * @param func The function to call for each module.
     */
    public static function forEachModule(func:SongModule->Void):Void
    {
        for (module in loadedSongModules)
        {
            func(module);
        }
    }

    /**
     * Logs a message from this ModuleHandler.
     * @param message The message to log to the console.
     */
    static function log(message:String)
    {
        trace('[SongModuleHandler] ${message}');
    }
}