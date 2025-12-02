package audio;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.ui.FlxSoundTray;
import openfl.display.BitmapData;
import openfl.text.TextField;
import openfl.text.TextFormatAlign;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import play.save.Preferences;

/**
 * An internal object used to change the game's master volume.
 */
class GameSoundTray extends FlxSoundTray
{
	public function new()
	{
		super();

		removeChildren();

		volumeDownSound = Paths.soundPath("clicky", "shared");
		volumeUpSound = Paths.soundPath("clicky", "shared");

		visible = false;
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		_bg = new Bitmap(new BitmapData(_minWidth, 30, true, 0x7F000000));
		screenCenter();
		addChild(_bg);

		_label = new TextField();
		_label.width = _bg.width;
		_label.multiline = true;
		_label.selectable = false;

		var dtf:TextFormat = new TextFormat("Comic Sans MS Bold", 8, 0xffffff);
		dtf.align = TextFormatAlign.CENTER;
		_label.defaultTextFormat = dtf;
		addChild(_label);

		_label.text = "VOLUME";
		_label.y = 16;

		_bars = new Array();

		var tmp:Bitmap;
		for (i in 0...10)
		{
			tmp = new Bitmap(new BitmapData(4, i + 1, false, FlxColor.WHITE));
			addChild(tmp);
			_bars.push(tmp);
		}
		updateSize();

		y = -height;
		visible = false;
	}

	public override function update(MS:Float):Void
	{
		// Animate stupid sound tray thing
		if (_timer > 0)
		{
			_timer -= MS / 1000;
		}
		else if (y > -height)
		{
			y -= (MS / 1000) * FlxG.height * 2;
			if (y <= -height)
			{
				visible = false;
				active = false;

				// Save sound preferences
				Preferences.masterVolume = FlxG.sound.volume;
				FlxG.save.flush();
			}
		}
	}

	public override function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label = "VOLUME")
	{
		var labelText:String = "Volume - " + ((Math.round(FlxG.sound.volume * 100) <= 0 || FlxG.sound.muted) ? "MUTED" : (Math.round(FlxG.sound.volume * 100)) + "%");
		
		super.showAnim(volume, sound, duration, labelText);
	}
}