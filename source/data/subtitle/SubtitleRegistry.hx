package data.subtitle;

import data.subtitle.SubtitleData.SongSubtitleData;
import json2object.JsonParser;
import play.subtitle.SubtitleManager;
import play.subtitle.ScriptedSubtitleManager;

class SubtitleRegistry extends BaseRegistry<SubtitleManager, SongSubtitleData>
{
    public static var VERSION:thx.semver.Version = '2.0.0';
    public static var VERSION_RULE:thx.semver.VersionRule = '>=2.0.0 <2.1.0';

    public static var instance(get, never):SubtitleRegistry;

    static function get_instance():SubtitleRegistry
    {
        if (_instance == null) 
            _instance = new SubtitleRegistry();
        return _instance;
    }

    static var _instance:SubtitleRegistry;
    
    public function new()
    {
        super('SubtitleRegistry', 'subtitles', VERSION_RULE);
    }

    public function parseEntryData(id:String):SongSubtitleData
    {
        var parser:JsonParser<SongSubtitleData> = new JsonParser<SongSubtitleData>();
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

    function createScriptedEntry(clsName:String):SubtitleManager
    {
        return ScriptedSubtitleManager.init(clsName, 'subtitle');
    }

    function getScriptedClasses():Array<String>
    {
       return ScriptedSubtitleManager.listScriptClasses();
    }
}