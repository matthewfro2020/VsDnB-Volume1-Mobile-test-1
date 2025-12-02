package util;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenManager;
import flixel.math.FlxMath;

class TweenUtil
{
	/**
	 *	Returns an ease function that eases the specified ease function via steps.
	 *
	 *	@param steps How many steps to ease over.
	 *	@param ease The ease function to use.
	 */
	public static inline function easeSteps(steps:Int, ?ease:EaseFunction):Float->Float
	{
		if (ease == null)
			ease = FlxEase.linear;

		return function(t:Float):Float
		{
			var value = Math.floor(t * steps) / steps;

			return ease(value);
		}
	}

	/**
	 *	Pauses all tweens on the manager.
	 *	@param manager The manager to pause all the tweens on (FlxTween.globalManager is none specified).
	 */
	public static inline function pauseTweens(?manager:FlxTweenManager)
	{
		if (manager == null)
			manager = FlxTween.globalManager;

		manager.forEach(function(t:FlxTween)
		{
			t.active = false;
		});
	}

	/**
	 *	Resumes all tweens on the manager.
	 *	@param manager The manager to resume all the tweens on (FlxTween.globalManager is none specified).
	 */
	public static inline function resumeTweens(?manager:FlxTweenManager)
	{
		if (manager == null)
			manager = FlxTween.globalManager;

		manager.forEach(function(t:FlxTween)
		{
			t.active = true;
		});
	}
	
	/**
	 * Completes all tweens running on `object`.
	 * Unlike `FlxTween.completeTweensOf()`, this allows to force the tween to be active for it work.
	 * @param object The tween to complete the tweens of.
	 * @param fieldPaths The fields to complete the tweens of. Optional.
	 * @param force Whether to force the tweens of `object` to be active, to then complete.
	 * @param manager The manager to complete all the tweens on (`FlxTween.globalManager` is none specified).
	 */
	public static inline function completeTweensOf(object:Dynamic, ?fieldPaths:Array<String>, force:Bool = true, ?manager:FlxTweenManager)
	{
		if (manager == null)
			manager = FlxTween.globalManager;
		
		if (!force)
		{
			manager.completeTweensOf(object, fieldPaths);
		}
		else
		{
			@:privateAccess
			manager.forEachTweensOf(object, fieldPaths, function(t:FlxTween) {
				t.active = true;
				
				// This helps bypass the delay property for VarTweens.
				@:privateAccess
				t._secondsSinceStart = FlxMath.MAX_VALUE_FLOAT;
			});
			manager.completeTweensOf(object, fieldPaths);
			
			// Cancel the tweens after they're completed so they don't affect the property afterwards.
			manager.cancelTweensOf(object, fieldPaths);
		}
	}
}
