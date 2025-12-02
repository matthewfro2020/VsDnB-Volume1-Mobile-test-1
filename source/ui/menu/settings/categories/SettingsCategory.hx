package ui.menu.settings.categories;

import controls.PlayerSettings;
import flixel.group.FlxSpriteGroup;
import ui.menu.settings.SettingsMenu.SettingsOption;

/**
 * A list containers for the available options in the settings menu.
 */
class SettingsCategory extends FlxSpriteGroup
{
	var parent:SettingsMenu;

	public var curOptionSelected:Int = 0;

	public var list:Array<SettingsOption> = [];

	var curOption:SettingsOption;
	
	public var firstAvailableOption(get, never):Int;

	function get_firstAvailableOption():Int
	{
		for (ind => option in list)
		{
			// Return the first option that's available.
			if (option.canInteract)
			{
				return ind;
			}
		}

		return -1;
	}

	public var lastAvailableOption(get, never):Int;

	function get_lastAvailableOption():Int
	{
		var index:Int = list.length - 1;

		while (index > -1)
		{
			if (list[index].canInteract)
			{
				return index;
			}
			index--;
		}

		return -1;
	}

	public function new(menu:SettingsMenu)
	{
		super();
		this.parent = menu;

		init();

		for (i in list)
		{
			i.menu = parent;
		}
	}

	public function init():Void {}

	/**
	 * The name of the category that'll be displayed in the settings menu.
	 * @return String
	 */
	public function getName():String 
	{
		throw 'Needs to be overwritten';
	}

	/**
	 * Handles the inputs in this category.
	 */
	public function handleInputs():Void
	{
		var upP = PlayerSettings.controls.UP_P;
		var downP = PlayerSettings.controls.DOWN_P;
		var accept = PlayerSettings.controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}
		if (accept)
		{
			onAccept();
		}
	}

	public function changeSelection(amount:Int = 0):Void
	{
		var oldSelect = curOptionSelected;
		curOptionSelected += amount;

		if (curOptionSelected < 0)
			curOptionSelected = list.length - 1;
		if (curOptionSelected > list.length - 1)
			curOptionSelected = 0;

		if (list[curOptionSelected].canInteract)
		{
			onSelect(curOptionSelected);
		}
		else
		{
			curOptionSelected = oldSelect;
		}
	}

	public function deselectOption():Void
	{
		curOption?.onDeselected.dispatch();
	}

	function onSelect(index:Int):Void
	{
		SoundController.play(Paths.sound('scrollMenu'), 0.7);

		curOption?.onDeselected.dispatch();

		curOption = list[curOptionSelected];

		curOption?.onSelected.dispatch();
	}

	function onAccept():Void
	{
		curOption?.onAccept.dispatch();
	}
}
