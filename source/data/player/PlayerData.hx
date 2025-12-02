package data.player;

import json2object.JsonWriter;
import data.animation.Animation.AnimationData;

class PlayerData
{
    /**
     * The semantic version number for this data object.
     */
    public var version:String;
    
    /**
     * The name of this playable character.
     */
    public var name:String;

    /**
     * The character id associated with this.
     */
    public var charId:String;
    
	/**
	 * The id of the variation this character uses.
	 */
    @:default('')
	public var variationId:String;

    /**
     * The data for the character select
     */
    public var charSelect:PlayerCharacterSelectData;

    /**
     * Whether this character is unlocked, or not.
     */
    @:default(true)
    public var unlocked:Bool = true;
    
    /**
     * Initalizes a new Player data object.
     * @param name The name of the playable character.
     * @param The id of the character.
     * @param The variation this represents.
     */
    public function new(name:String, char:String, variation:String = '')
    {
        this.name = name;
        this.charId = char;
        this.variationId = variation;
    }

    /**
     * Serializes this Player data object into a json string.
     * @return A PlayerData JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<PlayerData> = new JsonWriter<PlayerData>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }
}

typedef PlayerCharacterSelectData = 
{
	/**
	 * The asset name for this portrait.
	 */
	public var portraitFile:String;
    
	/**
	 * The gf character id used for when this portrait is selected.
	 */
	public var gf:String;

    /**
     * A zero-indexed integer that represents the page that this player is on.
     * The user is able to go down through the bottom characters to switch a page, and any character with this page number will show.
     * 
     * A page is able to have 9 slots.
     */
    @:default(0)
    public var page:Int;

    /**
     * A zero-indexed integer that determines the character portrait's grid based position.
     * In the case where there' multiple of the same, this'll be incremented (as well as the page) until there's a free space.
     */
    public var position:Int;

	/**
	 * The idle animation used for when the portrait is selected.
	 */
	public var selected:AnimationData;
    
	/**
	 * The transition animation that's played when the portrait is selected.
	 */
	public var selectedTransition:AnimationData;
    
	/**
	 * The idle animation used for when the portrait isn't being selected.
	 */
	public var unselected:AnimationData;
    
	/**
	 * The transition animation that's played when the portrait is de-selected.
	 */
	public var unselectedTransition:AnimationData;
}