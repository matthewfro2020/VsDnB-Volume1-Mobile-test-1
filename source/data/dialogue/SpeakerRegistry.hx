package data.dialogue;

import json2object.JsonParser;
import data.dialogue.SpeakerData;
import play.dialogue.Speaker;

// 🚨 IMPORTANT: BaseRegistry sometimes returns FlxSprite-based scripted entries.
// We REMOVE ALL SCRIPTED SUPPORT and FORCE ONLY FlxZSprite Speakers.

class SpeakerRegistry
{
    public static var instance(get, never):SpeakerRegistry;
    static var _instance:SpeakerRegistry;
    static function get_instance():SpeakerRegistry
    {
        if (_instance == null)
            _instance = new SpeakerRegistry();
        return _instance;
    }

    // Storage
    var speakers:Map<String, Speaker>;
    var dataStore:Map<String, SpeakerData>;

    public function new()
    {
        speakers = new Map();
        dataStore = new Map();
    }

    /** Loads JSON and returns SpeakerData */
    public function parseEntryData(id:String):SpeakerData
    {
        var parser = new JsonParser<SpeakerData>();
        parser.ignoreUnknownVariables = true;

        var file = Paths.getText('data/speakers/$id.json');
        if (file == null) return null;

        parser.fromJson(file, id);

        if (parser.errors.length > 0)
            trace(parser.errors);

        return parser.value;
    }

    /** The ONLY correct way to fetch a speaker. */
    public function fetchEntry(id:String):Speaker
    {
        // Already created?
        if (speakers.exists(id))
            return speakers[id];

        // Load JSON
        var data = parseEntryData(id);
        if (data == null)
            return null;

        // Construct Speaker (ALWAYS FlxZSprite-based)
        var speaker = new Speaker(data);

        speakers[id] = speaker;
        dataStore[id] = data;

        return speaker;
    }
}
