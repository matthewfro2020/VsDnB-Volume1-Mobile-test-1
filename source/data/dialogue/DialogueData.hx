package data.dialogue;

import json2object.JsonWriter;

/**
 * The data that defines the dialogue that happens before a song starts.
 */
class DialogueData
{
    /**
     * The semantic version number for this data object.
     */
    public var version:String;
    
    /**
     * The asset path for the music that's used for the dialogue.
     * If `null` is provided, no music will be played.
     */
    @:optional
    public var music:Null<String>;

    /**
     * The amount of time (in seconds) to fade in the music.
     * If `0`, or `null` is provided, there'll be no fade-in. 
     */
    @:default(1)
    @:optional
    public var fadeInTime:Null<Float>;

    /**
     * The amount of time (in seconds) to fade the music out.
     * If `0`, or `null` is provided, there'll be no fade-in. 
     */
    @:default(0.5)
    @:optional
    public var fadeOutTime:Null<Float>;

    /**
     * A list of all speaker dialogue that happens.
     */
    public var dialogue:Array<DialogueEntryData>;

    public function new() {}
     
    /**
     * Serializes this SpeakerData object into a json string.
     * @return A SpeakerData JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<DialogueData> = new JsonWriter<DialogueData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }
}

/**
 * Defines the data that goes into a dialogue entry, or character speaking.
 */
typedef DialogueEntryData = 
{
    /**
     * The id of the speaker used in this entry.
     */
    public var speaker:String;

    /**
     * The expression the speaker should use.
     * This is optional for speakers that aren't meant to speak at all. (Example: `generic`)
     */
    public var ?expression:String;

    /**
     * The localization key that contains the text that'll be gradually typed by this speaker.
     */
    @:default('')
    public var text:String;

    /**
     * The speed at which the text will be typed out. This can be done for if you want to give personality
     * to the current speaker, and emphasize how they talk
     */
    @:default(0.04)
    @:optional
    public var typeSpeed:Float;

    /**
     * The side of the dialogue box the speaker is on when talking.
     * Normally, this is either `left`, `middle`, or `right`
     * 
     * However you could technically put in a custom side and use a script to further control the side.
     */
    public var side:String;

    /**
     * An optional parameter used to allow for custom behavior for when this entry happens.
     * User can set this value and extend the dialogue via scripts to allow for when a dialogue entry is this modifier.
     */
    public var ?modifier:Null<String>;

    /**
     * Optional position offsets that's able to be provided for when the dialogue reaches this entry.
     */
    @:default([0, 0])
    @:optional
    public var ?offsets:Array<Float>;
}