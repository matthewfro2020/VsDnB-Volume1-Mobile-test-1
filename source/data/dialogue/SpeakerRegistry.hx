package data.dialogue;

import play.dialogue.ScriptedSpeaker;
import openfl.utils.Assets;
import json2object.JsonParser;
import play.dialogue.Speaker;
import play.dialogue.ScriptedDialogue;

class SpeakerRegistry extends BaseRegistry<Speaker, SpeakerData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):SpeakerRegistry;

    static function get_instance():SpeakerRegistry
    {
        if (_instance == null) 
            _instance = new SpeakerRegistry();
        return _instance;
    }

    static var _instance:SpeakerRegistry;
    
    public function new()
    {
        super('SpeakerRegistry', 'speakers', VERSION_RULE);
    }

    public function parseEntryData(id:String):SpeakerData
    {
        var parser:JsonParser<SpeakerData> = new JsonParser<SpeakerData>();
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

    function createScriptedEntry(clsName:String):Speaker
    {
        return ScriptedSpeaker.init(clsName, 'generic');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedSpeaker.listScriptClasses();
    }
}