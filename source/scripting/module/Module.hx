package scripting.module;

import scripting.IScriptedClass.IDialogueScriptedClass;
import scripting.events.ScriptEvent;
import scripting.IScriptedClass.IStateChangeScriptedClass;
import scripting.IScriptedClass.IPlayStateScriptedClass;

/**
 * A global script class that doesn't require a specific context.
 * 
 * Essentially, this is a global script that consistently is dispatched as long as the current state is one that dispatches events.
 */
class Module implements IPlayStateScriptedClass implements IStateChangeScriptedClass implements IDialogueScriptedClass
{
    /**
     * The id of this module.
     */
    public var moduleId(default, null):String;

    /**
     * The amount of priority this module has in terms of other modules.
     * This determines what modules are called first, and which are called last.
     * 
     * A module with a priority of `0` will be called before a module with a priority of `100`, etc.
     */
    public var priority:Int;
    
    /**
     * Whether this module is currently active, and running.
     * Disabling will mean this module will not be dispatched and have any of its scripted classes called.
     */
    public var enabled(default, null):Bool = true;

    /**
     * Creates a new module.
     * @param id The id of the module.
     * @param priority The priority of the module.
     */
    public function new(id:String, priority:Int = 0)
    {
        this.moduleId = id;
        this.priority = priority;
    }

    /**
     * De-activates this module.
     */
    public function deactivate():Void
    {
        enabled = false;
    }

    public function activate():Void
    {
        enabled = true;
    }

    function toString():String
    {
        return 'Module(id=$moduleId, priority=$priority)';
    }
    
    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}
    
    public function onUpdate(event:UpdateScriptEvent):Void {}

    public function onDestroy(event:ScriptEvent):Void {}

    public function onNoteSpawn(event:NoteScriptEvent):Void {}
	
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}

    public function onOpponentNoteHit(event:NoteScriptEvent):Void {}

    public function onPlayerNoteHit(event:NoteScriptEvent):Void {}
    
    public function onNoteMiss(event:NoteScriptEvent):Void {}
    
    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void {}

    public function onStepHit(event:ConductorScriptEvent):Void {}

    public function onBeatHit(event:ConductorScriptEvent):Void {}

    public function onMeasureHit(event:ConductorScriptEvent):Void {}
    
    public function onTimeChangeHit(event:ConductorScriptEvent):Void {}

    public function onCreatePost(event:ScriptEvent):Void {}

    public function onCreateUI(event:ScriptEvent):Void {}

    public function onSongStart(event:ScriptEvent):Void {}

    public function onSongLoad(event:ScriptEvent):Void {}

    public function onSongEnd(event:ScriptEvent):Void {} 

    public function onPause(event:ScriptEvent):Void {}

    public function onResume(event:ScriptEvent):Void {}

    public function onPressSeven(event:ScriptEvent):Void {}
    
    public function onGameOver(event:ScriptEvent):Void {}

    public function onCountdownStart(event:CountdownScriptEvent):Void {}

    public function onCountdownTick(event:CountdownScriptEvent):Void {}

    public function onCountdownTickPost(event:CountdownScriptEvent):Void {}

    public function onCountdownFinish(event:CountdownScriptEvent):Void {}

    public function onCameraMove(event:CameraScriptEvent):Void {}

    public function onCameraMoveSection(event:CameraScriptEvent):Void {}
    
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void {}

	public function onStateChange(event:StateChangeScriptEvent) {}

	public function onStateChangePost(event:StateChangeScriptEvent) {}

	public function onSubStateOpen(event:StateChangeScriptEvent) {}

	public function onSubStateOpenPost(event:StateChangeScriptEvent) {}
    
	public function onSubStateClose(event:StateChangeScriptEvent) {}

	public function onSubStateClosePost(event:StateChangeScriptEvent) {}

    public function onDialogueStart(event:DialogueScriptEvent):Void {}

    public function onDialogueLine(event:DialogueScriptEvent):Void {}

    public function onDialogueLineComplete(event:DialogueScriptEvent):Void {}
    
    public function onDialogueEnd(event:DialogueScriptEvent):Void {}
    
    public function onDialogueSkip(event:DialogueScriptEvent):Void {}
}