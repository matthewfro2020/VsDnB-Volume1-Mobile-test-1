package scripting.module;

import flixel.FlxG;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import util.SortUtil;

/**
 * Handles the behavior of modules such as dispatching them, storing them, etc.
 */
class ModuleHandler
{
    static var moduleList:Map<String, Module> = [];
    static var moduleSortCache:Array<String> = [];

    /**
     * Loads all modules from the asset cache.
     */
    public static function loadModules():Void
    {
        // Clear any modules currently in the cache.
        clearModules();

        var moduleScriptClasses:Array<String> = ScriptedModule.listScriptClasses();

        for (moduleClass in moduleScriptClasses)
        {
            var module:Module = ScriptedModule.init(moduleClass, moduleClass);

            if (module != null)
            {
                addModule(module);
                log('Loading module with an id: ${module.moduleId}');
            }
        }
        refreshModules();
        
        log('Successfully loaded ${moduleList.size()} modules');
    }

    /**
     * Adds a module into the cache.
     * @param module The module to add.
     */
    public static function addModule(module:Module)
    {
        if (module == null)
            return;

        moduleList.set(module.moduleId, module);
    }

    /**
     * Retrieves a module from the cache based on the given id.
     * @param id The id to get the module for.
     * @return A `Module`
     */
    public static function getModule(id:String):Module
    {
        return moduleList.get(id) ?? null;
    }

    /**
     * Enables a module if incase it's de-activated.
     * @param id The id of the module to enable.
     */
    public static function enableModule(id:String)
    {
        var module:Module = getModule(id);
        module.activate();
    }

    /**
     * Disables a module with the given id.
     * @param id The id of the module to de-activate.
     */
    public static function disableModule(id:String)
    {
        var module:Module = getModule(id);
        module.deactivate();
    }

    /**
     * Refreshes the modules by re-ordering them based on their priority.
     */
    public static function refreshModules():Void
    {        
        moduleSortCache = moduleList.keys().array().copy();
        moduleSortCache.sort(sortByPriority);
    }

    /**
     * Clear every module from the cache.
     * This'll Calls the `DESTROY` script event before they're destroyed.
     */
    public static function clearModules():Void
	{
        if (moduleList != null && moduleList.size() > 0)
        {
            var event = new ScriptEvent(DESTROY, false);
            
            // Call the destroy event on all modules before destroying them.
            callEvent(event);
        }

        moduleList.clear();
        moduleList = [];
    }

    /**
     * Dispatches the given script event to call all modules in the current cache.
     * @param event The event to dispatch.
     */
    public static function callEvent(event:ScriptEvent):Void
    {
        // Since the module cache is ordered.
        for (moduleId in moduleSortCache)
        {
            callOnModule(moduleId, event);
        }
    }

    /**
     * Dispatches a script event to a specific module with a given id.
     * @param id The id of the module to call.
     * @param event The event to dispatch to the module.
     */
    public static function callOnModule(id:String, event:ScriptEvent)
    {
        var module:Module = getModule(id);

        // If the module isn't activated, then it can't receive the script event.
        if (module != null && module.enabled)
        {
            ScriptEventDispatcher.callEvent(module, event);
        }
    }

    /**
     * Dispatches the `CREATE` event to all modules to help initalize them.
     */
    public static function callOnCreate():Void
    {
        callEvent(new ScriptEvent(CREATE, false));
    }

    public static function buildModuleCallbacks():Void
    {
        FlxG.signals.postStateSwitch.add(onSwitchStateComplete);
    }

    static function onSwitchStateComplete():Void
    {
        callEvent(new StateChangeScriptEvent(STATE_CHANGE_POST, FlxG.state, true));
    }

	/**
	 * Sorts all modules based on their priority priority.
	 * @param module The first module being compared.
	 * @param module2 The second module being compared.
     * 
	 * @return `Int` telling whether they should be swapped, or not.
	 */
	static function sortByPriority(module1:String, module2:String):Int
	{
        var a:Null<Module> = getModule(module1);
        var b:Null<Module> = getModule(module2);
        
        if (a == null || b == null)
            return 0;
	
        if (a.priority != b.priority)
		{
			return a.priority - b.priority;
		}
		else
		{
			return SortUtil.alphabetically(module1, module2);
		}
	}
    
    /**
     * Logs a message from this ModuleHandler.
     * @param message The message to log to the console.
     */
    static function log(message:String)
    {
        trace('[ModuleHandler] ${message}');
    }
}