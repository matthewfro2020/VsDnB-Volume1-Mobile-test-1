package data.animation;

import flixel.FlxSprite;
import graphics.FlxAtlasSprite;

typedef AnimationData =
{
	var name:String;
	var prefix:String;
	var ?frameRate:Int;
	var ?loop:Bool;
	var ?flip:Array<Bool>;
	var ?indices:Array<Int>;
	var ?offsets:Array<Float>;
}

class Animation
{
	/**
	 * The default animation frameate to use if none is provided.
	 */
	public static final DEFAULT_FRAMERATE:Int = 24;

	/**
	 * Replaces null Animation data values with default values.
	 * @param data The animation data to validate.
	 * @return A newly validated animation data.
	 */
	public static function validateAnimationData(data:AnimationData):AnimationData
	{
		data.frameRate = data.frameRate ?? DEFAULT_FRAMERATE;
		data.loop = data.loop ?? false;
		data.flip = data.flip ?? [false, false];
		data.offsets = data.offsets ?? [0, 0];
		return data;
	}

	/**
	 * Adds an animation data into an FlxSprite.
	 * @param target The sprite to apply the data into the animation.
	 * @param animation The data used to apply to the sprite.
	 */
	public static function addToSprite(target:FlxSprite, animation:AnimationData):Void
	{
		animation = validateAnimationData(animation);

		if (target is FlxAtlasSprite)
		{
			var sprite:FlxAtlasSprite = cast(target, FlxAtlasSprite);

			if (animation.indices != null)
			{
				sprite.addByIndices(animation.name, animation.prefix, animation.frameRate, animation.loop, animation.indices);
			}
			else
			{
				sprite.addByPrefix(animation.name, animation.prefix, animation.frameRate, animation.loop);
			}
		}
		else
		{
			if (animation.indices != null)
			{
				target.animation.addByIndices(animation.name, animation.prefix, animation.indices, '', animation.frameRate, animation.loop, animation.flip[0],
					animation.flip[1]);
			}
			else
			{
				target.animation.addByPrefix(animation.name, animation.prefix, animation.frameRate, animation.loop, animation.flip[0], animation.flip[1]);
			}
		}
	}

	/**
	 * Adds an animation data into an FlxSprite.
	 * @param target The sprite to apply the animatiosn to.
	 * @param animations The animations to add onto the sprite.
	 */
	public static function addAnimationsToSprite(target:FlxSprite, animations:Array<AnimationData>):Void
	{
		for (animation in animations)
		{
			if (animation != null)
				addToSprite(target, animation);
		}
	}
}
