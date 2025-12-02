package ui.menu.settings.categories;

import data.language.LanguageManager;
import audio.GameSound;
import play.save.Preferences;
import ui.menu.settings.SettingsMenu.SliderOption;

class Options_Audio extends SettingsCategory
{
	var voiceTest:GameSound;
	var hitsound:GameSound;
	var sfxInteract:GameSound;

	public override function init()
	{
		voiceTest = new GameSound(VOICES).load(Paths.sound('settings/slider_voicetest'));
		SoundController.add(voiceTest);

		hitsound = new GameSound().load(Paths.sound('note_click', 'shared'));
		SoundController.add(hitsound);

		sfxInteract = new GameSound().load(Paths.sound('settings/slider_sfxtest'));
		SoundController.add(sfxInteract);

		var slider_master = new SliderOption(300, 300, {
			name: LanguageManager.getTextString('settings_audio_masterVolume'),
			description: LanguageManager.getTextString('settings_audio_masterVolume_description'),
			min: 0.00,
			max: 1.00,
			callback: function(value:Float)
			{
				Preferences.masterVolume = value;
			}
		});
		slider_master.setValue(Preferences.masterVolume);
		list.push(slider_master);
		add(slider_master);

		var slider_music = new SliderOption(300, 375, {
			name: LanguageManager.getTextString('settings_audio_musicVolume'),
			description: LanguageManager.getTextString('settings_audio_musicVolume_description'),
			min: 0.00,
			max: 1.00,
			callback: function(value:Float)
			{
				Preferences.musicVolume = value;
			}
		});
		slider_music.setValue(Preferences.musicVolume);
		list.push(slider_music);
		add(slider_music);

		var slider_voices = new SliderOption(300, 450, {
			name: LanguageManager.getTextString('settings_audio_voices'),
			description: LanguageManager.getTextString('settings_audio_voices_description'),
			min: 0.00,
			max: 1.00,
			callback: function(value:Float)
			{
				Preferences.voicesVolume = value;
			}
		});
		slider_voices.slider.onPress.add(function()
		{
			if (!voiceTest?.playing ?? false)
			{
				voiceTest?.play(true);
			}
		});
		slider_voices.slider.onRelease.add(function()
		{
			voiceTest?.stop();
		});
		slider_voices.onDeselected.add(function()
		{
			voiceTest?.stop();
		});
		slider_voices.setValue(Preferences.voicesVolume);
		list.push(slider_voices);
		add(slider_voices);

		var slider_sfx = new SliderOption(300, 525, {
			name: LanguageManager.getTextString('settings_audio_sfx'),
			description: LanguageManager.getTextString('settings_audio_sfx_description'),
			min: 0.00,
			max: 1.00,
			callback: function(value:Float)
			{
				Preferences.sfxVolume = value;
			}
		});
		slider_sfx.slider.onPress.add(function()
		{
			if (!sfxInteract?.playing ?? false)
			{
				sfxInteract?.play(true);
			}
		});
		slider_sfx.slider.onRelease.add(function()
		{
			sfxInteract?.stop();
		});
		slider_sfx.onDeselected.add(function()
		{
			sfxInteract?.stop();
		});
		slider_sfx.setValue(Preferences.sfxVolume);
		list.push(slider_sfx);
		add(slider_sfx);

		var slider_hitsounds = new SliderOption(300, 600, {
			name: LanguageManager.getTextString('settings_audio_hitsounds'),
			description: LanguageManager.getTextString('settings_audio_hitsounds_description'),
			min: 0.00,
			max: 1.00,
			callback: function(value:Float)
			{
				Preferences.hitsoundsVolume = value;
			}
		});
		slider_hitsounds.slider.onPress.add(function()
		{
			hitsound.volume = Preferences.hitsoundsVolume;
			if (!hitsound?.playing ?? false)
			{
				hitsound?.play(true);
			}
		});
		slider_hitsounds.slider.onRelease.add(function()
		{
			hitsound?.stop();
		});
		slider_hitsounds.onDeselected.add(function()
		{
			hitsound?.stop();
		});
		slider_hitsounds.setValue(Preferences.hitsoundsVolume);
		list.push(slider_hitsounds);
		add(slider_hitsounds);
	}

	override function getName():String
	{
		return LanguageManager.getTextString('settings_category_audio');
	}

	override function destroy()
	{
		super.destroy();

		for (sound in [voiceTest, hitsound, sfxInteract])
		{
			sound.destroy();
			sound = null;
			SoundController.remove(sound);
		}
	}
}
