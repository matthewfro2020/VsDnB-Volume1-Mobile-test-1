package ui.secret;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxState;
#if sys
import sys.io.File;
import sys.io.Process;
#end

/**
 * scary!!!
 */
class YouCheatedSomeoneIsComing extends FlxState // why did this extend music beat state?
{
	public function new()
	{
		super();
	}

	override public function create():Void
	{
		super.create();

		if (SoundController.music != null)
			SoundController.music.stop();

		SoundController.playMusic(Paths.music('badEnding'), 1, true);
		var spooky:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('dave/endings/cheater_lol', 'shared'));
		spooky.screenCenter();
		add(spooky);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.keys.pressed.ENTER)
		{
			endIt();
		}
	}

	public function endIt()
	{
		FlxG.switchState(() -> new SusState());
	}
}
