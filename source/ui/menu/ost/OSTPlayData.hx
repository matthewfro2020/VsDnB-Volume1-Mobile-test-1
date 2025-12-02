package ui.menu.ost;

import data.character.CharacterRegistry;
import data.song.SongRegistry;
import data.song.SongData.SongMusicData;
import data.song.SongData.SongTimeChange;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import play.song.Song;
import play.song.Song.SongPlayChart;
import ui.menu.freeplay.category.Category.CategorySong;

class OSTPlayData
{
    /**
     * The readable name of the song.
     */
    public var name:String;

    /**
     * The list of all the composers who worked on the song.
     */
    public var composers:Array<String>;
    
    /**
     * The icon to use for this play data.
     */
    public var icon:Null<String> = null;

    /**
     * The instrumental asset path for this play data.
     */
    public var instrumental:String;
    
    /**
     * (Optional) A vocals asset path to provide.
     */
    public var vocals:Null<String> = null;

    /**
     * The asset path for the vinyl asset (From `ost/vinyls`).
     */
    public var vinylPath:Null<String> = null;

    /**
     * A list of colors to use for the background.
     */
    public var colors:Array<FlxColor> = [];
    
    /**
     * A list of all time changes.
     */
    public var timeChanges:Array<SongTimeChange> = [];

    
    public function new() {}

    public function toString():String
    {
        return 'OSTPlayData(name=$name, composers=$composers)';
    }

    /**
     * Builds a list of OSTPlayData information from `CategorySong`
     * @param categorySong The category song to build off of.
     * @return A `Map<String, OSTPlayData>` that maps each `OSTPlayData` by variation.
     */
    public static function buildFromCategorySong(categorySong:CategorySong):Map<String, OSTPlayData>
	{
        var songPlayData:Map<String, OSTPlayData> = [];

        // This category song is an external song (meaning it's not playable), load it from a music data file.
		if (categorySong.external && SongRegistry.instance.hasMusicDataFile(categorySong.id))
		{
			// Retrieve the data for the default variation.
			var musicData:SongMusicData = SongRegistry.instance.loadMusicDataFile(categorySong.id);
			var playData:OSTPlayData = OSTPlayData.buildFromMusicData(musicData, categorySong.color, categorySong.icon, categorySong.vinylPath);
            
			songPlayData.set(Song.DEFAULT_VARIATION, playData);

			// Load music data for any other variations.
			for (variation in musicData.variations)
			{
				var variationMusicData:SongMusicData = SongRegistry.instance.loadMusicDataFile(categorySong.id, variation);
				var playData:OSTPlayData = OSTPlayData.buildFromMusicData(variationMusicData, categorySong.color, categorySong.icon, categorySong.vinylPath);

				songPlayData.set(variation, playData);
			}
		}
		else
		{

			var song:Song = SongRegistry.instance.fetchEntry(categorySong.id);
			var defaultPlayChart:SongPlayChart = song.getChart(Song.DEFAULT_VARIATION);

			var opponentColor:FlxColor = FlxColor.fromString(CharacterRegistry.instance.fetchData(defaultPlayChart.opponent).color);
			var playerColor:FlxColor = FlxColor.fromString(CharacterRegistry.instance.fetchData(defaultPlayChart.player).color);
			var playDataIcon:String = categorySong.icon ?? CharacterRegistry.instance.fetchData(defaultPlayChart.opponent).icon;

			var playData:OSTPlayData = OSTPlayData.buildFromPlayChart(song.getChart(Song.DEFAULT_VARIATION), [opponentColor, playerColor], playDataIcon, categorySong.vinylPath);

			songPlayData.set(Song.DEFAULT_VARIATION, playData);

            var altVariationsList:Array<String> = song.listVariationIds().filter((variation:String) -> {
                return variation != Song.DEFAULT_VARIATION;
            });
			for (variation in altVariationsList)
			{
				var playChart:SongPlayChart = song.getChart(variation);

				var opponentColor:FlxColor = FlxColor.fromString(CharacterRegistry.instance.fetchData(playChart.opponent).color);
				var playerColor:FlxColor = FlxColor.fromString(CharacterRegistry.instance.fetchData(playChart.player).color);
				var playDataIcon:String = CharacterRegistry.instance.fetchData(playChart.opponent).icon;

				var playData:OSTPlayData = OSTPlayData.buildFromPlayChart(song.getChart(variation), [opponentColor, playerColor], playDataIcon, categorySong.vinylPath);

				songPlayData.set(variation, playData);
			}
		}

        return songPlayData;
    }

    /**
     * Builds an `OSTPlayData` from a given `SongMusicData`.
     * 
     * @param musicData The music data to build from.
     * @param colors The colors to be used for the play data.
     * @param icon The icon that should be used. 
     * @return A `OSTPlayData`
     */
    public static function buildFromMusicData(musicData:SongMusicData, colors:Array<FlxColor>, ?icon:String, ?vinyl:String):OSTPlayData
    {
        var playData = new OSTPlayData();
        playData.name = musicData.name;
        playData.composers = musicData.composers;
        playData.icon = icon;
        playData.timeChanges = musicData.timeChanges;
        playData.instrumental = Paths.soundPath(musicData.musicPath, null, 'music/', MUSIC);
        playData.colors = colors;
        playData.vinylPath = vinyl;

        return playData;
    }
    
    /**
     * Builds an `OSTPlayData` from a given `SongPlayChart`.
     * 
     * @param chart The play chart to build from.
     * @param colors The colors to be used for the play data.
     * @param icon The icon that should be used. 
     * @return A `OSTPlayData`
     */
    public static function buildFromPlayChart(chart:SongPlayChart, colors:Array<FlxColor>, ?icon:String, ?vinyl:String):OSTPlayData
    {
        var playData = new OSTPlayData();
        playData.name = chart.songName;
        playData.composers = chart.songComposers;
        playData.icon = icon;
        playData.timeChanges = chart.timeChanges;
        playData.instrumental = chart.getInstrumentalPath();
        playData.vinylPath = vinyl;
        
        if (Assets.exists(chart.getVoicesPath()))
            playData.vocals = chart.getVoicesPath();
        
        playData.colors = colors;

        return playData;
    }
}