package play;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;

import lime.app.Promise;
import lime.app.Future;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import haxe.io.Path;

import openfl.utils.Assets;

import ui.MusicBeatState;

import play.PlayState.PlayStateParams;
import play.song.Song;

class LoadingState extends MusicBeatState
{
	static var playStateParams:PlayStateParams;

	inline static var MIN_TIME = 1.0;

	var target:NextState;
	var stopMusic = false;
	var callbacks:MultiCallback;

	var danceLeft = false;

	function new(target:NextState, stopMusic:Bool)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
	}

	public static function loadPlayState(params:PlayStateParams, stopMusic:Bool)
	{
		playStateParams = params;

		loadAndSwitchState(() -> new PlayState(params), stopMusic);
	}

	override function create()
	{
		initSongsManifest().onComplete(function(lib)
		{
			callbacks = new MultiCallback(onLoad);
			var introComplete = callbacks.add("introComplete");

			var targetSongId:String = playStateParams.targetSong.id ?? 'house';
			var targetVariation:String = playStateParams.targetVariation ?? Song.DEFAULT_VARIATION;

			checkLoadSong(getSongPath(targetSongId, targetVariation));

			var voicesPath:String = getVocalPath(targetSongId, targetVariation);

			if (Assets.exists(voicesPath))
				checkLoadSong(voicesPath);

			checkLibrary("shared");

			var fadeTime = 0.5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
		});
	}

	function checkLoadSong(path:String)
	{
		if (!Assets.cache.hasSound(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
			var callback = callbacks.add("song:" + path);
			Assets.loadSound(path).onComplete(function(_)
			{
				callback();
			});
		}
	}

	function checkLibrary(library:String)
	{
		if (Assets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function(_)
			{
				callback();
			});
		}
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		#if debug
		if (FlxG.keys.justPressed.SPACE)
			trace('fired: ' + callbacks.getFired() + " unfired:" + callbacks.getUnfired());
		#end
	}

	function onLoad()
	{
		if (stopMusic && SoundController.music != null)
			SoundController.music.stop();

		FlxG.switchState(target);
	}

	static function getSongPath(id:String, ?variation:String)
	{
		return Paths.instPath(id, variation);
	}

	static function getVocalPath(id:String, ?variation:String)
	{
		return Paths.voicesPath(id, variation);
	}

	inline static public function loadAndSwitchState(target:NextState, stopMusic = false)
	{
		FlxG.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:NextState, stopMusic = false):NextState
	{
		#if NO_PRELOAD_ALL
		var targetSongId:String = playStateParams.targetSong.id;
		var targetVariation:String = playStateParams.targetVariation;
		
		var voicesPath:String = getVocalPath(targetSongId, targetVariation);
		var hasVoices:Bool = Assets.exists(voicesPath);

		var loaded = isSoundLoaded(getSongPath(targetSongId, targetVariation))
			&& (!hasVoices || isSoundLoaded(voicesPath))
			&& isLibraryLoaded("shared");

		if (!loaded)
			return new LoadingState(target, stopMusic);
		#end
		if (stopMusic && SoundController.music != null)
			SoundController.music.stop();

		return target;
	}

	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		return Assets.cache.hasSound(path);
	}

	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}
	#end

	override function destroy()
	{
		super.destroy();

		callbacks = null;
	}

	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
				promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();

	public function new(callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}

	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;

				if (logId != null)
					log('fired $id, $numRemaining remaining');

				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}

	inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}

	public function getFired()
		return fired.copy();

	public function getUnfired()
		return [for (id in unfired.keys()) id];
}
