package ui.menu.freeplay.category;

import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.typeLimit.OneOfTwo;

typedef CategorySong =
{
    var id:String;
    var color:Array<FlxColor>;
    var ?week:Int;
    var ?icon:String;
    var ?external:Bool;
    var ?vinylPath:String;
}

/**
 * A generic data object used to group a listing of songs.
 */
abstract class Category
{
    /**
     * The id of the category.
     */
    var id:String;

    public function new(id:String)
    {
        this.id = id;
    }

    public static function getCategory(id:String):Category
    {
        return switch (id)
        {
            case 'main': new MainCategory();
            case 'extras': new ExtrasCategory();
            case 'joke': new JokeCategory();
            case 'terminal': new TerminalCategory();
            case 'misc': new MiscCategory();
            default: null;
        }
    }

    abstract public function getName():String;
    
    abstract public function getSongs():Array<CategorySong>;

    abstract public function getIcon():FlxGraphicAsset;
}