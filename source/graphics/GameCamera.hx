package graphics;

import flixel.FlxCamera;
import flixel.util.FlxAxes;
import play.save.Preferences;

/**
 * An `FlxCamera` extension for helping with user preferences.
 */
class GameCamera extends FlxCamera
{
	public override function shake(Intensity:Float = 0.05, Duration:Float = 0.5, ?OnComplete:Void->Void, Force:Bool = true, ?Axes:FlxAxes):Void
	{
		if (Preferences.cameraShaking)
			super.shake(Intensity, Duration, OnComplete, Force, Axes);
	}
}
