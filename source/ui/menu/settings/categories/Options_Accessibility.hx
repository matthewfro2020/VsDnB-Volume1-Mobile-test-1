package ui.menu.settings.categories;

import data.language.LanguageManager;
import play.save.Preferences;
import ui.menu.settings.SettingsMenu.CheckboxOption;

class Options_Accessibility extends SettingsCategory
{
	public override function init()
	{
		var checkbox_flashingLights = new CheckboxOption(400, 300, {
			name: LanguageManager.getTextString('settings_accessibility_flashingLights'),
			description: LanguageManager.getTextString('settings_accessibility_flashingLights_description'),
			callback: function(value:Bool)
			{
				Preferences.flashingLights = value;
			}
		});
		checkbox_flashingLights.setChecked(Preferences.flashingLights, false, true);
		list.push(checkbox_flashingLights);
		add(checkbox_flashingLights);

		var checkbox_cameraShaking = new CheckboxOption(400, 400, {
			name: LanguageManager.getTextString('settings_accessibility_cameraShaking'),
			description: LanguageManager.getTextString('settings_accessibility_cameraShaking_description'),
			callback: function(value:Bool)
			{
				Preferences.cameraShaking = value;
			}
		});
		checkbox_cameraShaking.setChecked(Preferences.cameraShaking, false, true);
		list.push(checkbox_cameraShaking);
		add(checkbox_cameraShaking);

		var checkbox_cameraNoteMovement = new CheckboxOption(400, 500, {
			name: LanguageManager.getTextString('settings_accessibility_camNoteMove'),
			description: LanguageManager.getTextString('settings_accessibility_camNoteMove_description'),
			callback: function(value:Bool)
			{
				Preferences.cameraNoteMovement = value;
			}
		});
		checkbox_cameraNoteMovement.setChecked(Preferences.cameraNoteMovement, false, true);
		list.push(checkbox_cameraNoteMovement);
		add(checkbox_cameraNoteMovement);
	}

	override function getName():String
	{
		return LanguageManager.getTextString('settings_category_accessibility');
	}
}
