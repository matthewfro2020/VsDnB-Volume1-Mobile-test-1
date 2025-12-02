package ui;

import flixel.math.FlxPoint;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.display.BitmapData;

typedef CursorParams = 
{
    var graphic:FlxGraphicAsset;
    var ?scale:Float;
    var ?offset:FlxPoint;
}

class Cursor
{
    /**
     * Whether this mouse is currently visible or not.
     */
    public static var visible(default, set):Bool = false;

    static function set_visible(value:Bool):Bool
    {
        if (visible == value)
            return visible;

        setVisible(value);

        return visible = value;
    }

    /**
     * The graphic asset of the game's default cursor.
     */
    public static var DEFAULT_CURSOR:FlxGraphicAsset = 'cursor';

    /**
     * The parameters for the game's default cursor. 
     * Used for in-case the cursor needs to be reset due to it being changed.
     */
    public static final DEFAULT_CURSOR_PARAMS:CursorParams = {graphic: DEFAULT_CURSOR}

    /**
     * Initalizes the cursor graphic.
     * Called upon the game opening.
     */
    public static function initalize():Void
    {
        // Reset the cursor graphic to make sure it uses the default.
        reset();

        // Hide the cursor.
        hide();

        FlxG.signals.preUpdate.add(update);
        FlxG.console.registerClass(Cursor);
    }

    static function update():Void
    {
        // Sometimes the mouse will be either visible or invisible regardless of the actual state.
        // So we check to make sure the mouse is visible based on our property, and set it to that.
        if (visible != FlxG.mouse.visible)
            setVisible(visible);
    }

    /**
     * Loads a new cursor graphic given parameters.
     * @param params The parameters to use when loading the cursor.
     */
    public static function load(params:CursorParams)
    {
        if (params.scale == null)
            params.scale = 1;
        
        if (params.offset == null)
            params.offset = FlxPoint.get();
        
        if (params.graphic == null)
        {
            reset();
        }
        else
        {
            applyCursorParams(params);
        }
    }

    /**
     * Resets the cursor to the default cursor graphic.
     */
    public static function reset():Void
    {
        FlxG.mouse.unload();
        load(DEFAULT_CURSOR_PARAMS);

        // Make SURE the cursor is in the same toggle as before just to make sure.
        if (!visible)
        {
            hide();
        }
        else
        {
            show();
        }
    }

    /**
     * Enables the cursor to be visible.
     */
    public static function show():Void
    {
        visible = true;
    }

    /**
     * Disables the cursor to be unrendered.
     */
    public static function hide():Void
    {
        visible = false;
    }

    static function setVisible(visible:Bool):Void
    {
        FlxG.mouse.visible = visible;
        FlxG.mouse.cursor.visible = visible;
        FlxG.mouse.cursorContainer.visible = visible;
    }

    /**
     * Toggles the cursor current visibility.
     */
    public static function toggle():Void
    {
        if (visible)
        {
            hide();
        }
        else 
        {
            show();
        }
    }

    /**
     * Actually applies the given cursor parameters into the cursor.
     * @param params The parameters to set the cursor to.
     */
    static function applyCursorParams(params:CursorParams):Void
    {
        var bitmap:BitmapData = null;
        if (params.graphic is FlxGraphic)
        {
            var graphic:FlxGraphic = cast params.graphic;
            bitmap = graphic.bitmap;
        }
        else if (params.graphic is BitmapData)
        {
            bitmap = cast params.graphic;
        }
        else if (params.graphic is String)
        {
            // Load the given string graphic.
            bitmap = Paths.image(cast params.graphic).bitmap;
        }
        FlxG.mouse.load(bitmap, params.scale, Std.int(params.offset.x), Std.int(params.offset.y));
    }
}