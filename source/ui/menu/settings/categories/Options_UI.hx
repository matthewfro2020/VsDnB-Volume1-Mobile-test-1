package ui.menu.settings.categories;

import data.language.LanguageManager;
import play.save.Preferences;
import ui.menu.settings.SettingsMenu.CheckboxOption;
import ui.menu.settings.SettingsMenu.SelectOption;

class Options_UI extends SettingsCategory
{
	var checkbox_minimalUI:CheckboxOption;
	var checkbox_debugUI:CheckboxOption;
	var select_timerType:SelectOption;
	var checkbox_warnings:CheckboxOption;

	public override function init()
	{
		checkbox_minimalUI = new CheckboxOption(400, 300, {
			name: LanguageManager.getTextString('settings_ui_minimalUI'),
			description: LanguageManager.getTextString('settings_ui_minimalUI_description'),
			callback: function(value:Bool)
			{
				Preferences.minimalUI = value;
				Main.fps.visible = value ? false : checkbox_debugUI.checked;

				checkbox_debugUI.canInteract = !Preferences.minimalUI;
				select_timerType.canInteract = !Preferences.minimalUI;
				checkbox_warnings.canInteract = !Preferences.minimalUI;
			}
		});
		list.push(checkbox_minimalUI);
		add(checkbox_minimalUI);

		checkbox_debugUI = new CheckboxOption(400, 400, {
			name: LanguageManager.getTextString('settings_ui_debugUI'),
			description: LanguageManager.getTextString('settings_ui_debugUI_description'),
			callback: function(value:Bool)
			{
				Preferences.debugUI = value;
			}
		});
		checkbox_debugUI.setChecked(Preferences.debugUI, false, true);
		checkbox_debugUI.canInteract = !Preferences.minimalUI;
		list.push(checkbox_debugUI);
		add(checkbox_debugUI);

		select_timerType = new SelectOption(400, 500, {
			name: LanguageManager.getTextString('settings_ui_timerType'),
			description: LanguageManager.getTextString('settings_ui_timerType_description'),
			options: [
				LanguageManager.getTextString('settings_ui_timerType_timeLeft'),
				LanguageManager.getTextString('settings_ui_timerType_timeElapsed'),
				LanguageManager.getTextString('settings_ui_timerType_timeElapsedLeft'),
			],
			optionsID: ['timeLeft', 'timeElapsed', 'elapsedAndLeft'],
			selectCallback: function(value:String)
			{
				Preferences.timerType = value;
			}
		});
		select_timerType.setSelectedOption(Preferences.timerType, false);
		select_timerType.canInteract = !Preferences.minimalUI;
		list.push(select_timerType);
		add(select_timerType);

		checkbox_warnings = new CheckboxOption(400, 600, {
			name: LanguageManager.getTextString('settings_ui_warnings'),
			description: LanguageManager.getTextString('settings_ui_warnings_description'),
			callback: function(value:Bool)
			{
				Preferences.gimmickWarnings = value;
			}
		});
		checkbox_warnings.setChecked(Preferences.gimmickWarnings, false, true);
		checkbox_warnings.canInteract = !Preferences.minimalUI;
		list.push(checkbox_warnings);
		add(checkbox_warnings);

		// Need to do this last so everything is initalized.
		checkbox_minimalUI.setChecked(Preferences.minimalUI, false, true);
	}
	
	override function getName():String
	{
		return LanguageManager.getTextString('settings_category_ui');
	}
}
