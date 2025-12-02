package ui.menu.freeplay.category;

import data.language.LanguageManager;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import ui.menu.freeplay.category.Category.CategorySong;

class ExtrasCategory extends Category
{
    public function new()
    {
        super('extras');
    }

    public function getName():String
    {
        return LanguageManager.getTextString('freeplay_extra');
    }

    public function getSongs():Array<CategorySong>
    {
        return
        [
            {id: 'backseat', color: [0xFFFF0000], icon: 'playrobot-tristan', vinylPath: 'vinyl_backseat'},
            
            {id: 'bonus-song', color: [0xFF4965FF], vinylPath: 'vinyl_dave'},
            {id: 'mealie', color: [0xFF00B515], icon: 'bambi-loser', vinylPath: 'vinyl_bambi'},
            {id: 'adventure', color: [0xFFFF0000], vinylPath: 'vinyl_tristan'},
            {id: 'bot-trot', color: [FlxColor.fromString('0xFFC300')], vinylPath: 'vinyl_playrobot'},
        ];
    }

    public function getIcon():FlxGraphicAsset
    {
        return Paths.image('freeplay/categories/extras');
    }
}