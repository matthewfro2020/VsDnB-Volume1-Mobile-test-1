package play.ui;

import play.save.Preferences;
import backend.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.typeLimit.OneOfTwo;
import util.tools.Preloader;

typedef RatingsType =
{
	/**
	 * The asset directory this type is in.
	 */
	var directory:String;

	/**
	 * The size of this rating type.
	 */
	var size:Float;

	/**
	 * Whether this rating type is aliased, or not.
	 */
	var antialiasing:Bool;
}

class RatingsGroup extends FlxSpriteGroup
{
	/**
	 * List of all the types of ratings used, and the data for each.
	 * TODO: Probably best to softcode this.
	 */
	var types:Map<OneOfTwo<String, Array<String>>, RatingsType> = [
		'normal' => {directory: 'normal/', size: 0.7, antialiasing: true},
		['3d', 'shape'] => {directory: '3D/', size: 0.7, antialiasing: false},
		'pixel' => {directory: 'pixel/', size: 6, antialiasing: false}
	];

	/**
	 * The current style this group uses.
	 */
	var style(default, set):String;

	function set_style(value:String):String
	{
		if (style == value)
			return style;

		var ratingData:RatingsType = getData(value);

		cacheStyle(value);

		ratingSpr.antialiasing = ratingData.antialiasing;

		comboSpr.loadGraphic(Paths.image('ui/combo/${ratingData.directory}combo'));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * ratingData.size));
		comboSpr.updateHitbox();
		comboSpr.antialiasing = ratingData.antialiasing;

		return style = value;
	}

	/**
	 * The rating sprite of this group.
	 * Updates in accordance to the style.
	 * Gets reused when popups happen for performance.
	 */
	var ratingSpr:FlxSprite;

	/**
	 * The combo sprite of this group.
	 * Updates in accordance to this style.
	 * Gets reused when popups happen for performance.
	 */
	var comboSpr:FlxSprite;

	public function new(style:String)
	{
		super();

		ratingSpr = new FlxSprite();
		ratingSpr.alpha = 0.0001;
		add(ratingSpr);

		comboSpr = new FlxSprite();
		comboSpr.alpha = 0.0001;
		add(comboSpr);

		this.style = style;
	}

	public override function draw():Void
	{
		if (!Preferences.minimalUI)
			super.draw();
	}

	/**
	 * Caches a the specified rating style.
	 * Useful to make sure the game doesn't lag when a player hits a note.
	 * @param style The style to be cached.
	 */
	public function cacheStyle(?style:String)
	{
		var data:RatingsType = getData(style);

		for (i in 0...10)
		{
			Preloader.cacheImage('ui/combo/${data.directory}num${i}');
		}
		for (i in ['bad', 'combo', 'good', 'shit', 'sick'])
		{
			Preloader.cacheImage('ui/combo/${data.directory}${i}');
		}
	}

	/**
	 * Gets the data for the specified style.
	 * @param style The style to get the data of.
	 */
	function getData(style:String)
	{
		var ratingData:RatingsType = types.get('normal');
		for (key => value in types)
		{
			if (key.contains(style))
				ratingData = value;
		}
		return ratingData;
	}

	/**
	 * Displays a visual popup showing the rating based on how a player is doing.
	 * @param rating The rating to show.
	 * @param combo The current combo the player has, used to display a 'combo' graphic if the specified combo is high enough.
	 * @param style The style the rating should be.
	 */
	public function ratingPopup(rating:String, combo:Int, ?style:String)
	{
		var ratingData:RatingsType = getData(style ?? this.style);

		ratingSpr.loadGraphic(Paths.image('ui/combo/${ratingData.directory}${rating}'));
		ratingSpr.setGraphicSize(Std.int(ratingSpr.width * ratingData.size));
		ratingSpr.updateHitbox();

		// Reset the rating sprite to be re-used.
		ratingSpr.alpha = 1;
		ratingSpr.velocity.set();
		ratingSpr.acceleration.set();
		FlxTween.cancelTweensOf(ratingSpr);

		ratingSpr.x = this.x - ratingSpr.width / 2;
		ratingSpr.y = this.y - ratingSpr.height / 2;

		ratingSpr.acceleration.y = 550;
		ratingSpr.velocity.x -= FlxG.random.int(0, 10);
		ratingSpr.velocity.y -= FlxG.random.int(140, 175);
		
		var hasCombo:Bool = combo % 50 == 0 && combo != 0;

		if (hasCombo)
		{
			// Reset the combo sprite to be re-used.
			comboSpr.alpha = 1;
			comboSpr.velocity.set();
			comboSpr.acceleration.set();
			FlxTween.cancelTweensOf(comboSpr);

			comboSpr.x = this.x - comboSpr.width / 2 - 100;
			comboSpr.y = this.y + 45;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.x += FlxG.random.int(1, 10);
			comboSpr.velocity.y -= 150;

			ratingTween(comboSpr);
		}
		comboSpr.x = this.x - comboSpr.width / 2 - 100;
		comboSpr.y = this.y + 45;

		var seperatedScore:Array<Int> = [];
		var comboSplit:Array<String> = Std.string(combo).split('');

		for (num in comboSplit)
		{
			seperatedScore.push(Std.parseInt(num));
		}

		var numList:Array<FlxSprite> = [];
		for (i in 0...seperatedScore.length)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/combo/${ratingData.directory}num${comboSplit[i]}'));
			numScore.antialiasing = ratingData.antialiasing;
			numScore.setGraphicSize(Std.int(numScore.width * ratingData.size));
			numScore.updateHitbox();

			if (numList.length == 0)
			{
				// Center the number to the combo sprite.
				numScore.x = (this.comboSpr.x - this.x) + comboSpr.width + 2;
				numScore.y = (this.comboSpr.y - this.y) - (comboSpr.height - numScore.height) / 2 + 35;
			}
			else
			{
				numScore.x = (numList[i - 1].x - this.x) + numScore.width + 2;
				numScore.y = (numList[i - 1].y - this.y);
			}

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			add(numScore);
			numList.push(numScore);

			ratingTween(numScore, 2, function(tween:FlxTween)
			{
				remove(numScore, true);
			});
		}
		ratingTween(ratingSpr);
	}

	/**
	 * Helper function to a quick tween relating to ratings.
	 * @param spr The rating sprite to do a tween of.
	 * @param delayTime Delay time before the rating disappears. Defaults to 1.
	 * @param onComplete Function to call when the tween is complete.
	 */
	function ratingTween(spr:FlxSprite, delayTime:Float = 1, ?onComplete:FlxTween->Void)
	{
		FlxTween.tween(spr, {alpha: 0}, 0.2, {onComplete: onComplete, startDelay: (Conductor.instance.crochet / 1000) * delayTime});
	}
}