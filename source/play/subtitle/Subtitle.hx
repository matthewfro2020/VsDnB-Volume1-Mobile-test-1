package play.subtitle;

import data.language.LanguageManager;
import scripting.events.ScriptEvent;
import audio.GameSound;
import data.subtitle.SubtitleData;
import flixel.FlxG;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.addons.text.FlxTypeText;
import play.subtitle.SubtitleManager;
import scripting.IScriptedClass.IPlayStateScriptedClass;

/**
 * A UI element used to display text in-case a player is speaking.
 * 
 * Users can extend this class and pass a scripted class into the container's entry data to customize how this subtitle looks, and behaves.
 */
class Subtitle extends FlxTypeText implements IPlayStateScriptedClass
{
	/**
	 * The data used to initalize this subtitle.
	 */
	var data:SubtitleData;

	/**
	 * The manager this Subtitle belongs to.
	 */
	public var manager:SubtitleManager;

	/**
	 * Initalize a new Subtitle.
	 * 
	 * @param data The data this subtitle belongs to.
	 * @param manager The manager this subtitle is contained to.
	 */
	public function new(data:SubtitleData, manager:SubtitleManager)
	{
		this.data = data;
		this.manager = manager;

		var subtitleText = LanguageManager.getTextString(data.key, LanguageManager.currentSubtitlesList);

		super(data.x, data.y, FlxG.width, subtitleText, data.subtitleSize);
		
		setup();
	}

	/**
	 * Constructs this subtitle based on the given data.
	 */
	public function setup():Void
	{
		var soundsToLoad:Null<Array<String>> = null;
		if (manager.subtitleSounds != null && manager.subtitleSounds.length > 0)
		{
			soundsToLoad = manager.subtitleSounds.copy();	
		}
		if (data.sounds != null && data.sounds.length > 0)
		{
			soundsToLoad = data.sounds.copy();
		}

		sounds = if (soundsToLoad == null || soundsToLoad.length == 0)
		{
			null;
		}
		else
		{
			[for (sound in soundsToLoad) new GameSound().load(Paths.sound(sound))];
		}
		setFormat("Comic Sans MS Bold", data.subtitleSize, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		borderSize = 2;

		if (data.centerScreen)
		{
			screenCenter(data.screenCenterAxis);
		}
	}

	/**
	 * Start the subtitle typing process of this subtitle.
	 */
	public function startSubtitle():Void
	{
		start(data.typeSpeed, false, false, [], function()
		{
			beginSubtitleEnd();
		});
	}

	public function beginSubtitleEnd():Void
	{
		new FlxTimer().start(data.duration, function(timer:FlxTimer)
		{
			FlxTween.tween(this, {alpha: 0}, 0.5, {
				onComplete: function(tween:FlxTween)
				{
					manager.onSubtitleComplete(this);
				}
			});
		});
	}
	
    public function onCreate(event:ScriptEvent):Void {}
    public function onUpdate(event:UpdateScriptEvent):Void {}
    public function onDestroy(event:ScriptEvent):Void {}

    public function onScriptEvent(event:ScriptEvent):Void {}
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