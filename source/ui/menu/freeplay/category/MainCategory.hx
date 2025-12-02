package ui.menu.freeplay.category;

import data.language.LanguageManager;
import flixel.system.FlxAssets.FlxGraphicAsset;
import ui.menu.freeplay.category.Category.CategorySong;

class MainCategory extends Category
{
    public function new()
    {
        super('main');
    }

    public function getName():String
    {
        return LanguageManager.getTextString('freeplay_dave');
    }

    public function getSongs():Array<CategorySong>
    {
        return [
            {id: 'warmup', week: 1, color: [0xFF00137F], vinylPath: 'vinyl_dave'},
            
            // Dave Week
            {id: 'house', week: 1, color: [0xFF4965FF], vinylPath: 'vinyl_dave'},
            {id: 'insanity', week: 1, color: [0xFF4965FF], vinylPath: 'vinyl_dave'},
            {id: 'polygonized', week: 1, color: [0xFF4965FF], vinylPath: 'vinyl_dave'},
            
            // Bambi Week
            {id: 'blocked', week: 2, color: [0xFF00B515], vinylPath: 'vinyl_bambi'},
            {id: 'corn-theft', week: 2, color: [0xFF00B515], vinylPath: 'vinyl_bambi'},
            {id: 'maze', week: 2, color: [0xFF00B515], vinylPath: 'vinyl_bambi'},
            
            // Splitathon
            {id: 'splitathon', week: 3, color: [0xFF00FFFF], icon: 'the-duo', vinylPath: 'vinyl_duo'},
        ];
    }

    public function getIcon():FlxGraphicAsset
    {
        return Paths.image('freeplay/categories/main');
    }
}