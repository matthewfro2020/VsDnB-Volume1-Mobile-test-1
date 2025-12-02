package play.subtitle;

// Has to be imported or else a compile error will happen.
import play.subtitle.ScriptedSubtitle;

import backend.Conductor;
import data.IRegistryEntry;
import data.subtitle.SubtitleData;
import data.subtitle.SubtitleRegistry;
import flixel.group.FlxSpriteGroup;
import play.subtitle.Subtitle;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import scripting.IScriptedClass.IPlayStateScriptedClass;

/**
 * A container that stores a list of subtitles for it's specific entry.
 * 
 * Users can further extend this class to customize the way this subtitle container looks in-game.
 */
class SubtitleManager extends FlxSpriteGroup implements IRegistryEntry<SongSubtitleData> implements IPlayStateScriptedClass
{
    /**
     * The id of the entry.
     */
    public final id:String;

	/**
	 * The data for this subtitle container.
	 */
	var _data:SongSubtitleData;

	/**
	 * The scripted class that subtitles are initalized from.
	 * If the subtitle has it's own special scripted class, that is used instead.
	 * @return Null<String>
	 */
	public var subtitleScriptClass(get, never):Null<String>;
	
	function get_subtitleScriptClass():Null<String>
	{
		return _data?.scriptClass ?? null;
	}

	/**
	 * The sounds that'll when subtitles are being typed out.
	 * If the subtitle has it's own special sounds, that is used instead.
	 * @return Null<Array<String>>
	 */
	public var subtitleSounds(get, never):Null<Array<String>>;
	
	function get_subtitleSounds():Null<Array<String>>
	{
		return _data?.sounds ?? null;
	}

	/**
	 * A list of all of the remaining subtitles for this container to show.
	 */
	var songSubtitles:Array<SubtitleData> = [];

	/**
	 * The conductor that this subtitle container is running on.
	 * The container will check if the conductor is at the subtitle's given time based on this conductor.
	 */
	var conductor(get, set):Conductor;

	/**
	 * A group used to contain all of the subtitles that appear on this sprite.
	 */
	var subtitlesGroup:FlxTypedSpriteGroup<Subtitle> = new FlxTypedSpriteGroup<Subtitle>();

	function get_conductor():Conductor
	{
		if (_conductor == null)
			_conductor = Conductor.instance;

		return _conductor;
	}

	function set_conductor(value:Conductor)
	{
		return _conductor = value;
	}

	var _conductor:Conductor;
	
	public function new(id:String)
	{
		super();

		this.id = id;
		_data = fetchData(id);
		
		add(subtitlesGroup);
	}

    public function onCreate(event:ScriptEvent):Void
	{
		this.revive();

		// Initalize the subtitles when this container is created.
		songSubtitles = getDataSubtitles().copy();
		
		// Clear any existing subtitles.
		subtitlesGroup.clear();
	}

    public function onUpdate(event:UpdateScriptEvent):Void
	{
		if (songSubtitles.length > 0)
		{
			if (conductor.songPosition > songSubtitles[0].time * 1000.0)
			{
				var subtitle:SubtitleData = songSubtitles.shift();
				addSubtitle(subtitle);
			}
		}
	}

	public function onDestroy(e:ScriptEvent)
	{
		songSubtitles = [];

		subtitlesGroup.clear();
	}
	
    public function onScriptEvent(event:ScriptEvent):Void
	{
		// Make sure any subtitles currently rendering get received script functions this container does as well.
		subtitlesGroup.forEach((subtitle:Subtitle) ->
		{
			if (subtitle != null)
			{
				ScriptEventDispatcher.callEvent(subtitle, event);
			}
		});
	}

	/**
	 * Adds a subtitle to the manager.
	 * @param data The subtitle to add.
	 */
	public function addSubtitle(data:SubtitleData)
	{
		var subtitle:Subtitle = null;
		var scriptClass:Null<String> = data.scriptClass ?? subtitleScriptClass ?? null;
		if (scriptClass != null)
		{
			subtitle = ScriptedSubtitle.init(scriptClass, data, this);
		}
		else
		{
			subtitle = new Subtitle(data, this);
		}
		subtitlesGroup.add(subtitle);
		subtitle.startSubtitle();
	}

	/**
	 * Called when a subtitle has finished.
	 * @param subtitle The subtitle that was completed.
	 */
	public function onSubtitleComplete(subtitle:Subtitle)
	{
		subtitlesGroup.remove(subtitle);
	}

	function getDataSubtitles():Array<SubtitleData>
	{
		return _data?.subtitles ?? [];
	}

    /**
     * Retrieves the data for this entry.
     * @param id The id of the entry.
     * @return The data object for this entry.
     */
    public function fetchData(id:String):SongSubtitleData
	{
		return SubtitleRegistry.instance.parseEntryDataWithMigration(id);
	}

    /**
     * Destroys this data object.
     */
    override function destroy():Void
	{
		songSubtitles = [];

		for (subtitle in subtitlesGroup)
		{
			subtitlesGroup.remove(subtitle);
			
			subtitle.destroy();
			subtitle = null;
		}
		subtitlesGroup.clear();

		super.destroy();
	}

    /**
     * Returns a string representation of this entry.
     * @return String
     */
    override function toString():String
	{
		return 'SubtitleManager(id=$id)';
	}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}

    public function onStepHit(event:ConductorScriptEvent):Void {}
    public function onBeatHit(event:ConductorScriptEvent):Void {}
    public function onMeasureHit(event:ConductorScriptEvent):Void {}
    
    public function onTimeChangeHit(event:ConductorScriptEvent):Void {}

    public function onCreatePost(event:ScriptEvent):Void {}
    public function onCreateUI(event:ScriptEvent):Void {}

    public function onSongStart(event:ScriptEvent):Void {}
    public function onSongLoad(event:ScriptEvent):Void {}
    public function onSongEnd(event:ScriptEvent):Void {} 

    public function onPause(event:ScriptEvent):Void {}
    public function onResume(event:ScriptEvent):Void {}

    public function onPressSeven(event:ScriptEvent):Void {}
    
    public function onGameOver(event:ScriptEvent):Void {}

    public function onCountdownStart(event:CountdownScriptEvent):Void {}
    public function onCountdownTick(event:CountdownScriptEvent):Void {}
    public function onCountdownTickPost(event:CountdownScriptEvent):Void {}
    public function onCountdownFinish(event:CountdownScriptEvent):Void {}

    public function onCameraMove(event:CameraScriptEvent):Void {}
    public function onCameraMoveSection(event:CameraScriptEvent):Void {}
    
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void {}
	
    public function onNoteSpawn(event:NoteScriptEvent):Void {}
    public function onOpponentNoteHit(event:NoteScriptEvent):Void {}
    public function onPlayerNoteHit(event:NoteScriptEvent):Void {}
    public function onNoteMiss(event:NoteScriptEvent):Void {}
	
    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void {}
}
