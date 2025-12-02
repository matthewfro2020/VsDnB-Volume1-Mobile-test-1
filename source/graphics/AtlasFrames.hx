package graphics;

import haxe.io.Bytes;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.graphics.frames.FlxFrame;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import flxanimate.data.SpriteMapData.AnimateSpriteData;
import flxanimate.data.SpriteMapData.Meta;
import flxanimate.frames.FlxAnimateFrames;
import openfl.Assets;
import openfl.display.BitmapData;

/**
 * Alternative for getting FlxAnimateFrames.
 */
class AtlasFrames extends FlxAnimateFrames
{
	public static function textureAtlas(Path:String):FlxAtlasFrames
	{
		var frames:FlxAnimateFrames = new FlxAnimateFrames();

		var i = 1;
		while (Assets.exists('$Path/spritemap$i.json'))
		{
			var curJson:AnimateAtlas = haxe.Json.parse(StringTools.replace(Assets.getText('$Path/spritemap$i.json'), String.fromCharCode(0xFEFF), ""));
			var curSpritemap = Assets.getBitmapData('$Path/${curJson.meta.image}');

			if (curSpritemap != null)
			{
				var spritemapFrames = FlxAnimateFrames.fromSpriteMap(curJson, curSpritemap);
				if (spritemapFrames != null)
					frames.addAtlas(spritemapFrames);
			}
			else
				FlxG.log.error('the image called "${curJson.meta.image}" does not exist in Path $Path, maybe you changed the image Path somewhere else?');
			i++;
		}
		if (frames.frames == [])
		{
			FlxG.log.error("the Frames parsing couldn't parse any of the frames, it's completely empty! \n Maybe you misspelled the Path?");
			return null;
		}
		return frames;
	}

	static function atlasHelper(SpriteMap:BitmapData, limb:AnimateSpriteData, curMeta:Meta)
	{
		var width = (limb.rotated) ? limb.h : limb.w;
		var height = (limb.rotated) ? limb.w : limb.h;
		var sprite = new BitmapData(width, height, true, 0);
		var matrix = new FlxMatrix(1, 0, 0, 1, -limb.x, -limb.y);
		if (limb.rotated)
		{
			matrix.rotateByNegative90();
			matrix.translate(0, height);
		}
		sprite.draw(SpriteMap, matrix);

		@:privateAccess
		var curFrame = new FlxFrame(FlxG.bitmap.add(sprite));
		curFrame.name = limb.name;
		curFrame.sourceSize.set(width, height);
		curFrame.frame = new FlxRect(0, 0, width, height);
		return curFrame;
	}
}
