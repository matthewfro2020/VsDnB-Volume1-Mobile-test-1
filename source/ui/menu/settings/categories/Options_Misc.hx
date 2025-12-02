package ui.menu.settings.categories;

import data.song.Highscore;
import data.language.LanguageManager;
import flixel.FlxG;
import flixel.addons.transition.FlxTransitionableState;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import ui.intro.InitState;
import ui.intro.TitleState;
import ui.menu.settings.SettingsMenu.SelectOption;
import ui.menu.settings.SettingsMenu.CallbackOption;
import ui.menu.settings.SettingsMenu.CheckboxOption;
import ui.menu.settings.SettingsMenu.NumericStepperOption;
import ui.menu.settings.components.ResetDataPrompt.Prompt;
import play.save.Preferences;
import play.song.SongModuleHandler;
import scripting.module.ModuleHandler;

class Options_Misc extends SettingsCategory
{
	static var selectedLanguage:Null<String>;

	var prompt:Prompt;
	var option_resetData:CallbackOption;
	var restartGame:FlxText;

	public override function init()
	{
		// Cache the user's current language to use for later.
		if (selectedLanguage == null)
		{
			selectedLanguage = Preferences.language;
		}

		var checkbox_hitsounds = new CheckboxOption(400, 300, {
			name: LanguageManager.getTextString('settings_misc_hitsounds'),
			description: LanguageManager.getTextString('settings_misc_hitsounds_description'),
			callback: function(value:Bool)
			{
				Preferences.hitsounds = value;
			}
		});
		checkbox_hitsounds.setChecked(Preferences.hitsounds, false, true);
		list.push(checkbox_hitsounds);
		add(checkbox_hitsounds);

		var option_latencyOffsets = new NumericStepperOption(425, 400, {
			name: LanguageManager.getTextString('settings_misc_latencyOffsets'),
			description: LanguageManager.getTextString('settings_misc_latencyOffsets_description'),
			min: -2000,
			max: 2000,
			stepper: 1,
			changeTimer: 0.01,
			holdThreshold: 0.5,
			callback: function(value:Float)
			{
				Preferences.latencyOffsets = Std.int(value);
			}
		});
		option_latencyOffsets.setValue(Preferences.latencyOffsets);
		list.push(option_latencyOffsets);
		add(option_latencyOffsets);

		var languages = LanguageManager.getLanguages();

		var select_changeLanguage = new SelectOption(400, 500, {
			name: LanguageManager.getTextString('settings_misc_language'),
			description: LanguageManager.getTextString('settings_misc_language_description'),
			options: [for (language in languages) LanguageManager.getTextString(language.id)],
			optionsID: [for (language in languages) language.id],
			selectCallback: function(value:String)
			{
				selectedLanguage = value;

				var needsRestart:Bool = selectedLanguage != Preferences.language;
				if (needsRestart)
				{
					// The language was changed, the game needs to be restarted.
					FlxG.stage.window.onClose.add(onWindowExit);
				}
				else
				{
					// User selected the same language they had before.
					// The language doesn't need to be reset on exit.
					FlxG.stage.window.onClose.remove(onWindowExit);
				}
				restartGame.visible = needsRestart;
			}
		});
		select_changeLanguage.setSelectedOption(selectedLanguage, false);
		list.push(select_changeLanguage);
		add(select_changeLanguage);
		
		option_resetData = new CallbackOption(400, 600, {
			name: LanguageManager.getTextString('settings_misc_resetData'),
			description: LanguageManager.getTextString('settings_misc_resetData_description'),
			callback: function()
			{
				checkbox_hitsounds.canInteract = false;
				select_changeLanguage.canInteract = false;
				option_resetData.canInteract = false;
				option_latencyOffsets.canInteract = false;

				var prompt = new Prompt(0, 600);
				prompt.yesFunc = function()
				{
					ModuleHandler.clearModules();
					SongModuleHandler.clearModules();
					SongModuleHandler.clearModuleCache();
					
					Highscore.songScores = new Map();

					FlxG.stage.window.onClose.remove(onWindowExit);
					selectedLanguage = null;

					for (save in ['funkin', 'controls', 'preferences'])
					{
						var saveFile:FlxSave = new FlxSave();
						saveFile.bind(save, 'dnbteam');
						saveFile.erase();
						saveFile.close();
					}
					FlxG.save.erase();
					FlxG.save.flush();
					FlxG.save.bind('funkin', 'dnbteam');

					SoundController.music.stop();

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					TitleState.initialized = false;

					FlxG.switchState(() -> new InitState());
				}
				prompt.noFunc = function()
				{
					FlxTween.tween(prompt, {alpha: 0}, 0.5, {
						onComplete: function(tween:FlxTween)
						{
							remove(prompt, true);

							checkbox_hitsounds.canInteract = true;
							select_changeLanguage.canInteract = true;
							option_resetData.canInteract = true;
							option_latencyOffsets.canInteract = true;
						}
					});
				}
				prompt.screenCenter(X);
				add(prompt);
			}
		});
		list.push(option_resetData);
		add(option_resetData);

		restartGame = new FlxText(0, 150, 0, LanguageManager.getTextString('settings_misc_restart'));
		restartGame.setFormat(Paths.font('comic_normal.ttf'), 16, FlxColor.BLACK, FlxTextAlign.CENTER);
		restartGame.screenCenter(X);
		restartGame.visible = selectedLanguage != Preferences.language;
		add(restartGame);
	}

	override function getName():String
	{
		return LanguageManager.getTextString('settings_category_misc');
	}

	static function onWindowExit():Void
	{
		Preferences.language = selectedLanguage;
	}
}
