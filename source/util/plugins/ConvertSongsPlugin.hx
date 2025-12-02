package util.plugins;

import haxe.io.Path;
import sys.FileSystem;
import util.tools.converters.SongConverter;
import flixel.FlxG;
import flixel.FlxBasic;

/**
 * Plugin that converts a specified, or all songs to the new song format.
 */
class ConvertSongsPlugin extends FlxBasic
{
    public override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.keys.justPressed.F9)
        {
            convertAll();
        }
    }

    function convertSong(song:String):Void
    {
        SongConverter.convert(song);
    }
    function convertAll():Void
    {
        var songList:Array<String> = FileSystem.readDirectory(Paths.data('charts'));
        for (song in songList)
        {
            convertSong(Path.withoutExtension(song));
        }
    }
}