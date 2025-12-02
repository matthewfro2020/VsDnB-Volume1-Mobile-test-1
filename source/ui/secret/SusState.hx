package ui.secret;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxTimer;

class SusState extends FlxState
{
	var sus:FlxSprite;

	public function new()
	{
		super();
	}

	override public function create()
	{
		super.create();

		sus = new FlxSprite(0, 0);
		sus.loadGraphic(Paths.image("secret/youactuallythoughttherewasasecrethere", "shared"));
		add(sus);
		new FlxTimer().start(10, jumpscare);
	}

	public function jumpscare(bruh:FlxTimer = null)
	{
		sus.loadGraphic(Paths.image("secret/scary", "shared"));
		SoundController.play(Paths.sound("jumpscare", "preload"), 1, false);
		new FlxTimer().start(0.6, closeGame);
	}

	public function closeGame(time:FlxTimer = null)
	{
		Sys.exit(0);
	}
}
