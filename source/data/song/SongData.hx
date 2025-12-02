package data.song;

import haxe.Json;
import json2object.JsonWriter;

/**
 * A data object containing all of the data information for a song.
 */
class SongMetadata
{
    /**
     * The semantic version number for this data object.
     */
    public var version:String;

    /**
     * The readable name of this song.
     */
    public var songName:String;

    /**
     * List of all of the composers who made the song.
     */
    @:default([])
    public var composers:Array<String>;
    
    /**
     * List of all of the artists for this song.
     */
    @:default([])
    public var artists:Array<String>;
    
    /**
     * List of all of the charters for this song.
     */
    @:default([])
    public var charters:Array<String>;

    /**
     * List of all of the programmers for this song.
     */
    @:default([])
    public var coders:Array<String>;

    /**
     * A list of all of the playable variations for this song.
     */
    @:default([])
    @:optional
    public var variations:Array<String>;

    /**
     * The stage that's used for this song
     */
    @:default('stage')
    public var stage:String;

    /**
     * The character id of the player (BF) for this song.
     */
    @:default('bf')
    public var player:String;

    /**
     * The character id of the opponent (dad) for this song.
     */
    @:default('dave')
    public var opponent:String;

    /**
     * The character id of the gf for this song.
     */
    @:alias('gf')
    @:default('gf')
    public var girlfriend:String;

    /**
     * A list of all of the time changes this song has.
     */
    public var timeChanges:Array<SongTimeChange>;


    public function new(songName:String, composers:Array<String>, artists:Array<String>, charters:Array<String>, coders:Array<String>)
    {
        this.version = SongRegistry.METADATA_VERSION;
        this.songName = songName;
        
        this.composers = composers;
        this.artists = artists;
        this.charters = charters;
        this.coders = coders;

        this.player = 'bf';
        this.opponent = 'dave';
        this.girlfriend = 'gf';

        this.timeChanges = [];
    }

    public function toString():String
    {
        return '[SongMetadata] (${songName}) ([composers: ${composers}, artists: ${artists}, charters: ${charters}], [player: ${player}, opponent: ${opponent}, gf: ${girlfriend}], Time Changes: ${timeChanges})';
    }

    /**
     * Serializes this SongMetadata object into a json string.
     * @return A SongMetadata JSON string.
     */
    public function serialize():String
    {
        var writer:JsonWriter<SongMetadata> = new JsonWriter<SongMetadata>();
        writer.ignoreNullOptionals = true;
        return writer.write(this, '  ');
    }
}

class SongChartData
{
    /**
     * The semantic version number for this data object.
     */
    public var version:String;
    
	/**
	 * The speed of the chart.
	 */
    @:default(1)
	public var speed:Float;

    /**
     * A list of all of the notes in the song.
     * Separated via measure sections.
     */
    @:default([])
    public var notes:Array<SongSection>;

    /**
     * Initalizes a new chart data.
     * @param speed The speed of the chart.
     * @param notes A list of all notes.
     */
    public function new(speed:Float, notes:Array<SongSection>)
    {
        this.version = SongRegistry.CHART_DATA_VERSION;
        this.speed = speed;
        this.notes = notes;
    }
    
    /**
     * Serializes this SongChartData object into a json string.
     * @return A SongChartData JSON string.
     */
    public function serialize():String
	{
		var writer = new json2object.JsonWriter<SongChartData>(true);
		return writer.write(this, '  ');
	}
}

@:forward(time, direction, length, type, noteStyle, getDirection)
abstract SongNoteData(SongNoteDataRaw) from SongNoteDataRaw to SongNoteDataRaw
{
    public function new(time:Float, direction:Int, length:Float = 0.0, type:String = '', style:String = 'normal')
    {
        this = new SongNoteDataRaw(time, direction, length, type, style);
    }

    @:op(A == B)
	public function op_equals(other:SongNoteData):Bool
	{
        return this.time == other.time && this.direction == other.direction &&
        this.length == other.length && this.type == other.type && this.noteStyle == other.noteStyle;
	}

	@:op(A != B)
	public function op_notEquals(other:SongNoteData):Bool
	{
        return this.time != other.time || this.direction != other.direction ||
        this.length != other.length || this.type != other.type || this.noteStyle != other.noteStyle;
	}

    
	@:op(A > B)
	public function op_greaterThan(other:SongNoteData):Bool
	{
        return this.time > other.time;
	}

	@:op(A < B)
	public function op_lessThan(other:SongNoteData):Bool
	{
        return this.time < other.time;
	}

	@:op(A >= B)
	public function op_greaterThanOrEquals(other:SongNoteData):Bool
	{
        return this.time >= other.time;
	}

	@:op(A <= B)
	public function op_lessThanOrEquals(other:SongNoteData):Bool
	{
        return this.time <= other.time;
	}
}
class SongNoteDataRaw
{
    /**
     * The time this note's supposed to be hit.
     */
    @:default(0.0)
    public var time:Float;

    /**
     * The direction this note is in.
     */
    @:default(0)
    public var direction:Int;

    /**
     * How long the note needs to be held down for, in milliseconds.
     */
    @:default(0)
    public var length:Float;

    /**
     * The type of this note this is.
     */
    @:optional
    @:default('')
    public var type:String;

    /**
     * The style/skin of this note.
     */
    @:default('normal')
    @:alias('style')
    public var noteStyle:String;

    /**
     * Initalizes a new note data.
     * @param time The time the note should be hit at.
     * @param direction The direction of the note.
     * @param length How long the note is.
     * @param type What type of note this is.
     * @param style The style of this note.
     */
    public function new(time:Float, direction:Int, length:Float = 0.0, type:String = '', style:String = 'normal')
    {
        this.time = time;
        this.direction = direction;
        this.length = length;
        this.noteStyle = style;
    }

    /**
     * Gets the actual direction of this note data.
     * @return A number between 0-3.
     */
    public function getDirection():Int
    {
        return direction % 4;
    }

    public function toString():String
    {
        return 'SongNoteData(time: ${time}, direction: ${direction}, length: ${length}, type: ${type})';
    }
}

@:forward(time, bpm, numerator, denominator, stepTime, beatTime, measureTime)
abstract SongTimeChange(SongTimeChangeRaw) from SongTimeChangeRaw to SongTimeChangeRaw
{
    public function new(time:Float, bpm:Float, numerator:Int = 4, denominator:Int = 4)
    {
        this = new SongTimeChangeRaw(time, bpm, numerator, denominator);
    }
	
    @:op(A == B)
	public function op_equals(other:SongTimeChange):Bool
	{
        return this.time == other.time && this.bpm == other.bpm && 
        this.numerator == other.numerator && this.denominator == other.denominator; 
	}

	@:op(A != B)
	public function op_notEquals(other:SongTimeChange):Bool
	{
        return this.time != other.time || this.bpm != other.bpm || 
        this.numerator != other.numerator || this.denominator != other.denominator; 
	}

	@:op(A > B)
	public function op_greaterThan(other:SongTimeChange):Bool
	{
        return this.time > other.time;
	}

	@:op(A < B)
	public function op_lessThan(other:SongTimeChange):Bool
	{
        return this.time < other.time;
	}

	@:op(A >= B)
	public function op_greaterThanOrEquals(other:SongTimeChange):Bool
	{
        return this.time >= other.time;
	}

	@:op(A <= B)
	public function op_lessThanOrEquals(other:SongTimeChange):Bool
	{
        return this.time <= other.time;
	}
}

class SongTimeChangeRaw
{
    /**
     * The time when this time change happens, in milliseconds.
     */
    @:default(0.0)
    public var time:Float;

    /**
     * The bpm of this time change.
     */
    @:default(100)
    public var bpm:Float;

    /**
     * The time signature numerator of this time change.
     */
    @:default(4)
    public var numerator:Int;

    /**
     * The time signature denominator of this time change.
     */
    @:default(4)
    public var denominator:Int;
    
    /**
     * The time at which this time changes happens, in steps.
     * Automatically calculated when mapped.
     */
    @:jignored
    public var stepTime:Float;

    /**
     * The time at which this time changes happens, in beats.
     * Automatically calculated when mapped.
     */
    @:jignored
    public var beatTime:Float;
    
    /**
     * The time at which this time changes happens, in measure.
     * Automatically calculated when mapped.
     */
    @:jignored
    public var measureTime:Float;

    public function new(time:Float, bpm:Float, numerator:Int = 4, denominator:Int = 4)
    {
        this.time = time;
        this.bpm = bpm;
        this.numerator = numerator;
        this.denominator = denominator;
    }

    public function toString():String
    {
        return 'SongTimeChange(${time} ms, ${bpm} bpm, Time Signature: ${numerator}/${denominator})';
    }
}

typedef SongSection =
{
    /**
     * A list of all of the notes in this section.
     */
    var notes:Array<SongNoteData>;

	/**
	 * Whether this is a section that must be hit by the player.
	 */
	var mustHitSection:Bool;
}

/**
 * A data object containing metadata for external music.
 * Ex. Menu music, game over music, etc.
 */
class SongMusicData
{
    /**
     * The semantic version number of this object.
     */
    public var version:String;

    /**
     * The readable name of this song.
     */
    public var name:String;

    /**
     * The asset path to the music file.
     */
    public var musicPath:String;

    /**
     * A list of all the composers who worked on this song.
     */
    public var composers:Array<String>;
    
    /**
     * A list of variations this music has.
     */
    public var variations:Array<String>;
    
    /**
     * A list of all the time changes.
     */
    public var timeChanges:Array<SongTimeChange>;

    public function toString():String
    {
        return 'SongMusicData($name version: $version, composers: ${composers})';
    }
}