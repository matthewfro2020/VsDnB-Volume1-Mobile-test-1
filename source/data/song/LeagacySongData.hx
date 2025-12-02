package data.song;

import util.tools.converters.SongConverter;
import data.song.SongData.SongSection;
import haxe.Json;
import lime.utils.Assets;
#if sys
import sys.io.File;
#end

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
	var numerator:Int;
	var denominator:Int;
}
typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var numerator:Int;
	var denominator:Int;

	var player1:String;
	var player2:String;
	var gf:String;
	var stage:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SongSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gf:String;
	public var stage:String;

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String):SwagSong
	{
		var rawJson = "";
		var chartFile:String = Paths.chart(jsonInput.toLowerCase());

		rawJson = File.getContent(chartFile).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
