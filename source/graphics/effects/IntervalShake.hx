package graphics.effects;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxAxes;
import flixel.util.FlxPool;
import flixel.util.FlxTimer;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxEase.EaseFunction;

/**
 * Copy of the 'FlxFlicker' and 'FlxCamera' where instead of Flickering objects on a given interval and time, they shake (similar to Base FNF).
 */
class IntervalShake implements IFlxDestroyable
{
	static var _pool:FlxPool<IntervalShake> = new FlxPool<IntervalShake>(IntervalShake.new);

	/**
	 * Internal map for looking up which objects are currently shaking and getting their shake data.
	 */
	static var _boundObjects:Map<FlxObject, IntervalShake> = new Map<FlxObject, IntervalShake>();

	/**
	 * The shaking object.
	 */
	public var object(default, null):FlxObject;

	/**
	 * The start interval of the object after shake is complete.
	 */
	public var startInterval(default, null):Float;

	/**
	 * The final interval of the object after shake is complete.
	 */
	public var endInterval(default, null):Float;

	/**
	 * The shake timer. You can check how many seconds has passed since shaking started etc.
	 */
	public var timer(default, null):FlxTimer;

	/**
	 * The callback that will be triggered after the shake has completed.
	 */
	public var completionCallback(default, null):IntervalShake->Void;

	/**
	 * The callback that will be triggered every time object visiblity is changed.
	 */
	public var progressCallback(default, null):IntervalShake->Void;

	/**
	 * The duration of the shake (in seconds). `0` means "forever".
	 */
	public var duration(default, null):Float;

	/**
	 * The interval of the shake.
	 */
	public var interval(default, null):Float;

	/**
	 * The axes of the shake.
	 */
	public var axes(default, null):FlxAxes;

	/**
	 * The ease of the shake.
	 */
	public var ease(default, null):EaseFunction;

	/**
	 * Helper variable to keep track of the time passed since the shake started based.
	 */
	public var elapsedTime(default, null):Float;

	/**
	 * The object's initial position, will reset to this when the shake's finished.
	 */
	public var initialPosition(default, null):FlxPoint;

	/**
	 * Shake an object based on a start and end interval.
	 * @param Object The object to be shaking.
	 * @param Duration The amount of time the shake should last for.
	 * @param Interval The interval at which the object should shake.
	 * @param startInterval The interval in which the shake should start with.
	 * @param endInterval The interval in which the shake should end at.
	 * @param axes The axes in which the object should shake at.
	 * @param ease How the object's shake eases.
	 * @param CompletionCallback Callback that's called after the shake is completed.
	 * @param ProgressCallback Callback that's called every 'Interval' seconds.
	 * @return A new IntervalShake object.
	 */
	public static function shake(Object:FlxObject, Duration:Float = 1, Interval:Float = 0.04, startInterval:Float = 0, endInterval:Float = 0, ?axes:FlxAxes,
			?ease:EaseFunction, ?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):IntervalShake
	{
		if (isShaking(Object))
		{
			return _boundObjects[Object];
		}

		if (Interval <= 0)
		{
			Interval = FlxG.elapsed;
		}

		var shake:IntervalShake = _pool.get();
		shake.start(Object, Duration, Interval <= 0 ? FlxG.elapsed : Interval, startInterval, endInterval, axes, ease, CompletionCallback, ProgressCallback);
		return _boundObjects[Object] = shake;
	}

	/**
	 * Returns whether the object is shaking or not.
	 *
	 * @param   Object The object to test.
	 */
	public static function isShaking(Object:FlxObject):Bool
	{
		return _boundObjects.exists(Object);
	}

	/**
	 * Stops shaking of the object. Also it will make the object visible.
	 *
	 * @param   Object The object to stop shaking.
	 */
	public static function stopShaking(Object:FlxObject):Void
	{
		var boundShake:IntervalShake = _boundObjects[Object];
		if (boundShake != null)
		{
			boundShake.stop();
		}
	}

	function start(Object:FlxObject, Duration:Float, Interval:Float, startInterval:Float, endInterval:Float, ?axes:FlxAxes, ?ease:EaseFunction,
			?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):Void
	{
		object = Object;

		duration = Duration;
		interval = Interval;
		this.startInterval = startInterval;
		this.endInterval = endInterval;
		this.axes = axes;
		this.ease = ease ?? FlxEase.linear;
		completionCallback = CompletionCallback;
		progressCallback = ProgressCallback;
		elapsedTime = 0;

		initialPosition = object.getPosition();

		timer = new FlxTimer().start(interval, shakeProgress, Std.int(duration / interval));
	}

	/**
	 * Nullifies the references to prepare object for reuse and avoid memory leaks.
	 */
	public function destroy():Void
	{
		object = null;
		timer = null;
		initialPosition = null;
		ease = null;
		completionCallback = null;
		progressCallback = null;
	}

	/**
	 * Pauses the shake on this object.
	 */
	public function pause():Void
	{
		if (timer == null)
			return;

		timer.active = false;
	}
	
	/**
	 * Resume the shake on this object.
	 */
	public function resume():Void
	{
		if (timer == null)
			return;

		timer.active = true;
	}

	/**
	 * Stops the shake on this object.
	 */
	public function stop():Void
	{
		timer.cancel();
		object.visible = true;
		release();
	}

	/**
	 * Removes the current object from the shake list.
	 */
	function release():Void
	{
		_boundObjects.remove(object);
		_pool.put(this);
	}

	/**
	 * Helper function to update the shake's progression.
	 * @param timer The timer for the shake.
	 */
	function shakeProgress(timer:FlxTimer):Void
	{
		elapsedTime += interval;

		var normalizedTimeElapsed = elapsedTime / duration;
		normalizedTimeElapsed = 1 - ease(normalizedTimeElapsed);

		var curInterval = FlxMath.lerp(endInterval, startInterval, normalizedTimeElapsed);

		if (axes.x)
			object.x = initialPosition.x + (FlxG.random.float((-curInterval * object.width), (curInterval * object.width)));
		if (axes.y)
			object.y = initialPosition.y + (FlxG.random.float((-curInterval * object.height), (curInterval * object.height)));

		if (progressCallback != null)
			progressCallback(this);

		if (timer.loops > 0 && timer.loopsLeft == 0)
		{
			object.setPosition(initialPosition.x, initialPosition.y);

			if (completionCallback != null)
				completionCallback(this);

			if (this.timer == timer)
				release();
		}
	}

	/**
	 * Internal constructor. Use static methods.
	 */
	@:keep
	function new()
	{
	}
}
