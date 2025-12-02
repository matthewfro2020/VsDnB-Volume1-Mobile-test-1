package data.dialogue;

import openfl.utils.Assets;
import json2object.JsonParser;
import play.dialogue.Dialogue;
import play.dialogue.ScriptedDialogue;

class DialogueRegistry extends BaseRegistry<Dialogue, DialogueData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):DialogueRegistry;

    static function get_instance():DialogueRegistry
    {
        if (_instance == null) 
            _instance = new DialogueRegistry();
        return _instance;
    }

    static var _instance:DialogueRegistry;
    
    public function new()
    {
        super('DialogueRegistry', 'dialogue', VERSION_RULE);
    }

    public function parseEntryData(id:String):DialogueData
    {
        var parser:JsonParser<DialogueData> = new JsonParser<DialogueData>();
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

    function createScriptedEntry(clsName:String):Dialogue
    {
        return ScriptedDialogue.init(clsName, 'generic');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedDialogue.listScriptClasses();
    }
}