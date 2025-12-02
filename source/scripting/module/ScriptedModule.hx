package scripting.module;

/**
 * A module class that's attached through a script.
 * Create a script and extend by `Module` to use.
 */
@:hscriptClass
class ScriptedModule extends scripting.module.Module implements polymod.hscript.HScriptedClass {}