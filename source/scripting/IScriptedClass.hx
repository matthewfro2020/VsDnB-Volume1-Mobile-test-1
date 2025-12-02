package scripting;

import scripting.events.ScriptEvent;

/**
 * An interface defining a list of functions for a class that dispatches script events.
 * Implement this to allow be able to dispatch events to other scripts.
 */
interface IEventDispatcher
{
    public function dispatchEvent(event:ScriptEvent):Void;
}

/**
 * An interface defining a list of base functions for a scripted classes to contain.
 */
interface IScriptedClass
{
    public function onScriptEvent(event:ScriptEvent):Void;
    public function onScriptEventPost(event:ScriptEvent):Void;

    public function onCreate(event:ScriptEvent):Void;
    public function onUpdate(event:UpdateScriptEvent):Void;
    public function onDestroy(event:ScriptEvent):Void;
    
    /**
     * Called whenever the user changes a preference.
     * Override this if you want your class to do custom behavior if the user ends up changing a preference.
     * @param event The event dispatched.
     */
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void;
}

/**
 * An interface defining a list of functions for a scripted class relating to state changing.
 */
interface IStateChangeScriptedClass extends IScriptedClass
{
    public function onStateChange(event:StateChangeScriptEvent):Void;
    public function onStateChangePost(event:StateChangeScriptEvent):Void;
    
    public function onSubStateOpen(event:StateChangeScriptEvent):Void;
    public function onSubStateOpenPost(event:StateChangeScriptEvent):Void;

    public function onSubStateClose(event:StateChangeScriptEvent):Void;
    public function onSubStateClosePost(event:StateChangeScriptEvent):Void;
}

/**
 * An interface defining a list of base functions for a scripted class linked to a conductor.
 */
interface IConductorSyncedScriptedClass extends IScriptedClass
{
    public function onStepHit(event:ConductorScriptEvent):Void;
    public function onBeatHit(event:ConductorScriptEvent):Void;
    public function onMeasureHit(event:ConductorScriptEvent):Void;
    
    public function onTimeChangeHit(event:ConductorScriptEvent):Void;
}

/**
 * An interface defining a list of functions for a scripted class that runs on PlayState.
 */
interface IPlayStateScriptedClass extends IConductorSyncedScriptedClass extends INoteScriptedClass
{
    public function onCreatePost(event:ScriptEvent):Void;
    public function onCreateUI(event:ScriptEvent):Void;

    public function onSongStart(event:ScriptEvent):Void;
    public function onSongLoad(event:ScriptEvent):Void;
    public function onSongEnd(event:ScriptEvent):Void;    

    public function onPause(event:ScriptEvent):Void;
    public function onResume(event:ScriptEvent):Void;

    public function onPressSeven(event:ScriptEvent):Void;
    
    public function onGameOver(event:ScriptEvent):Void;

    public function onCountdownStart(event:CountdownScriptEvent):Void;
    public function onCountdownTick(event:CountdownScriptEvent):Void;
    public function onCountdownTickPost(event:CountdownScriptEvent):Void;
    public function onCountdownFinish(event:CountdownScriptEvent):Void;

    public function onCameraMove(event:CameraScriptEvent):Void;
    public function onCameraMoveSection(event:CameraScriptEvent):Void;
    
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void;
}

/**
 * An interface defining a list of functions relating to notes.
 */
interface INoteScriptedClass extends IScriptedClass
{
    public function onNoteSpawn(event:NoteScriptEvent):Void;
    public function onOpponentNoteHit(event:NoteScriptEvent):Void;
    public function onPlayerNoteHit(event:NoteScriptEvent):Void;
    public function onNoteMiss(event:NoteScriptEvent):Void;

    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void;
}

/**
 * Defines a list of script functions relating to stages.
 */
interface IStageScriptedClass extends IScriptedClass
{
    public function onAdd(event:AddPropScriptEvent):Void;
    public function onCharacterAdd(event:AddCharacterScriptEvent):Void;
}

/**
 * Defines a list of script functions relating to dialogue, to help with dialogue script events.
 */
interface IDialogueScriptedClass extends IScriptedClass
{
    public function onDialogueStart(event:DialogueScriptEvent):Void;
    public function onDialogueLine(event:DialogueScriptEvent):Void;
    public function onDialogueLineComplete(event:DialogueScriptEvent):Void;
    public function onDialogueEnd(event:DialogueScriptEvent):Void;
    public function onDialogueSkip(event:DialogueScriptEvent):Void;
}