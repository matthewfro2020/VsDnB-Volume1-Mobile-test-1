package audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;
import play.save.Preferences;

/**
 * The type of sound this sound object is.
 */
enum SoundType
{
	MUSIC;
	VOICES;
	SFX;
}

/**
 * An FlxSound with an additional `SoundType` allowing for volume automation based on what sound it is.
 */
class GameSound extends FlxSound
{
	public var soundType:SoundType = SFX;

	public function new(?soundType:SoundType = SFX)
	{
		this.soundType = soundType;
		super();
	}

	/**
	 * Loads, and returns this sound object based on the given sound asset. Synonym for `loadEmbedded` from FlxSound. 
	 * @param embeddedSound The sound asset to load.
	 * @param looped Whether this sound should loop.
	 * @param autoDestroy Should the sound destroy when completed?
	 * @param onComplete Called when the audio is finished.
	 * @return -> Void):GameSound
	 */
	public function load(embeddedSound:FlxSoundAsset, looped:Bool = false, autoDestroy:Bool = false, ?onComplete:() -> Void):GameSound
	{
		loadEmbedded(embeddedSound, looped, autoDestroy, onComplete);
		return this;
	}

	// Override to take into account the user volume preferences.
	override function updateTransform():Void
	{
		var volumeMultiplier = switch (soundType)
		{
			case MUSIC: Preferences.musicVolume;
			case VOICES: Preferences.voicesVolume;
			case SFX: Preferences.sfxVolume;
		}
		_transform.volume = #if FLX_SOUND_SYSTEM (FlxG.sound.muted ? 0 : 1) * FlxG.sound.volume * #end
			(group != null ? group.volume : 1) * _volume * _volumeAdjust * volumeMultiplier;

		if (_channel != null)
			_channel.soundTransform = _transform;
	}
}
