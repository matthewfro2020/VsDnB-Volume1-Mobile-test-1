package ui.menu.settings.categories;

import data.language.LanguageManager;
import play.save.Preferences;
import ui.menu.settings.SettingsMenu.CallbackOption;
import ui.menu.settings.SettingsMenu.CheckboxOption;

class Options_General extends SettingsCategory
{
	public override function init()
	{
		var checkbox_downscroll = new CheckboxOption(400, 300, {
			name: LanguageManager.getTextString('settings_general_downscroll'),
			description: LanguageManager.getTextString('settings_general_downscroll_description'),
			callback: function(value:Bool)
			{
				Preferences.downscroll = value;
			}
		});
		checkbox_downscroll.setChecked(Preferences.downscroll, false, true);
		list.push(checkbox_downscroll);
		add(checkbox_downscroll);

		var checkbox_ghostTapping = new CheckboxOption(400, 400, {
			name: LanguageManager.getTextString('settings_general_ghostTapping'),
			description: LanguageManager.getTextString('settings_general_ghostTapping_description'),
			callback: function(value:Bool)
			{
				Preferences.ghostTapping = value;
			}
		});
        checkbox_ghostTapping.setChecked(Preferences.ghostTapping, false, true);
		list.push(checkbox_ghostTapping);
		add(checkbox_ghostTapping);

		var checkbox_cutscenes = new CheckboxOption(400, 500, {
			name: LanguageManager.getTextString('settings_general_cutscenes'),
			description: LanguageManager.getTextString('settings_general_cutscenes_description'),
			callback: function(value:Bool)
			{
				Preferences.cutscenes = value;
			}
		});
		checkbox_cutscenes.setChecked(Preferences.cutscenes, false, true);
		list.push(checkbox_cutscenes);
		add(checkbox_cutscenes);

        // ==========================================================
        // ▶ BOTPLAY OPTION (NEW)
        // ==========================================================
		var checkbox_botplay = new CheckboxOption(400, 550, {
			name: LanguageManager.getTextString('settings_general_botplay'),
			description: LanguageManager.getTextString('settings_general_botplay_description'),
			callback: function(value:Bool)
			{
				Preferences.botplay = value;
			}
		});
		checkbox_botplay.setChecked(Preferences.botplay, false, true);
		list.push(checkbox_botplay);
		add(checkbox_botplay);
        // ==========================================================

		var option_keybinds = new CallbackOption(400, 650, {
			name: LanguageManager.getTextString('settings_general_keybinds'),
			description: LanguageManager.getTextString('settings_general_keybinds_description'),
			callback: function()
			{
				parent.canInteract = false;
				parent.openKeybindsMenu();
			}
		});
		list.push(option_keybinds);
		add(option_keybinds);
	}
	
	override function getName():String
	{
		return LanguageManager.getTextString('settings_category_general');
	}
}
