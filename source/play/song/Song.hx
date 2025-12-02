package play.song;

import data.song.SongRegistry;
import data.IRegistryEntry;
import flixel.FlxG;
import data.song.SongData.SongSection;
import data.song.SongData.SongTimeChange;
import data.song.SongData.SongMetadata;
import data.song.SongData.SongChartData;
import scripting.IScriptedClass.IPlayStateScriptedClass;
import scripting.events.ScriptEvent;

import util.tools.Preloader;

/**
 * An object that holds all of the data, and playable information for a song. 
 */
class Song implements IRegistryEntry<SongMetadata> implements IPlayStateScriptedClass
{
    public static final DEFAULT_VARIATION:String = 'default';

    /**
     * The id of this song.
     */
    public final id:String;

    /**
     * The metadata for the default/original variation for this song.
     */
    var _data:SongMetadata;

    /**
     * Contains a mapping of all of the metadata for the song's variations.
     * 
     * `String` (Variation) -> `SongMetadata` (The variation's metadata)
     */
    var _metadata:Map<String, SongMetadata> = new Map<String, SongMetadata>();
    
    /**
     * A list of all of the playable charts for this song.
     * 
     * `String` (Variation) -> `SongPlayChart` (The variation's SongPlayChart)
     */
    var charts:Map<String, SongPlayChart> = new Map<String, SongPlayChart>();

    /**
     * The readable name of the song.
     */
    public var songName(get, never):String;

    function get_songName():String
    {
        if (_data == null) return 'Unknown Name';
        return _data.songName;
    }
    
    /**
     * A list of all of the composers who made this song.
     */
    public var songComposers(get, never):Array<String>;

    function get_songComposers():Array<String>
    {
        if (_data == null) return ['Unknown Composers'];
        return _data.composers;
    }

    /**
     * All of the artists who worked on this song.
     */
    public var songArtists(get, never):Array<String>;

    function get_songArtists():Array<String>
    {
        if (_data == null) return ['Unknown Artists'];
        return _data.artists;
    }
    
    /**
     * All of the people who charted this song.
     */
    public var songCharters(get, never):Array<String>;

    function get_songCharters():Array<String>
    {
        if (_data == null) return ['Unknown Charters'];
        return _data.charters;
    }

    /**
     * All of the people who charted this song.
     */
    public var songCoders(get, never):Array<String>;

    function get_songCoders():Array<String>
    {
        if (_data == null) return ['Unknown Coders'];
        return _data.coders;
    }

    /**
     * Whether the score for this song's able to be saved.
     */
    public var validScore:Bool;

    public function new(id:String)
    {
        this.id = id;
        
        _data = fetchData(id);

        if (_data == null)
        {
            throw 'No Song data was found with an id of ${id}';
        }
        _metadata = [DEFAULT_VARIATION => _data];

        // Load all of the variations that this song has.
        for (variation in _data.variations)
        {
            var variationMetadata:SongMetadata = SongRegistry.instance.loadMetadataFile(id, variation);

            if (variationMetadata != null)
            {
                _metadata.set(variation, variationMetadata);
            }
            else
            {
                FlxG.log.warn('There was an error prasing the metadata file for variation: ${variation}');
            }
        }
        populateMetadataCharts();

        validScore = true;
    }

    /**
     * Fetches the metadata of this object.
     * @param id The id of this entry object.
     * @return The metadata to use for this data structure.
     */
    public function fetchData(id:String):SongMetadata
    {
        return SongRegistry.instance.parseEntryData(id);
    }

    /**
     * Destroys this object.
     * This should ONLY be used when this is being cleared from the registry. Destroying this outside of it can easily cause a crash.
     * Used to free up memory.
     */
    public function destroy():Void
    {
        _data = null;

        for (key in _metadata.keys())
        {
            _metadata.set(key, null);
        }
        _metadata.clear();
        _metadata = null;
        
        for (key in charts.keys())
        {
            charts.set(key, null);
        }
        charts.clear();
    }

    /**
     * Returns a string representation of this object.
     * @return A string used for debugging.
     */
    public function toString():String
    {
        return 'Song(id=$id)';
    }

    /**
     * Retrieves a playable chart from a given variation id.
     * @param variationId The variation to get the chart for.
     * @return The chart for this variation. Falls back to the default variation if none exist.
     */
    public function getChart(?variationId:String):SongPlayChart
    {
        return charts?.get(variationId) ?? charts?.get(DEFAULT_VARIATION) ?? null;
    }

    /**
     * Does a playable variation chart exist for the given id?
     * @param variationId The variation id to check.
     * @return Whether this song has a variation chart for the given id.
     */
    public function hasChart(?variationId:String):Bool
    {
        variationId ??= DEFAULT_VARIATION;
        return charts.exists(variationId);
    }

    /**
     * Populates this data structure with the charts it contains.
     */
    function populateMetadataCharts():Void
    {
        for (variation => metadata in _metadata)
        {
            var chartData:SongChartData = SongRegistry.instance.loadChartDataFile(this.id, variation);

            var playChart:SongPlayChart = new SongPlayChart(this, variation);
            playChart.songName = metadata.songName;

            playChart.songComposers = metadata.composers;
            playChart.songArtists = metadata.artists;
            playChart.songCharters = metadata.charters;
            playChart.songCharters = metadata.charters;
            playChart.songCoders = metadata.coders;

            playChart.player = metadata.player;
            playChart.opponent = metadata.opponent;
            playChart.girlfriend = metadata.girlfriend;
            playChart.timeChanges = metadata.timeChanges;
            
            playChart.stage = metadata.stage;

            playChart.speed = chartData.speed;
            playChart.notes = chartData.notes;
            playChart.validScore = (variation == DEFAULT_VARIATION);

            charts.set(variation, playChart);
        }
    }

    /**
     * Retrieves a list of all the variation ids available for this song.
     * @return A `Array<String>`
     */
    public function listVariationIds():Array<String>
    {
        return [for (variation in _metadata.keys()) variation];
    }

    /**
     * Validates the given variation to that it's able to be used when retrieving it for files.
     * @param variation The variation to validate.
     * @return A validated variation.
     */
    public static function validateVariationPath(?variation:String):String
    {
        return [DEFAULT_VARIATION, '', null].contains(variation) ? '' : '-$variation';
    }

    /**
     * Validates the given variation so it isn't null.
     * @param variation The variation to validate.
     * @return A new variation `String`
     */
    public static function validateVariation(?variation:String):String
    {
        return [DEFAULT_VARIATION, '', null].contains(variation) ? DEFAULT_VARIATION : variation;
    }
    
    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}

    public function onUpdate(event:UpdateScriptEvent):Void {}

    public function onDestroy(event:ScriptEvent):Void {}
	
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}

    public function onStepHit(event:ConductorScriptEvent):Void {}

    public function onBeatHit(event:ConductorScriptEvent):Void {}

    public function onMeasureHit(event:ConductorScriptEvent):Void {}
    
    public function onTimeChangeHit(event:ConductorScriptEvent):Void {}

    public function onCreatePost(event:ScriptEvent):Void {}

    public function onCreateUI(event:ScriptEvent):Void {}

    public function onSongStart(event:ScriptEvent):Void {}

    public function onSongLoad(event:ScriptEvent):Void {}

    public function onSongEnd(event:ScriptEvent):Void {} 

    public function onPause(event:ScriptEvent):Void {}

    public function onResume(event:ScriptEvent):Void {}

    public function onPressSeven(event:ScriptEvent):Void {}
    
    public function onGameOver(event:ScriptEvent):Void {}

    public function onCountdownStart(event:CountdownScriptEvent):Void {}

    public function onCountdownTick(event:CountdownScriptEvent):Void {}

    public function onCountdownTickPost(event:CountdownScriptEvent):Void {}
    
    public function onCountdownFinish(event:CountdownScriptEvent):Void {}

    public function onCameraMove(event:CameraScriptEvent):Void {}

    public function onCameraMoveSection(event:CameraScriptEvent):Void {}
    
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void {}
    
    public function onNoteSpawn(event:NoteScriptEvent):Void {}

    public function onOpponentNoteHit(event:NoteScriptEvent):Void {}
    
    public function onPlayerNoteHit(event:NoteScriptEvent):Void {}

    public function onNoteMiss(event:NoteScriptEvent):Void {}
    
    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void {}
}

/**
 * An object used to store the information for a variation's metadata, and chart.
 * This is the main structure used for gameplay, and is used to keep track of a different variation's data information, if it exists.
 */
class SongPlayChart
{
    /**
     * The parent song of this chart.
     */
    final song:Song;

    /**
     * The variation of this chart.
     */
    final variation:String;
    
    public var songName:String;

    public var songComposers:Array<String>;
    public var songArtists:Array<String>;
    public var songCharters:Array<String>;
    public var songCoders:Array<String>;
    
    public var stage:String;

    public var player:String;
    public var opponent:String;
    public var girlfriend:String;

    public var timeChanges:Array<SongTimeChange>;

    public var speed:Float;
    public var notes:Array<SongSection>;

    public var validScore:Bool;

    public function new(song:Song, ?variationId:String)
    {
        this.song = song;
        this.variation = variationId;
    }

    /**
     * Caches this chart's instrumental to prepare to be used.
     */
    public function cacheInstrumental():Void
    {
        Preloader.cacheSound(getInstrumentalPath());
    }

    /**
     * Caches the chart's vocals to prepare to be used.
     */
    public function cacheVocals():Void
    {
        Preloader.cacheSound(getVoicesPath());
    }

    /**
     * Gets the instrumental path for this chart.
     * @return The instrumental asset path.
     */
    public function getInstrumentalPath():String
    {
        return Paths.instPath(song.id, variation);
    }

    /**
     * Retrieves the asset path for the vocals of this chart.
     * @return The vocals asset path.
     */
    public function getVoicesPath():String
    {
        return Paths.voicesPath(song.id, variation);
    }
}