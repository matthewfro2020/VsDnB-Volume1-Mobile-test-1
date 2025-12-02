package data.stage;

import openfl.utils.Assets;
import json2object.JsonParser;
import play.stage.ScriptedStage;
import play.stage.Stage;

class StageRegistry extends BaseRegistry<Stage, StageData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';
    
    public static var instance(get, never):StageRegistry;

    static function get_instance():StageRegistry
    {
        if (_instance == null) 
            _instance = new StageRegistry();
        return _instance;
    }

    static var _instance:StageRegistry;
    
    public function new()
    {
        super('StageRegistry', 'stages', VERSION_RULE);
    }

    public function parseEntryData(id:String):StageData
    {
        var parser:JsonParser<StageData> = new JsonParser<StageData>();
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

    function createScriptedEntry(clsName:String):Stage
    {
        return ScriptedStage.init(clsName, 'stage');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedStage.listScriptClasses();
    }
}