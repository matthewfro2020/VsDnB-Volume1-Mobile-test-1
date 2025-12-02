package play.player;

import data.player.PlayerRegistry;
import data.player.PlayerData;
import data.IRegistryEntry;

class PlayableCharacter implements IRegistryEntry<PlayerData>
{
	/**
	 * The id of this playable character.
	 */
	public final id:String;

    /**
     * The data for this playable character.
     */
    public final data:PlayerData;


    /**
     * The readable name of this playable character.
     */
    public var name(get, never):String;

    function get_name():String
    {
        return data?.name ?? 'Unknown Name';
    }

    /**
     * The id of the general character of this playable character.
     */
    public var characterId(get, never):String;
    
    function get_characterId():String
    {
        return data?.charId ?? 'bf';
    }

    /**
     * The variation for this playable character.
     */
    public var variationId(get, never):String;
    
    function get_variationId():String
    {
        return data?.variationId ?? '';
    }

    /**
     * The page this character will be on in the character select.
     */
    public var page(get, never):Int;
    
    function get_page():Int
    {
        return getCharSelectData()?.page ?? 0;
    }

    /**
     * The grid-indexed position this character will be on in the character select.
     */
    public var position(get, never):Int;

    function get_position():Int
    {
        return getCharSelectData()?.position ?? 0;
    }
    
	public function new(id:String)
    {
		this.id = id;

        data = fetchData(id);
	}

    public function destroy() {}

    public function toString():String
    {
        return 'PlayableCharacter(${id})';
    }
    
    public function fetchData(id:String):PlayerData
    {
        return PlayerRegistry.instance.parseEntryDataWithMigration(id);
    }
    
    public function getCharSelectData():PlayerCharacterSelectData
    {
        return data?.charSelect ?? null;
    }

    public function isUnlocked():Bool
    {
        return data?.unlocked ?? true;
    }
}