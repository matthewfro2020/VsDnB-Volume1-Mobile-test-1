package util;

import flixel.math.FlxMath;

class MathUtil
{
	/**
	 * Perform a framerate-independent linear interpolation between the base value and the target.
	 * @param current The current value.
	 * @param target The target value.
	 * @param elapsed The time elapsed since the last frame.
	 * @param duration The total duration of the interpolation. Nominal duration until remaining distance is less than `precision`.
	 * @param precision The target precision of the interpolation. Defaults to 1% of distance remaining.
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return A value between the current value and the target value.
	 */
	public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		if (current == target)
			return target;

		var result:Float = FlxMath.lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

		// TODO: Is there a better way to ensure a lerp which actually reaches the target?
		// Research a framerate-independent PID lerp.
		if (Math.abs(result - target) < (precision * target))
			result = target;

		return result;
	}
}