package play.ui;

import ui.select.playerSelect.PlayerSelect.SelectedPlayerType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.addons.display.FlxRadialGauge;

import play.character.Character;
import play.save.Preferences;

typedef TimerType =
{
	/**
	 * The graphic of this style.
	 */
	var graphic:FlxGraphicAsset;

	/**
	 * The scaled this style should be.
	 */
	var ?scale:FlxPoint;

	/**
	 * The offsets that are needed for the graphic of this style.
	 */
	var ?offsets:FlxPoint;

	/**
	 * Whether this style is pixelated.
	 */
	var antialiasing:Bool;
}

/**
 * A UI graphic that displays the current time of a song.
 */
class HudTimer extends FlxSpriteGroup implements IHudItem
{
	/**
	 * The constant size of the pie graphics.
	 */
	final PIE_SIZE = (120 * 0.7) / 2;

	/**
	 * A list of all of the hard-coded type for a timer.
	 * TODO: Softcode this ?
	 */
	final types:Map<String, TimerType> = [
		'normal' => {graphic: Paths.image('ui/timer'), offsets: FlxPoint.get(0, 0), antialiasing: true},
		'3d' => {
			graphic: Paths.image('ui/timer-3d'),
			scale: FlxPoint.get(0.9, 0.9),
			offsets: FlxPoint.get(-5, -4),
			antialiasing: false
		}
	];

	/**
	 * Whether this timer's able to update it's graphics, or not.
	 */
	public var canUpdate:Bool = true;

	/**
	 * The current scroll type of this timer, changes the position based on this.
	 */
	public var scrollType(default, set):String;

	function set_scrollType(value:String):String
	{
		this.y = (value == 'downscroll' ? 560 : 10);
		return scrollType = value;
	}

	var playerType:SelectedPlayerType;

	/**
	 * The visual graphic that displays over the timer.
	 */
	var timerGraphic:FlxSprite;

	/**
	 * The grey part of the timer.
	 */
	var pieTimerFill:FlxRadialGauge;

	/**
	 * The circular visual that actually displays the timer.
	 * Overlayed over the fill graphic to show how much time of the song is left. 
	 */
	var pieTimer:FlxRadialGauge;

	/**
	 * The text that displays information on the song's time.
	 */
	var timerText:FlxText;

	
	public function new(x:Float = 0, y:Float = 0, opponent:Character, scrollType:String, type:String)
	{
		super(x, y);

		this.scrollType = scrollType;

		scrollFactor.set();

		var targetType:Null<TimerType> = getType(type);
		var timerType:TimerType = (targetType != null) ? targetType : getType('normal');

		timerGraphic = new FlxSprite().loadGraphic(timerType.graphic);
		timerGraphic.active = false;
		timerGraphic.scale.set(timerType.scale?.x ?? 1.0, timerType.scale?.y ?? 1.0);
		timerGraphic.updateHitbox();
		timerGraphic.antialiasing = timerType.antialiasing;
		add(timerGraphic);

		pieTimerFill = new FlxRadialGauge(21 + timerType.offsets?.x, 30 + timerType.offsets?.y);
		pieTimerFill.makeShapeGraphic(FlxRadialGaugeShape.CIRCLE, Std.int(PIE_SIZE), 0, FlxColor.GRAY);
		pieTimerFill.active = false;
		insert(members.indexOf(timerGraphic), pieTimerFill);

		pieTimer = new FlxRadialGauge(21 + timerType.offsets?.x, 30 + timerType.offsets?.y);
		pieTimer.makeShapeGraphic(FlxRadialGaugeShape.CIRCLE, Std.int(PIE_SIZE), 0, FlxColor.WHITE);
		pieTimer.color = opponent.characterColor;
		pieTimer.setOrientation(270, -90);
		pieTimer.active = false;
		pieTimer.amount = 0;
		pieTimer.antialiasing = timerType.antialiasing;
		insert(members.indexOf(timerGraphic), pieTimer);

		timerText = new FlxText(0, (timerGraphic.y - this.y) + timerGraphic.height - 5, 0, "0:00", 24);
		timerText.setFormat(Paths.font("comic.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timerText.borderSize = 2.5;
		timerText.active = false;
		add(timerText);
		timerText.x = timerGraphic.x + (timerGraphic.width - timerText.textField.textWidth) / 2;

		Preferences.onPreferenceChanged.add(onPreferenceChange);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!canUpdate)
			return;

		pieTimer.amount = Math.max(0, SoundController.music.time / SoundController.music.length);

		if (FlxG?.sound?.music != null && FlxG?.sound?.music?.playing ?? false)
		{
			updateText();
		}
	}

	override function destroy()
	{
		Preferences.onPreferenceChanged.remove(onPreferenceChange);
		super.destroy();
	}
	
	override function draw()
	{
		// If we're in minimal mode, we DON'T want to draw this.
		if (Preferences.minimalUI)
			return;
		
		super.draw();
	}

	/**
	 * Updates the timer's graphic to represent specified type.
	 * @param type The type to change the timer to.
	 */
	public function switchType(type:String)
	{
		var timerType:TimerType = getType(type);

		if (timerType == null)
			return;

		timerGraphic.loadGraphic(timerType.graphic);
		timerGraphic.scale.set(timerType.scale?.x ?? 1.0, timerType.scale?.y ?? 1.0);
		timerGraphic.updateHitbox();
		timerGraphic.antialiasing = timerType.antialiasing;

		pieTimerFill.setPosition(this.x + 21 + timerType.offsets?.x, this.y + 30 + timerType.offsets?.y);
		pieTimer.setPosition(this.x + 21 + timerType.offsets?.x, this.y + 30 + timerType.offsets?.y);

		pieTimer.antialiasing = timerType.antialiasing;
		
		timerText.x = timerGraphic.x + (timerGraphic.width - timerText.textField.textWidth) / 2;
		timerText.y = (timerGraphic.y - this.y) + timerGraphic.height - 5 + this.y;
	}

	public function updateText()
	{
		var time = Math.min(SoundController.music.time, SoundController.music.length);
		var length = SoundController.music.length;

		timerText.text = switch (Preferences.timerType)
		{
			case 'timeLeft': FlxStringUtil.formatTime((length - time) / 1000);
			case 'timeElapsed': FlxStringUtil.formatTime(time / 1000);
			case 'elapsedAndLeft': '${FlxStringUtil.formatTime(time / 1000)} / ${FlxStringUtil.formatTime(length / 1000)}';
			default: '';
		}
		timerText.x = timerGraphic.x + (timerGraphic.width - timerText.textField.textWidth) / 2;
	}

	function getType(name:String):Null<TimerType>
	{
		return types[name] ?? null;
	}

	public function updatePieColor(color:FlxColor)
	{
		pieTimer.color = color;
	}

	public function onPreferenceChange(preference:String, value:Any)
	{
		if (preference == 'timerType')
		{
			updateText();
		}
	}
}
