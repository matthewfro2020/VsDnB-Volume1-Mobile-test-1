
package util;

import flixel.FlxSprite;
import flixel.util.FlxGradient;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class GradientUtil
{
    public static function applyGradientToBitmapData(target:BitmapData, colors:Array<FlxColor>, chunkSize:Int = 1, rotation:Int = 90, interpolate:Bool = true)
	{
        if (target == null)
            return null;

		var gradientPixels = FlxGradient.createGradientBitmapData(target.width, target.height, colors, chunkSize, rotation, interpolate);

		// BitmapData persists within FlxSprites.
		// We need to clone it if we want to overlay it so it doesn't interfere in the future with a different sprite.
		var newPixels:BitmapData = target.clone();

		for (w in 0...target.width)
		{
			for (h in 0...target.height)
			{
				var pixelColor:FlxColor = target.getPixel(w, h);
				var gradientPixelColor:FlxColor = gradientPixels.getPixel(w, h);

				var finalColor = FlxColor.multiply(pixelColor, gradientPixelColor);
				newPixels.setPixel(w, h, finalColor);
			}
		}
        return newPixels;
	}

    public static function applyGradientToSprite(target:FlxSprite, colors:Array<FlxColor>, chunkSize:Int = 1, rotation:Int = 90, interpolate:Bool = true)
	{
        var gradientBitmapData:BitmapData = applyGradientToBitmapData(target.pixels, colors, chunkSize, rotation, interpolate);

		target.pixels = gradientBitmapData;
	}
}