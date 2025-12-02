package ui.terminal;

import flixel.FlxG;
import ui.terminal.TerminalScreen;

import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;

class TerminalClearer extends TerminalDisplay
{
	public function update(elapsed:Float):Void
	{
		myScreen.Clear();
	}
}

class TerminalLinePrinter extends TerminalDisplay
{
	public var addendText:String = "";

	public var lines:Array<TerminalLinePrinterLine> = new Array<TerminalLinePrinterLine>();

	public function update(elapsed:Float):Void
	{
		for (i in 0...lines.length)
		{
			lines[i].draw(this.myScreen, i);
		}
		if (addendText != "")
		{
			this.myScreen.WriteString(0, lines.length, addendText);
		}
	}

	// todo: ALSO SPLIT IF LONGER THAN screenWidth
	public function AddLine(text:String, fgColor:TerminalColor = TerminalColor.DARK_WHITE, bgColor:TerminalColor = TerminalColor.BLACK)
	{
		var splittedText:Array<String> = text.split("\n"); // can't have newlines
		for (i in 0...splittedText.length)
		{
			this.AddLineInternal(splittedText[i], fgColor, bgColor);
		}
	}

	public function AddCustomLine(line:TerminalLinePrinterLine)
	{
		lines.push(line);
		if ((lines.length + (addendText == "" ? 0 : 1)) > myScreen.screenHeight)
		{
			// is this stupid? probably. but i dont care
			lines.reverse();
			lines.pop();
			lines.reverse();
		}
	}

	function AddLineInternal(text:String, fgColor:TerminalColor = TerminalColor.DARK_WHITE, bgColor:TerminalColor = TerminalColor.BLACK)
	{
		lines.push(new TerminalLinePrinterLine(text, fgColor, bgColor));
		if ((lines.length + (addendText == "" ? 0 : 1)) > myScreen.screenHeight)
		{
			// is this stupid? probably. but i dont care
			lines.reverse();
			lines.pop();
			lines.reverse();
		}
	}
}

class TerminalLinePrinterLine
{
	public var text:String;
	public var foregroundColor:TerminalColor = TerminalColor.DARK_WHITE;
	public var backgroundColor:TerminalColor = TerminalColor.BLACK;

	public function draw(screen:TerminalScreen, y:Int)
	{
		screen.WriteString(0, y, text, foregroundColor, backgroundColor);
	}

	public function new(string:String, fgColor:TerminalColor = TerminalColor.DARK_WHITE, bgColor:TerminalColor = TerminalColor.BLACK)
	{
		this.text = string;
		this.foregroundColor = fgColor;
		this.backgroundColor = bgColor;
	}
}