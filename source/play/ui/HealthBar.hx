package play.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.group.FlxSpriteGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import play.character.Character;
import ui.select.playerSelect.PlayerSelect.SelectedPlayerType;

/**
 * The parameters for initalizing a health bar.
 */
typedef HealthBarParams =
{
	/**
	 * The graphic to use for the health bar.
	 */
	graphic:FlxGraphicAsset,

	/**
	 * The opponent character to use.
	 */
	opponent:Character,

	/**
	 * The player to use.
	 */
	player:Character,

	/**
	 * The parent state for this health bar.
	 */
	parent:Dynamic,

	/**
	 * The variable to base the health bar's percent on.
	 * This should be referenced from the `parent` object.
	 */
	variable:String,

	/**
	 * The minimum value of the health bar.
	 */
	min:Float,

	/**
	 * The maximum value for the health bar.
	 */
	max:Float,

	/**
	 * The scroll type for the health bar.
	 * Changes the y position based on whether it's upscroll, or downscroll.
	 */
	scrollType:String,

	/**
	 * Chooses whether which side is the player.
	 */
	playerType:SelectedPlayerType,
}

/**
 * A visual HUD element that displays how much health the user has in-comparison to the opponent.
 */
class HealthBar extends FlxSpriteGroup implements IHudItem
{
	/**
	 * The parameters passed on that are used for this health bar.
	 */
	var params(default, null):HealthBarParams;

	/**
	 * The current normalized value of the health bar.
	 * @see `FlxBar.percent`
	 */
	public var percent(get, never):Float;

	function get_percent():Float
	{
		return bar?.percent ?? 0.0;
	}

	/**
	 * The background of the health bar.
	 * @see `params.graphic`
	 */
	var bg:FlxSprite;

	/**
	 * The bar that actually shows the amount of health left.
	 */
	public var bar(default, null):FlxBar;

	/**
	 * The current value of the health bar.
	 * @see `FlxBar.value`
	 */
	public var value(get, never):Float;

	function get_value():Float
	{
		return bar?.value ?? params?.min ?? 0.0;
	}

	/**
	 * The current scroll type this health bar has.
	 */
	public var scrollType(default, set):String;

	public var playerType:SelectedPlayerType;

	public function set_scrollType(value:String):String
	{
		this.y = (value == 'downscroll' ? 50 : FlxG.height * 0.9);
		return scrollType = value;
	}

	public function new(x:Float, params:HealthBarParams)
	{
		if (params == null)
			return;

		super(x);

		scrollFactor.set();

		this.params = params;
		this.scrollType = params.scrollType;
		this.playerType = params.playerType;

		bg = new FlxSprite().loadGraphic(this.params.graphic);
		bg.antialiasing = true;
		bg.active = false;
		add(bg);

		var fillDirection:FlxBarFillDirection = this.playerType == PLAYER ? RIGHT_TO_LEFT : LEFT_TO_RIGHT;

		bar = new FlxBar(0, 0, fillDirection, Std.int(bg.width - 7), Std.int(bg.height - 8), params.parent, params.variable, params.min, params.max);
		bar.scrollFactor.set();
		updateColors(params.opponent, params.player);
		insert(members.indexOf(bg), bar);
		bar.setPosition(bg.x + 3, bg.y + 4);
	}

	/**
	 * Updates the colors of the health bar for the given players.
	 * @param opponent The opponent character to use the colors of the left side.
	 * @param player The player character to use the colors of the right side.
	 */
	public function updateColors(opponent:Character, player:Character)
	{
		var leftColor:FlxColor = this.playerType == PLAYER ? opponent.characterColor : player.characterColor;
		var rightColor:FlxColor = this.playerType == PLAYER ? player.characterColor : opponent.characterColor;

		bar.createFilledBar(leftColor, rightColor);
		bar.updateBar();
	}
}
