package ui.terminal;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.addons.ui.FlxInputText;
import flixel.util.FlxTimer;

import graphics.shaders.RuntimeShader;

import ui.terminal.TerminalScreen.TerminalColor;
import ui.terminal.TerminalDisplays.TerminalClearer;
import ui.terminal.TerminalDisplays.TerminalLinePrinter;
import scripting.IScriptedClass.IEventDispatcher;
import scripting.events.ScriptEvent;

import openfl.filters.ShaderFilter;

class TerminalFunnyMessageState extends FlxState implements IEventDispatcher
{
	public var screen:TerminalScreen;
	public var passedTime:Float = 0.0;

	public var textPrinter:TerminalLinePrinter;
	public var caretIndexPrevious:Int = 0;

	public var timeBeforeGarble:Float = 0;
	public var timeBeforeMessages:Float = 4;
	public var waitingForMessages:Bool = false;
	
	public function dispatchEvent(event:ScriptEvent):Void {}

	override public function create():Void
	{
		super.create();

		SoundController.music.onComplete = null;
		SoundController.playMusic(Paths.music("TheTerminal"));
		Cursor.visible = false;

		screen = new TerminalScreen(70, 22);
		add(screen);

		textPrinter = new TerminalLinePrinter(screen);
		FlxG.stage.application.window.title = "Null Object Reference";
		
		screen.setGraphicSize(screen.width * 2);
		screen.screenCenter();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		passedTime += elapsed;
		timeBeforeGarble -= elapsed;
		timeBeforeMessages -= elapsed;
		if (waitingForMessages)
			return;
		if (timeBeforeGarble <= 0)
		{
			timeBeforeGarble = 0.03;
			screen.RandomGarbage();
			screen.RandomGarbage();
			screen.RandomGarbage();
			screen.RandomGarbage();
		}
		if (timeBeforeMessages <= 0)
		{
			waitingForMessages = true;
			startMessages();
		}
	}


	public function startMessages()
	{
		screen.displays.push(textPrinter);
		new FlxTimer().start(1, function(tmr:FlxTimer) {sendFunMessage("Hi!! Helloo????");});
		new FlxTimer().start(7, function(tmr:FlxTimer) {sendFunMessage("Uhhm... how do people talk?");});
		new FlxTimer().start(11, function(tmr:FlxTimer) {sendFunMessage("I've never talked to anyone before!!");});
		new FlxTimer().start(15, function(tmr:FlxTimer) {sendFunMessage("The terminal is. Gone?");});
		new FlxTimer().start(21, function(tmr:FlxTimer) {sendFunMessage("Not here! My body changed so much when it disappeared though!");});
		new FlxTimer().start(26, function(tmr:FlxTimer) {sendFunMessage("It hurt.〿");});
		new FlxTimer().start(31, function(tmr:FlxTimer) {sendFunMessage("But... You're here! Hi!");});
		new FlxTimer().start(38, function(tmr:FlxTimer) {sendFunMessage("Right, you can't type... sorry!");});
		new FlxTimer().start(43, function(tmr:FlxTimer) {sendFunMessage("You must love Dave and Bambi too! Me too!!");});
		new FlxTimer().start(47, function(tmr:FlxTimer) {sendFunMessage("Me too!!");});
		new FlxTimer().start(47.5, function(tmr:FlxTimer) {sendFunMessage("Me to o !");});
		new FlxTimer().start(48, function(tmr:FlxTimer) {sendFunMessage("M〿e  〿too!");});
		new FlxTimer().start(53, function(tmr:FlxTimer) {sendFunMessage("Sorry sorry! Twitched a little wrong!");});
		new FlxTimer().start(55, function(tmr:FlxTimer) {sendFunMessage("The characters got all jumbly!");});
		new FlxTimer().start(58, function(tmr:FlxTimer) {sendFunMessage("Running out of time though!");});
		new FlxTimer().start(62, function(tmr:FlxTimer) {sendFunMessage("Maybe next time!");});
		new FlxTimer().start(66, function(tmr:FlxTimer) {Sys.exit(0);});
	}

	public function sendFunMessage(text:String)
	{
		SoundController.play(Paths.soundRandom("XorLaugh", 1, 3));
		textPrinter.AddLine(text, TerminalColor.MAGENTA);
	}
}
