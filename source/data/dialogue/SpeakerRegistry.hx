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
        super('SpeakerRegistry', 'speakers', VERSION_RULE);
    }

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

    // 🔥 ALWAYS RETURN A FLXZSPRITE-BASED SPEAKER
    override public function createEntryFromData(id:String, data:SpeakerData):Speaker
    {
        return new Speaker(data);
    }

    // 🔥 Make sure scripted fallback returns a FlxZSprite speaker
    function createScriptedEntry(clsName:String):Speaker
    {
        var data = new SpeakerData();
        data.name = clsName;
        data.globalOffsets = [0, 0];
        data.sounds = [];
        data.expressions = [];
        return new Speaker(data);
    }

    function getScriptedClasses():Array<String>
    {
        return ScriptedSpeaker.listScriptClasses();
    }
}

