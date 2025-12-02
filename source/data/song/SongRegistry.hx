package data.song;

import util.VersionUtil;
import data.song.SongData.SongChartData;
import data.song.SongData.SongMetadata;
import data.song.SongData.SongMusicData;
import json2object.JsonParser;
import openfl.utils.Assets;
import play.song.ScriptedSong;
import play.song.Song;
import thx.semver.Version;

class SongRegistry extends BaseRegistry<Song, SongMetadata>
{
    public static var METADATA_VERSION:thx.semver.Version = '2.0.0';
    public static var METADATA_VERSION_RULE:thx.semver.VersionRule = '2.0.x';
    
    public static var CHART_DATA_VERSION:thx.semver.Version = '2.0.0';
    public static var CHART_DATA_VERSION_RULE:thx.semver.VersionRule = '2.0.x';

    public static var MUSIC_DATA_VERSION:thx.semver.Version = '1.0.0';
    public static var MUSIC_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

    public static var instance(get, never):SongRegistry;

    static function get_instance():SongRegistry
    {
        if (_instance == null)
            _instance = new SongRegistry();

        return _instance;
    }

    static var _instance:Null<SongRegistry> = null;

    public function new()
    {
        super('SongRegistry', 'songs', METADATA_VERSION_RULE, '-metadata.json');
    }

    function createScriptedEntry(cls:String):Song
    {
        return ScriptedSong.init(cls, 'house');
    }

    function getScriptedClasses():Array<String>
    {
        return ScriptedSong.listScriptClasses();
    }

    public function parseEntryData(id:String):SongMetadata
    {
        return loadMetadataFile(id);
    }
    
    /**
     * Reads the contents of a metadata file given it's entry id and variation.
     * @param id The id of the entry.
     * @param variation The variation of the metadata to load.
     */
    public function readMetadataEntryFile(id:String, ?variation:String)
    {
        var path:String = 'songs/$id/$id';

        var filePath:String = Paths.json('${path}-metadata${Song.validateVariationPath(variation)}');
        var contents:String = Assets.getText(filePath);

        return {fileName: filePath, contents: contents};
    }
    
    /**
     * Retrieves the semantic version number of a metadata entry from it's id.
     * @param id The id of the entry.
     * @return The entry's version.
     */
    public function fetchEntryMetadataVersion(id:String, ?variation:String):Version
    {
        var entryContents:String = readMetadataEntryFile(id, variation).contents;
        return VersionUtil.getVersionFromJSON(entryContents);
    }

    /**
     * Reads, and parses a metadata file from a given entry's id.
     * @param id The id of the entry.
     * @param variation The variation of the entry to get the metadata for.
     * @return The metadata file for this entry.
     */
    public function loadMetadataFile(id:String, ?variation:String):SongMetadata
    {
        var parser = new JsonParser<SongMetadata>();
        parser.ignoreUnknownVariables = true;
        
        switch (readMetadataEntryFile(id, variation))
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
    
    /**
     * Reads the contents of a chart data file given it's entry id and variation.
     * @param id The id of the entry.
     * @param variation The variation of the metadata to load.
    */
    public function readChartEntryFile(id:String, ?variation:String, ?suffix:String)
    {
        var path:String = 'songs/$id/$id';

        var filePath:String = Paths.json('${path}${suffix != null ? '-$suffix' : ''}-chart${Song.validateVariationPath(variation)}');
        var contents:String = Assets.getText(filePath).trim();

        return {fileName: filePath, contents: contents};
    }

    /**
     * Reads, and parses the chart file from a given entry's id.
     * @param id The id of the entry.
     * @param variation The variation of the entry to get the chart for.
     * @param suffix (Optional) An additional suffix to use when retrieving the chart file.
     * @return The chart data for this entry.
     */
    public function loadChartDataFile(id:String, ?variation:String, ?suffix:String):SongChartData
    {
        var parser = new JsonParser<SongChartData>();
        parser.ignoreUnknownVariables = true;
        
        switch (readChartEntryFile(id, variation, suffix))
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

    /**
     * Retrieves the semantic version number of the entry chart data from it's id.
     * @param id The id of the entry.
     * @return The entry's version.
     */
    public function fetchEntryChartDataVersion(id:String, ?variation:String, ?suffix:String):Version
    {
        var entryContents:String = readChartEntryFile(id, variation, suffix).contents;
        return VersionUtil.getVersionFromJSON(entryContents);
    }
    
    /**
     * Checks if a music data file exists for the given path.
     * 
     * @param id The entry id of the music data file.
     * @param variation The variation of the music data file.
     * @return If the game was able to find a music data file, or not.
     */
    public function hasMusicDataFile(id:String, ?variation:String):Bool
    {
        var path:String = 'music/$id';
        var filePath:String = Paths.json('$path${Song.validateVariationPath(variation)}');

        return Assets.exists(filePath);
    }

    /** 
     * Reads the contents of a music data file given it's key, and additional parameters.
     * 
     * @param id The entry id of the music data file.
     * @param variation The variation of the music data file.
     */
    public function readMusicDataFile(id:String, ?variation:String)
    {
        var path:String = 'music/$id';

        var filePath:String = Paths.json('$path${Song.validateVariationPath(variation)}');
        var contents:String = Assets.getText(filePath).trim();

        return {fileName: filePath, contents: contents};
    }
    
    /**
     * Reads, and parses the music data file from the given parameters.
     * 
     * @param id The id of the entry.
     * @param variation The variation of the entry to get the chart for.
     * @return The chart data for this entry.
     */
    public function loadMusicDataFile(id:String, ?variation:String):SongMusicData
    {
        var parser = new JsonParser<SongMusicData>();
        parser.ignoreUnknownVariables = true;
        
        switch (readMusicDataFile(id, variation))
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
}