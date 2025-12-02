package play.ui;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import play.PlayState;
import play.ui.IHudItem;
import play.save.Preferences;

typedef HudDisplayParams =
{
	/**
	 * The name of the HUD display.
	 * This is used to get the asset.
	 */
	name:String,

	/**
	 * The parent state.
	 */
	parent:Dynamic,

	/**
	 * A variable from `parent` to track.
	 */
	trackerVariable:String,

	/**
	 * The string to start with when initalizing the display.
	 */
	startString:String,

	/**
	 * The scroll type to use.
	 */
	scrollType:String
}

/**
 * A HUD element that visually displays the scoring for a usr..
 */
class HudDisplay extends FlxSpriteGroup implements IHudItem
{
	/**
	 * The parameters for this display.
	 */
	public var params:HudDisplayParams;

	/**
	 * The scroll type for this display element.
	 */
	public var scrollType(default, set):String;

	function set_scrollType(value:String):String
	{
		y = (value == 'downscroll' ? 75 : 675);
		return scrollType = value;
	}

	/**
	 * The name of this display element.
	 * Also known as the asset path.
	 */
	public var name(default, null):String;

	/**
	 * The parent this display uses.
	 */
	public var parent(default, null):Dynamic;

	/**
	 * The scoring variable from `parent` to track. 
	 */
	public var trackerVariable(default, null):String;

	/**
	 * The current value being displayed.
	 */
	public var value(default, null):Float;

	/**
	 * The display icon that shows next to the text.
	 */
	public var icon(default, null):FlxSprite;

	/**
	 * The text that displays the tracked performance.
	 */
	public var text(default, null):FlxText;

	/**
	 * Called whenever the text changes.
	 * Used usually if you want to change what the text looks like.
	 */
	public var textUpdateFunc:Float->Void;

	public function new(x:Float, params:HudDisplayParams)
	{
		if (params == null)
			return;

		super(x);

		scrollFactor.set();

		this.params = params;
		this.scrollType = params.scrollType;

		this.name = params.name ?? '';
		this.parent = params.parent ?? PlayState;
		this.trackerVariable = params.trackerVariable ?? '';

		icon = new FlxSprite().loadGraphic(Paths.image('ui/${params.name}'));
		icon.scale.set(0.5, 0.5);
		icon.updateHitbox();
		icon.active = false;
		icon.antialiasing = true;
		add(icon);

		text = new FlxText(0, 0, 0, params.startString, 20);
		text.setFormat(Paths.font('comic.ttf'), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		text.borderSize = 1.5;
		text.active = false;
		text.antialiasing = true;
		add(text);
		text.setPosition(icon.x + icon.width + 5, icon.y - (text.textField.height - icon.height) / 2);
	}

	public override function update(elapsed:Float)
	{
		var variableValue = Reflect.getProperty(parent, trackerVariable);
		if (Reflect.getProperty(parent, trackerVariable) != value)
		{
			updateText(variableValue);
		}
		super.update(elapsed);
	}

	override function draw()
	{
		// If we have minimal UI enabled, we DON'T want to draw this.
		if (Preferences.minimalUI)
			return;

		super.draw();
	}

	function updateText(newValue:Float)
	{
		value = newValue;
		text.text = FlxStringUtil.formatMoney(newValue, false);
		if (textUpdateFunc != null)
		{
			textUpdateFunc(newValue);
		}
	}
}
