package ui.menu.story;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

import play.save.Preferences;

/**
 * A UI object that's displayed in the settings menu,
 */
class MenuItem extends FlxSpriteGroup
{
	/**
	 * The ease type to use when moving the menu item.
	 */
	public static var easeType = FlxEase.cubeOut;

	/**
	 * The time to ease the position of the item.
	 */
	public static var easeTime:Float = 0.3;

	/**
	 * The graphic that displays the week.
	 */
	public var week:FlxSprite;

	/**
	 * The tween used to move the item.
	 */
	var currentTween:FlxTween;

	/**
	 * The target x position of the menu item.
	 */
	public var targetX:Float = 0;

	/**
	 * Used to keep track of the amount of flash frames that's happened.
	 */
	var flashingInt:Int = 0;

	/**
	 * Whether the item was selected, and is currently flashing.
	 */
	private var isFlashing:Bool = false;

	public function new(x:Float, y:Float, weekNum:Int = 0)
	{
		super(x, y);
		if (weekNum == 5 && !FlxG.save.data.hasPlayedMasterWeek)
		{
			week = new FlxSprite().loadGraphic(Paths.image('storyMenu/weeks/weekquestionmark'));
		}
		else
		{
			week = new FlxSprite().loadGraphic(Paths.image('storyMenu/weeks/week' + weekNum));
		}
		add(week);
		week.antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isFlashing)
			flashingInt += 1;

		var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);
		if (fakeFramerate == 0)
			return;

		if (flashingInt % fakeFramerate >= Math.floor(fakeFramerate / (!Preferences.flashingLights ? 0.5 : 2)))
		{
			week.color = 0xFF33ffff;
		}
		else
		{
			week.color = FlxColor.WHITE;
		}
	}

	/**
	 * Changes the x position of the menu item.
	 * @param newTarget The new x position.
	 */
	public function changeTargetX(newTarget:Float)
	{
		targetX = newTarget;
		if (currentTween != null)
		{
			currentTween.active = false;
			currentTween.destroy();
			currentTween = null;
		}
		currentTween = FlxTween.tween(this, {x: (targetX * 450) + 420}, easeTime, {type: ONESHOT, ease: easeType, onComplete: clearTween});
	}

	/**
	 * Clears out the item's tween. Called when the tween's been completed.
	 * @param t The tween.
	 */
	function clearTween(t:FlxTween)
	{
		currentTween = null;
	}

	/**
	 * Starts flashing the menu item.
	 * This usually means it was selected.
	 */
	public function startFlashing():Void
	{
		isFlashing = true;
	}
}
