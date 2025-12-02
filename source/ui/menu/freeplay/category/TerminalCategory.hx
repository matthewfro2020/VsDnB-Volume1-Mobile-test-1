package ui.menu.freeplay.category;

import flixel.util.FlxColor;
import flixel.FlxG;
import data.language.LanguageManager;
import flixel.system.FlxAssets.FlxGraphicAsset;
import ui.menu.freeplay.category.Category.CategorySong;

class TerminalCategory extends Category
{
    public function new()
    {
        super('terminal');
    }

	public function getName():String
	{
		return LanguageManager.getTextString('freeplay_terminal');
	}

	public function getSongs():Array<CategorySong>
	{
		return [
			{id: 'cheating', color: [0xFFFF0000], icon: 'bambi-3d'},
			{id: 'unfairness', color: [0xFF0EAE2C], icon: 'bambi-unfair'},
            
			{id: 'Enter Terminal', color: [FlxColor.BLACK], icon: 'terminal'},
		];
	}

	public function getIcon():FlxGraphicAsset
	{
		return Paths.image('freeplay/categories/terminal');
	}
}