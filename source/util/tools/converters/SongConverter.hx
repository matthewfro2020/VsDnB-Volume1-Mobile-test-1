package util.tools.converters;

import data.character.CharacterRegistry;
import data.song.SongRegistry;
import backend.Conductor;
import data.song.LeagacySongData.Song;
import data.song.LeagacySongData.SwagSong;
import data.song.SongData.SongChartData;
import data.song.SongData.SongMetadata;
import data.song.SongData.SongNoteData;
import data.song.SongData.SongTimeChange;
import data.song.SongData.SongSection;
import util.FileUtil;
import sys.io.File;

class SongConverter
{
    public static function migrate():Void
    {
        for (entry in SongRegistry.instance.listEntryIds())
        {
            var metadata = SongRegistry.instance.loadMetadataFile(entry);
            var chartData = SongRegistry.instance.loadChartDataFile(entry);

            metadata.version = '${SongRegistry.METADATA_VERSION}';
            metadata.coders = ["Unknown"];

            chartData.version = '${SongRegistry.CHART_DATA_VERSION}';
            
            FileUtil.createDirectory(Paths.data('generated/songs/$entry'));

            File.saveContent(Paths.data('generated/songs/${entry}/${entry}-metadata.json'), metadata.serialize());
            File.saveContent(Paths.data('generated/songs/${entry}/${entry}-chart.json'), chartData.serialize());
        }
    }

    public static function convert(id:String)
    {
        convertSong(Song.loadFromJson(id));
    }

    public static function convertSong(songData:SwagSong)
    {
        var metadata:SongMetadata = new SongMetadata(songData.song, ['Unknown Composer'], ['Unknown Artists'], ['Unknown Charters'], ['Unknown Coders']);
        metadata.version = SongRegistry.METADATA_VERSION;
        metadata.player = songData.player1 ?? 'bf';
        metadata.opponent = songData.player2 ?? 'dave';
        metadata.girlfriend = songData.gf ?? 'gf';
        
        metadata.stage = songData.stage ?? 'gf';
        metadata.variations = [];
        metadata.timeChanges = generateTimeChanges(songData);
        
        var chartData = new SongChartData(songData.speed, convertChart(songData));

        FileUtil.createDirectory(Paths.data('generated/${songData.song}'));
        
        File.saveContent(Paths.data('generated/${songData.song}/${songData.song}-metadata.json'), metadata.serialize());
        File.saveContent(Paths.data('generated/${songData.song}/${songData.song}-chart.json'), chartData.serialize());
    }

    static function generateTimeChanges(song:SwagSong):Array<SongTimeChange>
    {
        var timeChangeMap:Array<SongTimeChange> = [];

		var curBPM:Float = song.bpm;
		
        var songNumerator:Int = song.numerator ?? 4;
        var songDenominator:Int = song.denominator ?? 4;

        var currentNumerator:Int = songNumerator;
        var currentDenominator:Int = songDenominator;

		var position:Float = 0;
		var totalSteps:Int = 0;
		var totalBeats:Int = 0;
		var totalMeasures:Int = 0;

        // Initalize time signature.
        timeChangeMap.push(new SongTimeChange(position, curBPM, songNumerator, songDenominator));
        
		for (section in song.notes)
		{
			var event:SongTimeChange = null;

			if (section.changeBPM && section.bpm != curBPM)
			{
				curBPM = section.bpm;
                event = new SongTimeChange(position, curBPM, songNumerator, songDenominator);
			}

            var sectionNumerator:Int = section.numerator ?? currentNumerator;
            var sectionDenominator:Int = section.denominator ?? currentDenominator;

			if (currentNumerator != sectionNumerator
				|| currentDenominator != sectionDenominator)
			{
                currentNumerator = sectionNumerator;
                currentDenominator = sectionDenominator;
				
                if (event != null)
                {
                    event.numerator = currentNumerator;
                    event.denominator = currentDenominator;
                }
                else 
                {
                    event = new SongTimeChange(position, curBPM, currentNumerator, currentDenominator);
                }
			}
			if (event != null)
			{
				timeChangeMap.push(event);
			}

			totalSteps += Conductor.measureSteps(currentNumerator);
			totalBeats += Conductor.measureBeats(currentDenominator);
			totalMeasures++;

			position += Conductor.stepCrochetOf(curBPM, currentNumerator, currentDenominator) * Conductor.measureSteps(currentNumerator, currentDenominator);
		}
        return timeChangeMap;
    }

    static function convertChart(song:SwagSong):Array<SongSection>
    {
        var notes:Array<SongSection> = [];

        for (section in song.notes)
        {
            var songSection:SongSection = {mustHitSection: section.mustHitSection, notes: []};
            
            if (section != null)
            {
                for (note in section.sectionNotes)
                {
                    var note:SongNoteData = new SongNoteData(note[0], note[1], note[2], '', note[3]);
                    songSection.notes.push(note);
                }
            }
            notes.push(songSection);
        }
        return notes;
    }
}