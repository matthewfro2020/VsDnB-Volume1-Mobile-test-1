package data.dialogue;

import play.dialogue.ScriptedSpeaker;
import json2object.JsonParser;
import play.dialogue.Speaker;

class SpeakerRegistry extends BaseRegistry<Speaker, SpeakerData>
{
    public static var VERSION:thx.semver.Version = '1.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):SpeakerRegistry;
    static var _instance:SpeakerRegistry;

    static function get_instance():SpeakerRegistry
    {
        if (_instance == null)
            _instance = new SpeakerRegistry();
        return _instance;
    }

    public function new()
    {
        super("SpeakerRegistry", "speakers", VERSION_RULE);
    }

    //------------------------------------------------------------------
    // PARSES THE JSON DATA FOR SPEAKER DEFINITIONS
    //------------------------------------------------------------------

    public function parseEntryData(id:String):SpeakerData
    {
        var parser = new JsonParser<SpeakerData>();
        parser.ignoreUnknownVariables = true;

        switch (loadEntryFile(id))
        {
            case {fileName: fileName, contents: contents}:
                parser.fromJson(contents, fileName);
            default:
                return null;
        }

        if (parser.errors.length > 0)
            printErrors(parser.errors);

        return parser.value;
    }

    //------------------------------------------------------------------
    // THIS IS THE IMPORTANT PART:
    // ALWAYS RETURNS A SPEAKER OBJECT (FlxZSprite)
    //------------------------------------------------------------------

    public function fetchEntry(id:String):Speaker
    {
        var data = parseEntryData(id);
        if (data == null)
            return null;

        // Creates a new Speaker instance based on the ID
        return new Speaker(id);
    }

    //------------------------------------------------------------------
    // SCRIPTED SPEAKERS (for dialogue scripts)
    //------------------------------------------------------------------

    function createScriptedEntry(clsName:String):Speaker
    {
        return ScriptedSpeaker.init(clsName, "generic");
    }

    function getScriptedClasses():Array<String>
    {
        return ScriptedSpeaker.listScriptClasses();
    }
}
