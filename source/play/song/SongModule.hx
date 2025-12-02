package play.song;

import scripting.IScriptedClass.IDialogueScriptedClass;
import flixel.FlxBasic;
import flixel.FlxG;
import play.song.SongModuleHandler;
import scripting.events.ScriptEvent;
import scripting.IScriptedClass.IPlayStateScriptedClass;

/**
 * A module that can be attached to a song that runs the given scripted functions if the player's on a specific song/variation.
 * 
 * Exists to help keep scripted functions, events, and logic separate with songs with multiple variations.
 * This can also be used in-case you want your scripted functions to be ran inside a module instead of the song script itself.
 * 
 * Extend `SongModule`, and provide the given song and variation id in the constructor to run this module. 
 */
class SongModule implements IPlayStateScriptedClass implements IDialogueScriptedClass implements IDialogueScriptedClass
{
    /**
     * The id of this module.
     */
    public var moduleId(default, null):String;

    /**
     * The id of the song this module is attached to.
     */
    public var songId(default, null):String;

    /**
     * The variation this module is attached to.
     */
    public var variation(default, null):String;

    /**
     * The priority this module has when calling scripts.
     * A lower priority will mean this module will be called first in favor of other attached song modules.
     */
    public var priority(default, set):Int;

    function set_priority(value:Int):Int
    {
        priority = value;
        SongModuleHandler.reorderModules();
        return value;
    }

    /**
     * Whether this module is currently active, and running.
     * Disabling will mean this module will not be dispatched and have any of its scripted classes called.
     */
    public var enabled(default, null):Bool = true;

    /**
     * The current PlayState instance so it's easily accessible for scripts.
     */
    var game:PlayState;

    /**
     * Creates a new SongModule instance.
     * @param moduleId The id of the module.
     * @param songId The id of the song for this module to run on.
     * @param variationId The variation of this module to run on.
     */
    public function new(moduleId:String, priority:Int, songId:String, ?variationId:Null<String> = null)
    {
        this.moduleId = moduleId;
        this.songId = songId;
        this.variation = variationId ?? Song.DEFAULT_VARIATION;
        
        this.priority = priority;
    }
    
    /**
     * Further initalizes the SongModule before it runs.
     */
    public function initalize():Void
    {
        if (FlxG.state is PlayState)
        {
            game = PlayState.instance;
        }
    }

    /**
     * De-activates this song module making it not be able to run it's functions.
     */
    public function deactivate():Void
    {
        enabled = false;
    }

    /**
     * Re-enables this song module. This'll make it be able to run the scripted functions.
     */
    public function activate():Void
    {
        enabled = true;
    }

    function toString():String
    {
        return 'SongModule(song=(id=$songId, variation=$variation), id=$moduleId, priority=$priority';
    }

    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}

    public function onUpdate(event:UpdateScriptEvent):Void {}

    public function onDestroy(event:ScriptEvent):Void {}
	
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}

    public function onNoteSpawn(event:NoteScriptEvent):Void {}

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
    
    public function onDialogueStart(event:DialogueScriptEvent):Void {}

    public function onDialogueLine(event:DialogueScriptEvent):Void {}

    public function onDialogueLineComplete(event:DialogueScriptEvent):Void {}
    
    public function onDialogueEnd(event:DialogueScriptEvent):Void {}
    
    public function onDialogueSkip(event:DialogueScriptEvent):Void {}
}