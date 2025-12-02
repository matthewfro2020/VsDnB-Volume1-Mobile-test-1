package data.stage;

import json2object.JsonWriter;

/**
 * A data structure that holds the metadata information for a stage.
 */
class StageData
{
    /**
     * The readable name of the stage.
     */
    @:default('Unknown Stage')
    public var name:String;

    /**
     * The default camera zoom for this stage.
     */
    @:default(1)
    public var zoom:Float;

    /**
     * The player data information for this stage.
     */
    public var player:StageDataCharacter;

    /**
     * The opponent data information for this stage.
     */
    public var opponent:StageDataCharacter;

    /**
     * The gf data information for this stage.
     */
    public var gf:StageDataCharacter;

    /**
     * Initalize a new StageData object.
     * @param name The name of the stage.
     * @param zoom The camera zoom of the stage.
     */
    public function new(name:String, zoom:Float)
    {
        this.name = name;
        this.zoom = zoom;

        player = validateCharacterData('player');
        opponent = validateCharacterData('opponent');
        gf = validateCharacterData('gf');
    }

    /**
     * Serializes this StageData object into a json string.
     * @return A StageData JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<StageData> = new JsonWriter<StageData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }

    function validateCharacterData(type:String):StageDataCharacter
    {
        return switch (type)
        {
            case 'player': {zIndex: 102, position: [770, 450], scroll: [1, 1], cameraOffsets: [0, 0]}
            case 'opponent': {zIndex: 101, position: [100, 450], scroll: [1, 1], cameraOffsets: [0, 0]}
            case 'gf': {zIndex: 100, position: [400, 130], scroll: [1, 1], cameraOffsets: [0, 0]}
            default: null;
        }
    }
}

/**
 * A data structure that holds the data for a character in a stage.
 */
typedef StageDataCharacter = 
{
    /**
     * The layer order of the objects.
     */
    @:default(100)
    var zIndex:Int;

    /**
     * The character's position for the stage.
     */
    var position:Array<Float>;

    /**
     * The scroll factor for the character.
     */
    @:default([1, 1])
    var scroll:Array<Float>;

    /**
     * The camera offsets for this character.
     */
    @:default([0, 0])
    var cameraOffsets:Array<Float>;
}