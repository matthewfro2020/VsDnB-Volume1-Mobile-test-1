package data.dialogue;

import json2object.JsonWriter;
import data.animation.Animation.AnimationData;

class SpeakerData
{
    /**
     * Semantic version for migrations.
     */
    @:default("1.0.0")
    public var version:String;

    /**
     * Readable name of the speaker.
     */
    public var name:String;

    /**
     * Base position offsets for the speaker.
     */
    @:default([0, 0])
    public var globalOffsets:Array<Float>;

    /**
     * Dialogue sound list.
     */
    @:default([])
    public var sounds:Array<String>;

    /**
     * Expressions (idle, happy, angry, etc.)
     */
    @:default([])
    public var expressions:Array<SpeakerExpressionData>;

    public function new() {}

    /**
     * Serialize into JSON.
     */
    public function serialize():String
    {
        var writer = new JsonWriter<SpeakerData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, "  ");
    }
}

/**
 * Data definition for an expression.
 */
typedef SpeakerExpressionData =
{
    /** Name / ID of the expression */
    public var name:String;

    /** Path to PNG or atlas folder */
    public var assetPath:String;

    /** Animation data (optional) */
    @:optional
    public var ?animation:AnimationData;

    /** Scaling */
    @:default(1)
    public var scale:Float;

    /** Anti-alias toggle */
    @:default(true)
    @:optional
    public var ?antialiasing:Bool;

    /** Offset applied ONLY for this expression */
    @:default([0, 0])
    @:optional
    public var ?offsets:Array<Float>;
}
