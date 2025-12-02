package play.ui;

import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import openfl.utils.Assets;

/**
 * A visual icon used both in-game to display the players, and also a prop to display a player's icon in a menu.
 */
class HealthIcon extends FlxSprite
{
	/**
	 * A list of characters that aren't antialiased.
	 */
	public final noAaChars:Array<String> = [
		'dave-angey',
		'bf-pixel',
		'gf-pixel',
		'bf-3d',
		'gf-3d',
		'baldi-3d',
		'exbungo',
	];

	/**
	 * The character id this icon is based off.
	 */
	public var char(default, set):String;

	public function set_char(value:String)
	{
		if (this.char == value)
			return value;

		if (value == 'none' || !Assets.exists(Paths.imagePath('iconGrid/${value}')))
		{
			value = 'face';
		}

		var file = Paths.image('iconGrid/$value');
		loadGraphic(file, true, 150, 150);

		var numFrames = frames?.frames?.length ?? 1;

		antialiasing = !noAaChars.contains(value);
		animation.add(value, [for (i in 0...numFrames) i], 0, false, isPlayer);
		animation.play(value);

		return char = value;
	}

	/**
	 * The current state the icon is in.
	 * This can either be `losing`, or `winning`
	 */
	public var state(default, set):IconState;

	public function set_state(value:IconState)
	{
		animation.curAnim.curFrame = switch (value)
		{
			case 'normal': 0;
			case 'losing': 1;
		}
		return state = value;
	}

	/**
	 * The sprite this icon will position based off of.
	 */
	public var sprTracker:FlxSprite;

	/**
	 * Whether this icon is for a user's player.
	 */
	public var isPlayer:Bool;

	/**
	 * Optional offsets to add in-case the health icon isn't able to be manually positioned.
	 */
	public var offsets:FlxPoint = FlxPoint.get();

	/**
	 * Whether the health icon should auto offset itself.
	 */
	public var autoOffset:Bool = true;

	public function new(char:String = 'bf', isPlayer:Bool = false):Void
	{
		super();
		this.isPlayer = isPlayer;
		this.char = char;
		scrollFactor.set();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (autoOffset)
			offset.set(Std.int(FlxMath.bound(width - 150, 0)), Std.int(FlxMath.bound(height - 150, 0)));

	if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10 + offsets.x, sprTracker.y + (sprTracker.height - this.height) / 2 + 25 + offsets.y);
	}

	/**
	 * Changes the state of the icon.
	 * @param charState The new state.
	 */
	public function changeState(charState:String):Void
	{
		state = charState;
	}
}

enum abstract IconState(String) from String
{
	var NORMAL = 'normal';
	var LOSING = 'losing';
}
