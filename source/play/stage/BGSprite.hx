package play.stage;

import data.animation.Animation;
import data.animation.Animation.AnimationData;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;

using StringTools;

/**
 * A visual prop used in the background for a stage.
 */
class BGSprite extends FlxSprite
{
	/**
	 * The name of the sprite.
	 */
	public var spriteName:String;

	/**
	 * Creates a new BGSprite object.
	 * @param spriteName The name of the sprite.
	 * @param posX The x position of the sprite.
	 * @param posY The y position of the sprite.
	 * @param graphic The graphic asset to use.
	 * @param animations Optional, any animations the sprite has.
	 * @param scrollX How much the sprite should scroll on the x side.
	 * @param scrollY How much the sprite should scroll on the y side.
	 * @param antialiasing Whether the sprite should be pixelated.
	 * @param active Should the sprite call the `update()` function?
	 */
	public function new(spriteName:String, posX:Float, posY:Float, graphic:FlxGraphicAsset = null, animations:Array<AnimationData>, scrollX:Float = 1, scrollY:Float = 1,
			antialiasing:Bool = true, active:Bool = false)
	{
		super(posX, posY);

		this.spriteName = spriteName;
		var hasAnimations:Bool = animations != null;

		if (graphic != null)
		{
			if (hasAnimations)
			{
				frames = Paths.getSparrowAtlas(graphic);
				for (anim in animations)
				{
					Animation.addToSprite(this, anim);
				}
			}
			else
			{
				loadGraphic(graphic);
			}
		}
		this.antialiasing = antialiasing;
		scrollFactor.set(scrollX, scrollY);
		this.active = active;
	}

	/**
	 * Gets a BGSprite from a list.
	 * @param spriteGroup The list to retrieve the sprite from.
	 * @param spriteName The name of the sprite.
	 * @return A BGSprite.
	 */
	public static function getBGSprite(spriteGroup:FlxTypedGroup<BGSprite>, spriteName:String):BGSprite
	{
		for (bgSprite in spriteGroup.members)
		{
			if (bgSprite.spriteName == spriteName)
			{
				return bgSprite;
			}
		}
		return null;
	}
}
