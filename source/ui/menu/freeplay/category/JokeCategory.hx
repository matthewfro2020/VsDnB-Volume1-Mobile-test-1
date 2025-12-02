package ui.menu.freeplay.category;

import flixel.FlxG;
import data.language.LanguageManager;
import flixel.system.FlxAssets.FlxGraphicAsset;
import ui.menu.freeplay.category.Category.CategorySong;

class JokeCategory extends Category
{
    public function new()
    {
        super('joke');
    }

    public function getName():String
    {
        return LanguageManager.getTextString('freeplay_joke');
    }

    public function getSongs():Array<CategorySong>
    {
        return
        [
            {id: 'overdrive', color: [0xFF0162F5], icon: 'dave-awesome', vinylPath: 'vinyl_dave'},

            {id: 'supernovae', week: 5, color: [0xFF116E1C], vinylPath: 'vinyl_bambi'},
            {id: 'glitch', week: 5, color: [0xFF116E1C], vinylPath: 'vinyl_bambi'},
            {id: 'master', week: 5, color: [0xFF116E1C], vinylPath: 'vinyl_bambi'},
                
            {id: 'kabunga', color: [0xFFFF0000]},
            {id: 'roofs', color: [0xFF0EAE2C]},
            
            {id: 'vs-dave-rap', color: [0xFF00137F], vinylPath: 'vinyl_dave'},
            {id: 'vs-dave-rap-two', color: [0xFF00137F], vinylPath: 'vinyl_dave'},
        ];
    }

    public function getIcon():FlxGraphicAsset
    {
        return Paths.image('freeplay/categories/joke');
    }
}