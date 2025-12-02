package data.dialogue;

import json2object.JsonWriter;
import data.animation.Animation.AnimationData;

class SpeakerData
{
    /**
     * The semantic version of this SpeakerData object.
     */
    public var version:String;

    /**
     * The name of this speaker.
     */
    public var name:String;

    /**
     * position offsets that are applied to this speaker when they're talking.
     */
    @:default([0, 0])
    public var globalOffsets:Array<Float>;

    /**
     * A list of sound asset paths to play at random while the character is talking.
     */
    public var sounds:Array<String>;

    /**
     * A list of all of this character's expressions as they're talking.
     */
    @:default([])
    public var expressions:Array<SpeakerExpressionData>;


    public function new() {}
    
    /**
     * Serializes this SpeakerData object into a json string.
     * @return A SpeakerData JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<SpeakerData> = new JsonWriter<SpeakerData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }
}

/**
 * A type that defines the data that goes into a speaker's expression.
 */
typedef SpeakerExpressionData = 
{
    /**
     * The name/id of this expression.
     * This is what'll be used to retrieve this data.
     */
    public var name:String;
    
    /**
     * The asset path of the expression.
     */
    public var assetPath:String;

    /**
     * An optional parameter allowing to make the expression animated.
     */
    public var ?animation:AnimationData;

    /**
     * How much the speaker will be scaled when they're this expression.
     */
    @:default(1)
    public var scale:Float;

    /**
     * Whether this expression should have antialiasing.
     */
    @:default(true)
    public var ?antialiasing:Bool;

    /**
     * Position offsets that'll be used when the speaker is on this expression.
     */
    @:default([0, 0])
    public var ?offsets:Array<Float>;
}