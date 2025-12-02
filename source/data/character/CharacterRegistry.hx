package data.character;

import json2object.JsonParser;
import openfl.utils.Assets;
import play.character.Character;
import play.character.ScriptedCharacter;

class CharacterRegistry extends BaseRegistry<Character, CharacterData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):CharacterRegistry;

    static function get_instance():CharacterRegistry
    {
        if (_instance == null)
            _instance = new CharacterRegistry();

        return _instance;
    }

    static var _instance:CharacterRegistry;

    /**
     * Maps out a list of all of the characters and their related script classes.
     */
    var characterScriptClasses:Map<String, String> = [];

    /**
     * A list meant for caching the data for each data.
     * Populated as all entries are being loaded.
     */
    var characterDataCache:Map<String, CharacterData> = [];

    
    public function new()
    {
        super('CharacterRegistry', 'characters', VERSION_RULE);
    }
    
    public override function loadEntries():Void
    {
        // Get a list of all of the entries from this registry's folder.
        var entryIds:Array<String> = DataAssets.listAssetsFromPath(dataFolder, fileType);

        // Cache all of the character entry data.
        for (entry in entryIds)
        {
            var charData:Null<CharacterData> = parseEntryData(entry);
            if (charData != null)
            {
                characterDataCache.set(entry, charData);
            }
        }

        var scriptedClasses:Array<String> = getScriptedClasses();

        // Create entries from all of the scripted classes.
		for (cls in scriptedClasses)
        {
			var scriptedEntry:Character = createScriptedEntry(cls);

			if (scriptedEntry != null)
			{
                characterScriptClasses.set(scriptedEntry.id, cls);
			}
            else
            {
                log('Error while creating scripted entry with the class ${cls}');
            }
            scriptedEntry.destroy();
            scriptedEntry = null;
		}
        log('Parsed ${entryIds.length} entries (${characterScriptClasses.size()} scripted, ${entryIds.length - characterScriptClasses.size()} unscripted)');
    }

    /**
     * Retrieves a new Character instance, that's ready to be added.
     * @param id The id of the character to retrieve.
     * @return A `Character` instance ready to be added.
     */
    public override function fetchEntry(id:String):Character
    {
        var charScriptClass:Null<String> = characterScriptClasses.get(id);
        var charData:Null<CharacterData> = characterDataCache.get(id);
        var char:Character = null;

        // This character is a scripted class.
        if (charScriptClass != null && charData != null)
        {
            char = createScriptedEntry(charScriptClass);
        }
        else
        {
            char = createEntry(id);
        }
        return char;
    }

    /**
     * Fetches the given character id's data.
     * @param id The id of the character to get the data for.
     * @return A `CharacterData`
     */
    public function fetchData(id:String):CharacterData
    {
        return characterDataCache.exists(id) ? characterDataCache.get(id) : null;
    }

    public function parseEntryData(id:String):CharacterData
    {
        var parser:JsonParser<CharacterData> = new JsonParser<CharacterData>();
        parser.ignoreUnknownVariables = true;

        switch (loadEntryFile(id))
        {
            case {fileName: fileName, contents: contents}:
                parser.fromJson(contents, fileName);
            default:
                return null;
        }
        if (parser.errors.length > 0)
        {
            printErrors(parser.errors);
        }
        return parser.value; 
    }

    function createScriptedEntry(clsName:String):Character
    {
        return ScriptedCharacter.init(clsName, 'bf');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedCharacter.listScriptClasses();
    }
}