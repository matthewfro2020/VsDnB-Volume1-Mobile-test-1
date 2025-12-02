package data.player;

import play.player.ScriptedPlayableCharacter;
import play.player.PlayableCharacter;
import openfl.utils.Assets;
import json2object.JsonParser;
import play.stage.ScriptedStage;
import play.stage.Stage;

class PlayerRegistry extends BaseRegistry<PlayableCharacter, PlayerData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):PlayerRegistry;

    static function get_instance():PlayerRegistry
    {
        if (_instance == null) 
            _instance = new PlayerRegistry();
        return _instance;
    }

    static var _instance:PlayerRegistry;
    
    public function new()
    {
        super('PlayerRegistry', 'players', VERSION_RULE);
    }

    public function parseEntryData(id:String):PlayerData
    {
        var parser:JsonParser<PlayerData> = new JsonParser<PlayerData>();
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

    function createScriptedEntry(clsName:String):PlayableCharacter
    {
        return ScriptedPlayableCharacter.init(clsName, 'stage');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedPlayableCharacter.listScriptClasses();
    }
}