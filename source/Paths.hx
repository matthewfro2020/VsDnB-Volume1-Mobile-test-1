package;

import play.song.Song;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxSoundAsset;
import haxe.io.Path;
import openfl.media.Sound;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import util.tools.Preloader;
import play.save.Preferences;

/**
 * A core classed used for accessing the paths, and file locations for image, sounds, etc.
 */
class Paths
{
	/**
	 * The extension to use for sounds.
	 * Defaults to ogg, as the game doesn't have web browser support. 
	 */
	public static inline var SOUND_EXT = 'ogg';

	/**
	 * Is this game using a language other than English?
	 * @return Whether the game's using a non-english language.
	 */
	public static function isLocale():Bool
	{
		return Preferences.language !='en-US';
	}
	
	/**
	 * Retrieves the file path for the language file used to parse languages.
	 * @return The path for the language file.
	 */
	public static function langaugeFile():String
	{
		return getPath('locale/languages.txt', TEXT, 'preload');
	}
	
	/**
	 * Retrieves the library from an OpenFL asset path.
	 * @param path The path to get the library from.
	 * @return The library name.
	 */
	public static function stripLibrary(path:String):String
	{
		return (path.split(':').length > 0) ? path.split(':')[0] : '';
	}

	/**
	 * Strips the real path from an asset path. 
	 * @param path The asset path to get the relative path from.
	 * @return The path.
	 */
	public static function absolutePath(path:String):String // literally like murder drones
	{
		return (path.split(':').length > 0) ? path.split(':')[1] : path;
	}

	/**
	 * Returns a path given a library, if it exists.
	 * @param file The path to get.
	 * @param type The OpenFL asset type of the file.
	 * @param library The library of the file, normally defaults to either the preload, or shared path.
	 */
	static function getPath(file:String, type:AssetType, library:Null<String>)
	{
		if (library != null)
		{
			return getLibraryPath(file, library);
		}
		else
		{
			var sharedPath:String = getLibraryPathForce(file, 'shared');
			if (OpenFlAssets.exists(sharedPath, type))
			{
				return sharedPath;
			}
		}
		return getPreloadPath(file);
	}

	/**
	 * Returns the path of a file relative to the given library.
	 * @param file The file path to retrieve the path for.
	 * @param library The library to use.
	 */
	public static function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	/**
	 * Retrieves the constant path for a file from a given library.
	 * @param file The file path to retrieve the path for.
	 * @param library The library to use.
	 */
	static inline function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	/**
	 * Retrieves path for a file from the preload library.
	 * @param file The file path to retrieve the path for.
	 */
	static inline function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	/**
	 * Retrieves a graphic asset from a path, and a given library.
	 * @param key The image's path.
	 * @param library The library the image is in.
	 * @return The image asset path.
	 */
	public static inline function image(key:String, ?library:String):FlxGraphic
	{
		var assetPath:String = imagePath(key, library);
		var graphic:FlxGraphic = null;

		// Graphic is already cached, just return the cached asset.
		if (Preloader.trackedGraphics.exists(assetPath))
		{
			graphic = Preloader.trackedGraphics.get(assetPath);
		}
		else if (Preloader.previousTrackedGraphics.exists(assetPath))
		{
			// Graphic was previously cached, retrieve it, and return that.
			graphic = cast Preloader.fetchFromPreviousCache(assetPath, IMAGE);
		}
		
		if (graphic == null)
		{
			// Load a new graphic, and then cache it.
			graphic = Preloader.cacheImage(assetPath);
		}
		return graphic;
	}

	/**
	 * Returns the asset path for an image.
	 * @param key The key of the graphic asset.
	 * @param library The library the graphic asset is in.
	 */
	public static function imagePath(key:String, ?library:String)
	{
		var assetPath:String = getPath('images/$key.png', IMAGE, library);
		if (isLocale())
		{
			var langaugeAssetPath = getPath('locale/${Preferences.language}/images/$key.png', IMAGE, library);
			if (OpenFlAssets.exists(langaugeAssetPath))
			{
				assetPath = langaugeAssetPath;
			}
		}
		return assetPath;
	}
	
	/**
	 * Retrieves a sound asset path from a given path, and library.
	 * @param key The path the sound asset is in.
	 * @param library The library the sound asset is in.
	 * @return A new `FlxSoundAsset`
	 */
	public static function sound(key:String, ?library:String, parentPath:String = 'sounds/', ?type:AssetType = SOUND):Sound
	{
		var assetPath:String = soundPath(key, library, parentPath, type);
		var sound:Sound = retrieveSound(assetPath, type);

		return sound;
	}

	/**
	 * Retrieves a random sound from a list of minimum, maximum, and given path.
	 * @param key The path the sound is located.
	 * @param min The minimum range value.
	 * @param max The maximum range value.
	 * @param library The library the sound asset is located at.
	 * @return A `FlxSoundAsset`
	 */
	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String):FlxSoundAsset
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	/**
	 * Retrieves a music sound asset path from a given path, and library.
	 * @param key The path the sound asset is in.
	 * @param library The library the sound asset is in.
	 * @return A new `FlxSoundAsset`
	 */
	public static inline function music(key:String, ?library:String)
	{
		return sound(key, library, 'music/', MUSIC);
	}

	/**
	 * Retrieves the instrumental audio file for a song.
	 * @param song The song to file for.
	 * @return The instrumental `Sound` object.
	 */
	public static inline function inst(song:String, ?variationId:String, suffix:String = ''):Sound
	{
		var instPath:String = instPath(song, variationId, suffix);
		var sound:Sound = retrieveSound(instPath, MUSIC);

		return sound;
	}

	/**
	 * Returns the path for an instrumental's sound asset from the given parameters.
	 * @param song The song to get the instrumental for.
	 * @param variationId The song's variation. 
	 * @param suffix (Optional) Additional suffix to add at the end.
	 * @return The instrumental's asset path.
	 */
	public static function instPath(song:String, ?variationId:String, suffix:String = ''):String
	{
		var variation:String = Song.validateVariationPath(variationId);

		return soundPath('${song.toLowerCase()}/Inst${variation}${suffix}', 'songs', '', MUSIC);
	}

	/**
	 * Retrieves the voices sound file for a song.
	 * @param song The song to file for.
	 * @return The voices `Sound` object.
	 */
	public static inline function voices(song:String, ?variationId:String, suffix:String = ''):Sound
	{
		var voicesPath:String = voicesPath(song, variationId, suffix);
		var sound:Sound = retrieveSound(voicesPath, SOUND);
		return sound;
	}

	/**
	 * Returns the path for a voices sound asset from the given parameters.
	 * @param song The song to get the voices for.
	 * @param variationId The song's variation. 
	 * @param suffix (Optional) Additional suffix to add at the end.
	 * @return The voices asset path.
	 */
	public static inline function voicesPath(song:String, ?variationId:String, suffix:String = ''):String
	{
		var variation:String = Song.validateVariationPath(variationId);

		return soundPath('${song.toLowerCase()}/Voices${variation}${suffix}', 'songs', '', SOUND);
	}

	/**
	 * Returns the asset path for a sound.
	 * @param key The key of the sound asset.
	 * @param library The library the sound asset is in.
	 */
	public static function soundPath(key:String, ?library:String, ?parentPath:String = 'sounds/', ?type:AssetType = SOUND)
	{
		var assetPath:String = getPath('${parentPath}$key.$SOUND_EXT', type, library);
		if (isLocale())
		{
			var langaugeAssetPath = getPath('locale/${Preferences.language}/${parentPath}$key.$SOUND_EXT', type, library);
			if (OpenFlAssets.exists(langaugeAssetPath))
			{
				assetPath = langaugeAssetPath;
			}
		}
		return assetPath;
	}

	/**
	 * Loads, or retrieves a sound asset from the cache.
	 * @param key The key of the sound asset.
	 * @param type The type of asset the sound is.
	 * @return A new `Sound` object.
	 */
	static function retrieveSound(key:String, type:AssetType):Sound
	{
		var sound:Sound = null;

		// Sound is already cached, just return the cached asset.
		if (Preloader.trackedSounds.exists(key))
		{
			sound = Preloader.trackedSounds.get(key);
		}
		else if (Preloader.previousTrackedSounds.exists(key))
		{
			// Sound was previously cached, retrieve it, and return that.
			sound = cast Preloader.fetchFromPreviousCache(key, type);
		}

		if (sound == null)
		{
			// Load a new sound, and then cache it.
			sound = Preloader.cacheSound(key);
		}
		return sound;
	}

	/**
	 * Retrieves the path for a file from it's asset type, and library.
	 * @param file The file to retrieve.
	 * @param type The file's OpenFL's asset type.
	 * @param library The library the file's located in.
	 */
	public static inline function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		var assetReturnPath:String = getPath(file, type, library);
		if (isLocale())
		{
			var langaugeReturnPath:String = getPath('locale/${Preferences.language}/' + file, type, library);
			if (OpenFlAssets.exists(langaugeReturnPath))
			{
				assetReturnPath = langaugeReturnPath;
			}
		}
		return assetReturnPath;
	}

	/**
	 * Retrieves the path for a text file from it's library.
	 * @param key The file to retrieve.
	 * @param library The library the text file's located in.
	 */
	public static inline function txt(key:String, ?library:String):String
	{
		var assetReturnPath:String = getPath('data/$key.txt', TEXT, library);
		if (isLocale())
		{
			var langaugeReturnPath:String = getPath('locale/${Preferences.language}/data/$key.txt', TEXT, library);
			if (OpenFlAssets.exists(langaugeReturnPath))
			{
				assetReturnPath = langaugeReturnPath;
			}
		}
		return assetReturnPath;
	}

	/**
	 * Retrieves a collection of sparrow atlas frames from an asset path, and a given library.
	 * The image and XML file should be in the same file directory location.
	 * 
	 * @param key The frame's path.
	 * @param library The library the frames are located in.
	 * @return A collection of frames of type SparrowAtlas.
	 */
	public inline static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	/**
	 * Retrieves a collection of packer atlas frames from an asset path, and a given library.
	 * The image and XML file should be in the same file directory location.
	 * 
	 * @param key The frame's path.
	 * @param library The library the frames are located in.
	 * @return A collection of frames of type PackerAtlas.
	 */
	public inline static function getPackerAtlas(key:String, ?library:String)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	/**
	 * Retrieves the file path for an FlxAnimate atlas file.
	 * @param key The path the atlas is located in.
	 * @param library The library the atlas is in.
	 * @return The file location the atlas is at.
	 */
	public inline static function atlas(key:String, ?library:String):String
	{
		return Path.withoutExtension(imagePath(key, library));
	}

	/**
	 * Retrieves the path for a font.
	 * @param key The font name.
	 * @return The asset path for the font.
	 */
	public static inline function font(key:String):String
	{
		return 'assets/fonts/$key';
	}

	/**
	 * Retrieves the asset path for a video.
	 * @param key The relative path, and name for the video.
	 * @param library The library the video is in.
	 * @return The video's asset path.
	 */
	public inline static function video(key:String, ?library:String):String
	{
		return getPath('videos/$key.mp4', BINARY, library);
	}

	/**
	 * Retrieves an asset path from the `data` folder.
	 * @param key The file path to get.
	 * @param library The library the file is at.
	 * @return The asset path for the requested file.
	 */
	public static inline function data(key:String, ?library:String):String
	{
		return getPath('data/$key', TEXT, library);
	}

	/**
	 * Retrieves the offset file for a given character.
	 * @param character The character to get the offset file for.
	 * @return The asset path for the offset file.
	 */
	public static function offsetFile(character:String):String
	{
		return getPath('data/offsets/$character.txt', TEXT, 'preload');
	}

	/**
	 * Retrieves a json asset path from the `data` folder.
	 * @param key The relative path for the json file.
	 * @param library The library the file is at.
	 * @return The asset path for the json file.
	 */
	public static inline function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	/**
	 * Retrieves the json asset path for a chart.
	 * @param key The relative path for the chart file.
	 * @param library The library the chart is at.
	 * @return The asset path for the chart file.
	 */
	public static inline function chart(key:String, ?library:String):String
	{
		return getPath('data/charts/$key.json', TEXT, library);
	}

	/**
	 * Retrieves the asset path for an HScript file.
	 * @param key The relative path for the script file.
	 * @param library The library the script file is at.
	 * @return The script asset path.
	 */
	public static inline function script(key:String, ?library:String):String
	{
		return getPath('data/scripts/${key}', TEXT, library);
	}

	/**
	 * Retrieves the asset path for a glsl frag file.
	 * @param key The key for the frag file.
	 * @param library The library the frag file is at.
	 * @return The asset path for the offset file.
	 */
	public static inline function frag(key:String, ?library:String)
	{
		return getPath('data/shaders/${key}.frag', TEXT, library);
	}
}
