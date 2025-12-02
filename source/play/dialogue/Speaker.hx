package play.dialogue;

import util.FlxZSprite;
import data.dialogue.SpeakerData;
import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;

class Speaker extends FlxZSprite
{
    public var dialogueSounds:Array<FlxSound>;
    public var globalOffsets:Array<Float>;
    public var data:SpeakerData;

    public function new(data:SpeakerData)
    {
        super();
        this.data = data;

        this.globalOffsets = data.globalOffsets;
        this.dialogueSounds = [];

        // Prepare a harmless default 1x1 graphic
        makeGraphic(1, 1, 0x00FFFFFF);
        zIndex = 10;
    }

    public function switchToExpression(exprName:String):Void
    {
        var expr:SpeakerExpressionData = null;

        for (e in data.expressions)
            if (e.name == exprName)
                expr = e;

        if (expr == null)
            return;

        // RESET PREVIOUS VISUALS (required!)
        this.animation.destroyAnimations();
        this.frames = null;

        // ============================================================
        //  1. ATLAS / MULTI-FRAME ANIMATION
        // ============================================================
        if (expr.animation != null)
        {
            var atlas:FlxAtlasFrames = Paths.getSparrowAtlas(expr.assetPath);

            if (atlas != null)
            {
                this.frames = atlas;
                this.antialiasing = expr.antialiasing;
                this.animation.addByPrefix(
                    "play",
                    expr.animation.name,
                    expr.animation.fps
                );
                this.animation.play("play");
            }
        }
        else
        {
            // ========================================================
            //  2. SINGLE PNG EXPRESSION — **NO loadGraphic EVER**
            // ========================================================

            var bmp:BitmapData = Paths.image(expr.assetPath);
            if (bmp != null)
            {
                // Make an identical-size blank canvas
                makeGraphic(bmp.width, bmp.height, 0x00000000);

                // Copy image pixels into FlxZSprite bitmap
                this.pixels.copyPixels(
                    bmp,
                    bmp.rect,
                    bmp.rect.topLeft
                );

                this.dirty = true; // refresh render
                this.updateHitbox();
            }
        }

        // ================================================================
        //  Apply expression metadata (scale, AA, offsets)
        // ================================================================
        this.antialiasing = expr.antialiasing;
        this.scale.set(expr.scale, expr.scale);

        // Offset adjustments
        this.x += expr.offsets[0];
        this.y += expr.offsets[1];
    }
}
