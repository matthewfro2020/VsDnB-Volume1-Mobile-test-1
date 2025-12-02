package ui.menu.freeplay.category;

import data.language.LanguageManager;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import ui.menu.freeplay.category.Category.CategorySong;

class MiscCategory extends Category
{
    public function new()
    {
        super('misc');
    }

    public function getName():String
    {
        return LanguageManager.getTextString('freeplay_misc');
    }

    public function getSongs():Array<CategorySong>
    {
        return
        [
            {id: 'freakyMenu', external: true, color: [0xFF4965FF, 0xFF00B515]},

            {id: 'a-new-day', external: true, color: [0xFF4965FF, 0xFF00B515]},
            {id: 'breakfast', external: true, color: [FlxColor.multiply(0xFF4965FF, FlxColor.GRAY), FlxColor.multiply(0xFF00B515, FlxColor.GRAY)]},

            {id: 'bad-ending', external: true, color: [0xFF4965FF]},
            {id: 'good-ending', external: true, color: [0xFF4965FF]},
            
            {id: 'game-over', external: true, color: [FlxColor.fromRGB(40, 40, 40)]},
            {id: 'characterSelect', external: true, color: [0xFF4965FF, 0xFF00B515, FlxColor.fromString("0xFF130F"), FlxColor.fromString("0xFFC300")]},
            {id: 'playerSelect-backseat', external: true, color: [FlxColor.fromString("0xFFC300"), FlxColor.fromString("0xFF130F")], vinylPath: 'vinyl_backseat'},
            {id: 'bot-trot-extended', external: true, color: [FlxColor.fromString("0xFFC300")], vinylPath: 'vinyl_playrobot'},

            {id: 'daves-head', external: true, color: [0xFF4965FF]},

            {id: 'wait-is-over', external: true, color: [0xFF4965FF, 0xFF00B515]},
        ];
    }

    public function getIcon():FlxGraphicAsset
    {
        return Paths.image('freeplay/categories/misc');
    }
}