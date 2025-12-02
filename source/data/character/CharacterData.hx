package data.character;

import flixel.util.FlxColor;
import json2object.JsonWriter;

/**
 * A data structure that represents the normal data for a character.
 */
class CharacterData
{
    /**
     * The semantic version number for this data object.
     */
    public var version:Null<String>;

    /**
     * The readable name of this character.
     */
    @:default('Unknown')
    public var name:Null<String>;
    
    /**
     * How much this character is scaled.
     */
    @:default(1)
    public var scale:Null<Float>;

    /**
     * This character needs every `x` beats.
     */
    @:default(2)
    public var danceSnap:Null<Int>;
    
    /**
     * How much to offset the character's position globally.
     * Normally this is relative to BF's position so the characters are on the same bottom-center ground.
     */
    @:default([0, 0])
    public var globalOffset:Null<Array<Float>>;

    /**
     * How much to offset the character's camera position.
     */
    @:default([0, 0])
    public var cameraOffsets:Null<Array<Float>>;

    /**
     * The relative asset file to use for loading the character's offsets for if they're the player.
     * This'd normally default to the character's id path, but in-case the offset's organized you'd need to edit this.
     */
    @:default('bf')
    public var offsetFilePlayer:Null<String>;
    
    /**
     * The relative asset file to use for loading the character's offsets for when this character's the opponent.
     */
    @:default('bf')
    public var offsetFileOpponent:Null<String>;

    /**
     * The icon id to use for this character.
     */
    @:default('bf')
    public var icon:Null<String>;

    /**
     * How long the character should sing for, in terms of steps.
     */
    @:default(6)
    public var singDuration:Null<Float>;

    /**
     * The color that represents the character.
     */
    @:default("0xFFFFFF")
    public var color:Null<String>;

    /**
     * This character needs their LEFT, or RIGHT animations flipped/
     */
    @:default(false)
    @:optional
    public var nativelyPlayable:Null<Bool>;

    /**
     * Whether the character should be flipped around.
     */
    @:default(false)
    public var flipX:Null<Bool>;

    /**
     * Whether this character is pixelated, or not.
     */
    @:default(true)
    public var antialiasing:Null<Bool>;

    /**
     * The data relating for the character for the countdown.
     */
    public var countdownData:CharacterCountdownData;

    /**
     * Initalizes a new character data.
     * @param name The name of the character.
     */
    public function new(name:String)
    {
        this.name = name;
        validateData();
    }

    /**
     * Serializes this `CharacterData` object into a json string.
     * @return A StageData JSON string.
     */
    public function serialize():String
    {
        // Make sure the data's validated before writing.
        validateData();

        var writer:JsonWriter<CharacterData> = new JsonWriter<CharacterData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }

    /**
     * Validates all of the data of this structure to make sure there's no null values.
     */
    public function validateData():Void
    {
        if (version == null)
            version = data.character.CharacterRegistry.VERSION;

        if (name == null)
            name = 'Unknown';

        if (scale == null)
            scale = 1.0;

        if (danceSnap == null)
            danceSnap = 2;

        if (globalOffset == null)
            globalOffset = [0, 0];

        if (cameraOffsets == null)
            cameraOffsets = [0, 0];

        if (offsetFilePlayer == null)
            offsetFilePlayer = 'bf';

        if (offsetFileOpponent == null)
            offsetFileOpponent = 'bf';

        if (icon == null)
            icon = 'bf';
        
        if (singDuration == null)
            singDuration = 6.0;

        if (color == null)
            color = FlxColor.WHITE.toHexString(false);

        if (nativelyPlayable == null)
            nativelyPlayable = false;
        
        if (flipX == null)
            flipX = false;

        if (antialiasing == null)
            antialiasing = true;

        if (countdownData == null)
            countdownData = {graphicPath: 'normal', soundPath: 'default'}
    }
}

typedef CharacterCountdownData = 
{
    /**
     * The graphic asset path to use for this countdown.
     */
    @:default('normal')
    var graphicPath:String;
    
    /**
     * The sound asset path to use for the countdown if the character's starting it.
     */
    @:default('default')
    var soundPath:String;
}