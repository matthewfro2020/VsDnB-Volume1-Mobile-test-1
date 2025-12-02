package scripting.events;

import play.dialogue.Dialogue;
import audio.GameSound;
import data.song.SongData.SongTimeChange;

import flixel.FlxState;
import flixel.FlxSprite;

import play.character.Character;
import play.notes.Note;
import play.notes.SustainNote;
import play.ui.Countdown.CountdownStep;
import play.subtitle.Subtitle;

/**
 * A base class that represents for all script events that are dispatched to scripted classes.
 */
class ScriptEvent
{
    /**
     * The type of event this script is.
     */
    public var type(default, null):ScriptEventType;

    /**
     * Whether this event is able to be cancelled by the children it's dispatched to.
     * When cancelled, the behavior can be customized for what happens for when the event is cancelled.
     */
    public var cancelable(default, null):Bool;

    /**
     * Whether the event was cancelled by one of the children that received it.
     */
    public var eventCanceled(default, null):Bool = false;

    /**
     * Whether the event should dispatch to any other elements when it's cancelled.
     */
    public var shouldPropagate(default, null):Bool = true;

    /**
     * Creates a new ScriptEvent to be used by scripts.
     * @param type The type of event this ScriptEvent is.
     * @param cancelable Whether this script event is cancellable. Automatically false.
     */
    public function new(type:ScriptEventType, cancelable:Bool = false)
    {
        this.type = type;
        this.cancelable = cancelable;
    }

    /**
     * Cancels this script event as long as it's able to be cancellable.
     */
    public function cancel():Void
    {
        if (cancelable)
        {
            this.eventCanceled = true;
        }
    }

    /**
     * Continues this script event as long as it was cancelled by another script.
     */
    public function revive():Void
    {
        if (cancelable && !eventCanceled)
        {
            this.eventCanceled = true;
        }
    }

    /**
     * Prevents other scripts from being able to receive this script event. 
     */
    public function stopPropagation():Void
    {
        shouldPropagate = false;
    }

    /**
     * Allows for others scripts to be able to receive this script event in case it was cancelled by another script.
     */
    public function resumePropagation():Void
    {
        this.shouldPropagate = true;
    }
	
    public function toString():String
	{
		return 'ScriptEvent(type=$type, cancelable=$cancelable)';
	}
}

/**
 * A script event that dispatches on update.
 * This is not cancellable.
 */
class UpdateScriptEvent extends ScriptEvent
{
    /**
     * The time passed since the last frame.
     * This can not be edited.
     */
    public var elapsed(default, null):Float;

    public function new(elapsed:Float)
    {
        super(UPDATE, false);

        this.elapsed = elapsed;
    }
    
    override function toString():String
    {
        return 'UpdateScriptEvent(elapsed=$elapsed)';
    }
}

/**
 * A script event dispatched whenever the user changes a preference.
 * Stores the preference that was changed, and the new value of the preference.
 * 
 * This script event is NOT cancellable.
 */
class PreferenceScriptEvent extends ScriptEvent
{
    /**
     * The id of the preference that was changed. This can not be changed.
     */
    public var preference(default, null):String;

    /**
     * The new value of the preference that was changed.
     */
    public var value(default, null):Any;

    /**
     * Initalizes a new PreferenceScriptEvent.
     * @param preference The preference that was changed.
     * @param value The new value.
     */
    public function new(preference:String, value:Any)
    {
        super(PREFERENCE_CHANGE, false);
        
        this.preference = preference;
        this.value = value;
    }
    
    override function toString():String
    {
        return 'PreferenceScriptEvent(preference=$preference, value=$value)';
    }
}

/**
 * A script event dispatched when the state/substate changes.
 */
class StateChangeScriptEvent extends ScriptEvent
{
    /**
     * The target state being changed.
     */
    var targetState(default, null):FlxState;

    public function new(type:ScriptEventType, targetState:FlxState, cancelable:Bool = false)
    {
        super(type, cancelable);

        this.targetState = targetState;
    }
    
    override function toString():String
    {
        return 'StateChangeScriptEvent(type=$type, targetState=$targetState)';
    }
}

/**
 * A script event dispatched that stores information from a Conductor.
 * While non of these can be changed. This can help to allow the user to do events based on a certain step, beat, etc.
 */
class ConductorScriptEvent extends ScriptEvent
{
    /**
     * The current step of the Conductor.
     */
    var step(default, null):Int;
    
    /**
     * The current beat of the Conductor.
     */
    var beat(default, null):Int;

    /**
     * The current measure of the Conductor.
     */
    var measure(default, null):Int;
    
    /**
     * The current `SongTimeChange` of the Conductor.
     */
    var timeChange(default, null):SongTimeChange;
    
    public function new(type:ScriptEventType, step:Int, beat:Int, measure:Int, timeChange:SongTimeChange, cancelable:Bool = true)
    {
        super(type, cancelable);

        this.step = step;
        this.beat = beat;
        this.measure = measure;
        this.timeChange = timeChange;
    }
    
    override function toString():String
    {
        return 'ConductorScriptEvent(type=$type, step=$step, beat=$beat, measure=$measure, timeChange=$timeChange)';
    }
}


// PLAYSTATE //

/**
 * A script event that's attached to a countdown.
 * This is cancellable. Cancelling this can allowing for functionaility of cancelling the Countdown, stopping it, etc.
 */
class CountdownScriptEvent extends ScriptEvent
{
    /**
     * The current step of the countdown.
     */
    public var step:CountdownStep;

    public function new(type:ScriptEventType, step:CountdownStep, cancelable:Bool = true)
    {
        super(type, cancelable);

        this.step = step;
    }
    
    override function toString():String
    {
        return 'CountdownScriptEvent(type=$type, step=$step)';
    }
}

/**
 * A script event event dispatched relating to the movement of the game camera.
 */
class CameraScriptEvent extends ScriptEvent
{
    /**
     * Whether the camera is pointed to the opponent, or not.
     * This can not be edited.
     */
    var isOpponent(default, null):Bool;

    public function new(type:ScriptEventType, isOpponent:Bool, cancelable:Bool = false)
    {
        super(type, cancelable);

        this.isOpponent = isOpponent;
    }
    
    override function toString():String
    {
        return 'CameraScriptEvent(type=$type, isOpponent=$isOpponent)';
    }
}

// NOTE //

/**
 * A script event attached to the information relating to a note.
 * This is used for events such as when a note is hit, and missed.
 */
class NoteScriptEvent extends ScriptEvent
{
    /**
     * The note sprite associated with this event.
     * This can not be edited.
     */
    public var note(default, null):Note;

    /**
     * The character that is being sung from this note.
     * This can not be edited.
     */
    public var character(default, null):Character;

    /**
     * The amount the health will change for this note event.
     * If this is an note miss, this value will be negative, a note hit script event will have this be positive.
     * 
     * This can be edited by scripts to change the amount of health gained/loss for a specific character, song, etc lol.
     */
    public var healthChange:Float;

    /**
     * The current combo as this event was dispatched.
     * On a note hit event, this'll be the current combo incremented, on a miss event this'll be the combo before being reset.
     * 
     * This can not be edited.
     */
    public var comboCount(default, null):Int;

    /**
     * The sound that plays when missed (used for the note miss script event).
     * This can allow to customize the miss sound through a script.
     */
    public var missSound:GameSound;

    public function new(type:ScriptEventType, note:Note, character:Character, healthChange:Float, comboCount:Int, missSound:GameSound, cancelable:Bool = true)
    {
        super(type, cancelable);

        this.note = note;
        this.character = character;
        this.healthChange = healthChange;
        this.comboCount = comboCount;
        this.missSound = missSound;
    }
    
    override function toString():String
    {
        return 'NoteScriptEvent(type=$type, note=$note, character=$character, healthChange=$healthChange, comboCount=$comboCount, missSound=$missSound)';
    }
}

/**
 * A script event used for storing information relating to a hold note.
 */
class HoldNoteScriptEvent extends NoteScriptEvent
{
    public var holdNote:SustainNote;

    public function new(type:ScriptEventType, holdNote:SustainNote, character:Character, healthChange:Float, combo:Int, missSound:GameSound, cancelable:Bool = true)
    {
        super(type, null, character, healthChange, combo, missSound, cancelable);

        this.holdNote = holdNote;
    }
}

/**
 * A script event that's dispatched whenever the player misses from pressing a key when there's no notes in place.
 * This event IS cancellable. Cancelling this event will allow for the player to not miss from a ghost note.
 */
class GhostNoteScriptEvent extends NoteScriptEvent
{
    /**
     * The ghost direction that the player pressed.
     */
    public var direction(default, null):Int;

    public function new(direction:Int, character:Character, healthChange:Float, comboCount:Int, missSound:GameSound, cancelable:Bool = true)
    {
        super(GHOST_NOTE_MISS, null, character, healthChange, comboCount, missSound, cancelable);

        this.direction = direction;
    }
    
    override function toString():String
    {
        return 'GhostNoteScriptEvent(direction=$direction)';
    }
}

// STAGE //

/**
 * A script event that's dispatched whenever a stage adds a sprite to the stage.
 * Can be used to further initalize a prop after it's added.
 */
class AddPropScriptEvent extends ScriptEvent
{
    /**
     * The sprite associated with this script event.
     * This is can not be edited.
     */
    var prop(default, null):FlxSprite;

    public function new(prop:FlxSprite, cancelable:Bool = true)
    {
        super(ON_ADD, cancelable);

        this.prop = prop;
    }
    
    override function toString():String
    {
        return 'AddPropScriptEvent(prop=$prop)';
    }
}

/**
 * A script event that's dispatched whenever a stage adds a sprite to the stage.
 * Can be used to further initalize a prop after it's added.
 */
class AddCharacterScriptEvent extends ScriptEvent
{
    /**
     * The sprite associated with this script event.
     */
    var character(default, null):Character;
    
    public function new(character:Character, cancelable:Bool = true)
    {
        super(ON_CHARACTER_ADD, cancelable);

        this.character = character;
    }
    
    override function toString():String
    {
        return 'AddCharacterScriptEvent(character=$character)';
    }
}

// SUBTITLE //

/**
 * A script event used to store the data relating to subtitles.
 */
class SubtitleScriptEvent extends ScriptEvent
{
    /**
     * The subtitle associated with this script event.
     */
    var subtitle(default, null):Subtitle;

    public function new(type:ScriptEventType, subtitle:Subtitle, cancelable:Bool = true)
    {
        super(type, cancelable);

        this.subtitle = subtitle;
    }
    
    override function toString():String
    {
        return 'SubtitleScriptEvent(type=$type, subtitle=$subtitle)';
    }
}

// DIALOGUE //

/**
 * A script event used to store the data relating to dialogue.
 */
class DialogueScriptEvent extends ScriptEvent
{
    /**
     * The dialogue box associated with this event.
     */
    var dialogue(default, null):Dialogue;

    public function new(type:ScriptEventType, dialogue:Dialogue, cancelable:Bool = true)
    {
        super(type, cancelable);

        this.dialogue = dialogue;
    }

    override function toString():String
    {
        return 'DialogueScriptEvent(type=$type, dialogue=$dialogue)';
    }
}