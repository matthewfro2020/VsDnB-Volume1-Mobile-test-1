package ui.terminal;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

abstract class TerminalDisplay
{
	public var myScreen:TerminalScreen;

	public function new(screen:TerminalScreen)
	{
		this.myScreen = screen;
	}

	public abstract function update(elapsed:Float):Void;
}

class TerminalScreen extends FlxSprite
{
	public static inline var characterWidth:Int = 9;
	public static inline var characterHeight:Int = 16;
	public static inline var sheetWidth:Int = 32;
	public static inline var sheetHeight:Int = 8;

	public var displays:Array<TerminalDisplay> = new Array<TerminalDisplay>();

	// do not add new colors without MY(mtm101's) approval or i will find where you live
	public static var colorMap:Map<TerminalColor, FlxColor> = [
		TerminalColor.BLACK => FlxColor.BLACK,
		TerminalColor.WHITE => FlxColor.WHITE,
		TerminalColor.DARK_WHITE => FlxColor.fromRGB(192, 192, 192),
		TerminalColor.GRAY => FlxColor.fromRGB(128, 128, 128),
		TerminalColor.DARK_RED => FlxColor.fromRGB(128, 0, 0),
		TerminalColor.RED => FlxColor.fromRGB(255, 0, 0),
		TerminalColor.DARK_GREEN => FlxColor.fromRGB(0, 128, 0),
		TerminalColor.GREEN => FlxColor.fromRGB(0, 255, 0),
		TerminalColor.DARK_YELLOW => FlxColor.fromRGB(128, 128, 0),
		TerminalColor.YELLOW => FlxColor.fromRGB(255, 255, 0),
		TerminalColor.DARK_BLUE => FlxColor.fromRGB(0, 0, 128),
		TerminalColor.BLUE => FlxColor.fromRGB(0, 0, 255),
		TerminalColor.DARK_MAGENTA => FlxColor.fromRGB(128, 0, 128),
		TerminalColor.MAGENTA => FlxColor.fromRGB(255, 0, 255),
		TerminalColor.DARK_CYAN => FlxColor.fromRGB(0, 128, 128),
		TerminalColor.CYAN => FlxColor.fromRGB(0, 255, 255),
		TerminalColor.TRANSPARENT => FlxColor.TRANSPARENT
	];

	// if ms-dos aligned perfectly with ascii i would not have to do this shit
	// but it does NOT. maybe the part that does could be automated in some way but i cant be bothered man
	public static var codePoints:Map<String, Int> = [
		// ascii characters
		"" => 0,
		" " => 32,
		"!" => 33,
		'"' => 34,
		"#" => 35,
		"$" => 36,
		"%" => 37,
		"&" => 38,
		"'" => 39,
		"(" => 40,
		")" => 41,
		"*" => 42,
		"+" => 43,
		"," => 44,
		"-" => 45,
		"." => 46,
		"/" => 47,
		"0" => 48,
		"1" => 49,
		"2" => 50,
		"3" => 51,
		"4" => 52,
		"5" => 53,
		"6" => 54,
		"7" => 55,
		"8" => 56,
		"9" => 57,
		":" => 58,
		";" => 59,
		"<" => 60,
		"=" => 61,
		">" => 62,
		"?" => 63,
		"@" => 64,
		"A" => 65,
		"B" => 66,
		"C" => 67,
		"D" => 68,
		"E" => 69,
		"F" => 70,
		"G" => 71,
		"H" => 72,
		"I" => 73,
		"J" => 74,
		"K" => 75,
		"L" => 76,
		"M" => 77,
		"N" => 78,
		"O" => 79,
		"P" => 80,
		"Q" => 81,
		"R" => 82,
		"S" => 83,
		"T" => 84,
		"U" => 85,
		"V" => 86,
		"W" => 87,
		"X" => 88,
		"Y" => 89,
		"Z" => 90,
		"[" => 91,
		"\\" => 92,
		"]" => 93,
		"^" => 94,
		"_" => 95,
		"`" => 96,
		"a" => 97,
		"b" => 98,
		"c" => 99,
		"d" => 100,
		"e" => 101,
		"f" => 102,
		"g" => 103,
		"h" => 104,
		"i" => 105,
		"j" => 106,
		"k" => 107,
		"l" => 108,
		"m" => 109,
		"n" => 110,
		"o" => 111,
		"p" => 112,
		"q" => 113,
		"r" => 114,
		"s" => 115,
		"t" => 116,
		"u" => 117,
		"v" => 118,
		"w" => 119,
		"x" => 120,
		"y" => 121,
		"z" => 122,
		"{" => 123,
		"|" => 124,
		"}" => 125,
		"~" => 126,
		// weird blocks
		"░" => 176,
		"▒" => 177,
		"▓" => 178,
		"█" => 219,
	];

	public var characterSet:BitmapData = null;

	public var screenWidth:Int = 0;
	public var screenHeight:Int = 0;

	public function SetCharacter(x:Int, y:Int, character:Int, textColor:TerminalColor = TerminalColor.DARK_WHITE,
			bgColor:TerminalColor = TerminalColor.BLACK):Void
	{
		var characterInd:Int = this.IndexFromPosition(x, y);
		this.characters[characterInd].index = character;
		this.characters[characterInd].foregroundColor = textColor;
		this.characters[characterInd].backgroundColor = bgColor;
	}

	public function RenderCharacter(x:Int, y:Int)
	{
		var characterInd:Int = this.IndexFromPosition(x, y);
		var character:TerminalCharacter = this.characters[characterInd];
		var ind:Int = character.index;
		if (character.index == -1)
		{
			ind = FlxG.random.int(0, 255);
		}
		var charX:Int = (ind % sheetWidth) * characterWidth;
		var charY:Int = (Std.int(ind / sheetWidth)) * characterHeight;

		var targetPixels:ByteArray = characterSet.getPixels(new Rectangle(charX, charY, characterWidth, characterHeight));
		var foregroundColor:FlxColor = colorMap[character.foregroundColor];
		var backgroundColor:FlxColor = colorMap[character.backgroundColor];
		for (i in 0...Std.int(targetPixels.length / 4))
		{
			var beginIndex:Int = i * 4;
			if (targetPixels[beginIndex] > 0)
			{
				targetPixels[beginIndex] = foregroundColor.alpha;
				targetPixels[beginIndex + 1] = foregroundColor.red;
				targetPixels[beginIndex + 2] = foregroundColor.green;
				targetPixels[beginIndex + 3] = foregroundColor.blue;
			}
			else
			{
				targetPixels[beginIndex] = backgroundColor.alpha;
				targetPixels[beginIndex + 1] = backgroundColor.red;
				targetPixels[beginIndex + 2] = backgroundColor.green;
				targetPixels[beginIndex + 3] = backgroundColor.blue;
			}
		}
		this.graphic.bitmap.setPixels(new Rectangle(x * characterWidth, y * characterHeight, characterWidth, characterHeight), targetPixels);
	}

	public function SetLetter(x:Int, y:Int, letter:String, textColor:TerminalColor = TerminalColor.DARK_WHITE, bgColor:TerminalColor = TerminalColor.BLACK):Void
	{
		SetCharacter(x, y, codePoints[letter], textColor, bgColor);
	}

	public function WriteString(x:Int, y:Int, text:String, textColor:TerminalColor = TerminalColor.DARK_WHITE, bgColor:TerminalColor = TerminalColor.BLACK)
	{
		for (i in 0...text.length)
		{
			SetLetter(x + i, y, text.charAt(i), textColor, bgColor);
		}
	}

	public var rngColors:Array<TerminalColor> = [
		TerminalColor.WHITE,
		TerminalColor.DARK_WHITE,
		TerminalColor.GRAY,
		TerminalColor.BLACK,
		TerminalColor.DARK_RED,
		TerminalColor.RED,
		TerminalColor.DARK_GREEN,
		TerminalColor.GREEN,
		TerminalColor.DARK_YELLOW,
		TerminalColor.YELLOW,
		TerminalColor.DARK_BLUE,
		TerminalColor.BLUE,
		TerminalColor.DARK_MAGENTA,
		TerminalColor.MAGENTA,
		TerminalColor.DARK_CYAN,
		TerminalColor.CYAN,
	];

	public function SetGarbageCharacter(x:Int, y:Int)
	{
		SetCharacter(x, y, FlxG.random.int(0, 255), rngColors[FlxG.random.int(0, rngColors.length - 1)], rngColors[FlxG.random.int(0, rngColors.length - 1)]);
	}

	public function RandomGarbage()
	{
		SetGarbageCharacter(FlxG.random.int(0, screenWidth - 1), FlxG.random.int(0, screenHeight - 1));
	}

	public var characters:Array<TerminalCharacter> = new Array<TerminalCharacter>();

	var charactersLastFrame:Array<TerminalCharacter> = new Array<TerminalCharacter>();

	public function IndexFromPosition(x:Int, y:Int):Int
	{
		return (y * screenWidth) + x;
	}

	public function new(scWidth:Int, scHeight:Int)
	{
		super();
		screenWidth = scWidth;
		screenHeight = scHeight;
		this.makeGraphic(scWidth * characterWidth, scHeight * characterHeight, FlxColor.TRANSPARENT, true);
		this.antialiasing = false;
		characterSet = BitmapData.fromFile("assets/images/IBMCharacters.png");
		for (x in 0...scWidth)
		{
			for (y in 0...scHeight)
			{
				var index = this.IndexFromPosition(x, y);
				characters[index] = new TerminalCharacter();
				charactersLastFrame[index] = new TerminalCharacter();
				this.SetCharacter(x, y, 0, TerminalColor.DARK_WHITE, TerminalColor.BLACK);
			}
		}
		#if !mobile
		Main.fps.visible = false; // todo: ask how to set this back lol
		#end
	}

	public function Clear()
	{
		for (x in 0...screenWidth)
		{
			for (y in 0...screenHeight)
			{
				this.SetCharacter(x, y, 0, TerminalColor.DARK_WHITE, TerminalColor.BLACK);
			}
		}
	}

	public function updateDisplays(elapsed:Float)
	{
		for (i in 0...displays.length)
		{
			displays[i].update(elapsed);
		}
	}

	public override function update(elapsed:Float)
	{
		updateDisplays(elapsed);
		for (x in 0...screenWidth)
		{
			for (y in 0...screenHeight)
			{
				var index:Int = this.IndexFromPosition(x, y);
				// if not equal, queue an update
				if (!charactersLastFrame[index].Equals(characters[index]))
				{
					this.RenderCharacter(x, y);
					charactersLastFrame[index].CopyFrom(characters[index]);
				}
			}
		}
		super.update(elapsed);
	}
}

class TerminalCharacter
{
	public var index:Int = 0;
	public var foregroundColor:TerminalColor = TerminalColor.DARK_WHITE;
	public var backgroundColor:TerminalColor = TerminalColor.BLACK;

	public function new(chr:Int = 0, fg:TerminalColor = TerminalColor.DARK_WHITE, bg:TerminalColor = TerminalColor.BLACK)
	{
		this.index = chr;
		this.foregroundColor = fg;
		this.backgroundColor = bg;
	}

	public static function copy(chr:TerminalCharacter):TerminalCharacter
	{
		var newChr:TerminalCharacter = new TerminalCharacter();
		newChr.CopyFrom(chr);
		return newChr;
	}

	public function CopyFrom(chr:TerminalCharacter)
	{
		this.index = chr.index;
		this.foregroundColor = chr.foregroundColor;
		this.backgroundColor = chr.backgroundColor;
	}

	public function Equals(chr:TerminalCharacter)
	{
		return (chr.index == this.index && chr.foregroundColor == this.foregroundColor && chr.backgroundColor == this.backgroundColor);
	}
}

enum TerminalColor
{
	BLACK;
	DARK_RED;
	DARK_GREEN;
	DARK_YELLOW;
	DARK_BLUE;
	DARK_MAGENTA;
	DARK_CYAN;
	DARK_WHITE;
	GRAY;
	RED;
	GREEN;
	YELLOW;
	BLUE;
	MAGENTA;
	CYAN;
	WHITE;
	TRANSPARENT; // USE MINIMALLY
}
