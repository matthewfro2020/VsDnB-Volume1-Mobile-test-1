package play.ui;

import audio.GameSound.SoundType;
import backend.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import openfl.Assets;
import play.PlayState;
import play.character.Character;
import util.tools.Preloader;
import scripting.IScriptedClass.IEventDispatcher;
import scripting.events.ScriptEvent;

/**
 * A manager for handling the countdown that plays before the song starts.
 */
class Countdown
{
	/**
	 * The camera to display the countdown on.
	 */
	public static var countdownCamera = FlxG.camera;
	
	/**
	 * How the camera behaves while the camera happens.
	 */
	public static var cameraType:CountdownCameraType = ALTERNATE;
	
	/**
	 * Stores the sprite related to each CountdownStep to be accessed if needed.
	 */
	public static var countdownSpriteMap:Map<CountdownStep, FlxSprite> = [];

	/**
	 * Whether the countdown has started.
	 */
	public static var countdownStarted(default, null):Bool = false;

	/**
	 * Whether the countdown is paused or not.
	 */
	public static var paused(default, set):Bool;

	static function set_paused(value:Bool):Bool
	{
		if (countdownTimer != null)
		{
			countdownTimer.active = !value;
		}
		return value;
	}

	static function get_paused():Bool
	{
		return countdownTimer?.active ?? false;
	}

	/**
	 * Whether the countdown has finished.
	 */
	public static var finished(get, null):Bool;

	static function get_finished():Bool
	{
		return countdownTimer?.finished ?? false;
	}

	/**
	 * Signal fired when the countdown has started playing.
	 */
	public static var onStart(default, null):FlxSignal = new FlxSignal();

	/**
	 * Signal fired when the countdown reaches a new step.
	 */
	public static var onIncrement(default, null):FlxTypedSignal<CountdownStep->Void> = new FlxTypedSignal<CountdownStep->Void>();

	/**
	 * Signal fired when the countdown has finished.
	 */
	public static var onFinish(default, null):FlxSignal = new FlxSignal();

	
	/**
	 * The timer used for the countdown.
	 */
	static var countdownTimer(default, null):FlxTimer;

	/**
	 * The current step the countdown is at.
	 */
	static var countdownStep:CountdownStep = START;

	/**
	 * The character associated with this countdown.
	 */
	static var char:Character = null;

	/**
	 * Initalizes the Countdown to be ready for use.
	 * @param char The character to use for the countdown.
	 */
	public static function initalize(char:Character):Void
	{
		Countdown.char = char;
		
		FlxG.console.registerClass(Countdown);
	}

	/**
	 * Starts the countdown.
	 * Caches the sprites first, and initalizes the timer to start.
	 * 
	 * @param skip Whether to skip the countdown entirely.
	 */
	public static function start(skip:Bool = false):Void
	{
		countdownStarted = true;

		if (skip)
		{
			stop();
			onFinish.dispatch();
			return;
		}

		cacheSprites();
		cacheSounds();

		onStart.dispatch();

		countdownTimer = new FlxTimer().start(Conductor.instance.crochet / 1000, function(tmr:FlxTimer)
		{
			increment();

			var eventCancelled:Bool = dispatchCountdownEvent();

			if (eventCancelled)
			{
				pause();
			}
			else
			{
				showCountdownGraphic(countdownStep);
				playCountdownSound(countdownStep);

				switch (countdownStep)
				{
					case THREE, TWO, ONE, GO:
						onIncrement.dispatch(countdownStep);
					case FINISH:
						stop();
						onFinish.dispatch();
					default:
				}

				// Dispatch the post-tick event.
				dispatchEvent(new CountdownScriptEvent(COUNTDOWN_TICK_POST, countdownStep, true));
			}
		}, 5);
	}


	public static function reset():Void
	{
		Conductor.instance.update(-Conductor.instance.crochet * 5, false);
		
		if (countdownTimer != null)
		{
			countdownTimer.cancel();
			countdownTimer.destroy();
			countdownTimer = null;
		}
		countdownSpriteMap = [];
		char = null;

		onStart.removeAll();
		onIncrement.removeAll();
		onFinish.removeAll();

		countdownStep = START;
		countdownStarted = false;
		Countdown.cameraType = ALTERNATE;
	}

	/**
	 * Pauses the countdown as long as it's currently running.
	 * To resume the countdown, simply call `resume()`
	 */
	public static function pause():Void
	{
		paused = true;
	}

	/**
	 * Resumes the countdown as long as it was paused.
	 */
	public static function resume():Void
	{
		paused = false;
	}

	/**
	 * Completely stops the countdown.
	 */
	public static function stop():Void
	{
		if (countdownTimer != null)
		{
			countdownTimer.cancel();
			countdownTimer = null;
		}
		countdownStep = START;
	}

	/**
	 * Shows the graphic for the given step.
	 * @param step The step to show the graphic for.
	 */
	public static function showCountdownGraphic(step:CountdownStep):Void
	{
		var graphic:Null<String> = getCountdownGraphic(step);
		if (graphic == null)
			return;

		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(graphic, 'shared'));
		spr.scrollFactor.set();
		spr.scale.set(0.7, 0.7);
		spr.updateHitbox();
		spr.screenCenter();
		spr.antialiasing = char.countdownGraphicType != '3D';
		spr.camera = countdownCamera;
		PlayState.instance.add(spr);
		countdownSpriteMap[step] = spr;

		FlxTween.tween(spr, {alpha: 0}, Conductor.instance.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				spr.destroy();
			}
		});
	}

	/**
	 * Plays a sound based on the given countdown step.
	 * @param step The step to play the sound for.
	 */
	public static function playCountdownSound(step:CountdownStep):Void
	{
		var stepSound = countdownSound(step);
		if (stepSound != null)
		{
			SoundController.play(Paths.soundPath(stepSound), 0.6, SoundType.VOICES);
		}
	}

	/**
	 * Increments the Countdown to a new step.
	 */
	public static function increment():Void
	{
		countdownStep = switch (countdownStep)
		{
			case START: THREE;
			case THREE: TWO;
			case TWO: ONE;
			case ONE: GO;
			case GO: FINISH;
			default: START;
		}
	}

	public static function dispatchCountdownEvent():Bool
	{
		var event:ScriptEvent = null;
		switch (countdownStep)
		{
			case START:
				event = new CountdownScriptEvent(COUNTDOWN_START, countdownStep, true);
			case THREE, TWO, ONE, GO:
				event = new CountdownScriptEvent(COUNTDOWN_TICK, countdownStep, true);
			case FINISH:
				event = new CountdownScriptEvent(COUNTDOWN_END, countdownStep, true);
		}
		dispatchEvent(event);
		
		return event.eventCanceled;
	}

	/**
	 * Gets the animation name for the given countdown step.
	 * @param step The step to get the animation name for.
	 * @return A Countdown Step's animation name.
	 */
	public static function countdownAnimStep(step:CountdownStep):Null<String>
	{
		return switch (step)
		{
			case THREE: 'countdownThree';
			case TWO: 'countdownTwo';
			case ONE: 'countdownOne';
			case GO: 'countdownGo';
			default: null;
		}
	}

	/**
	 * Gets the countdown graphic for the given step.
	 * @param step The Countdown step.
	 * @return The graphic for this step.
	 */
	public static function getCountdownGraphic(step:CountdownStep):Null<String>
	{
		var path:String = 'ui/countdown';
		var stepGraphic = countdownGraphicStep(step);
		if (stepGraphic == null)
			return null;

		function checkForAsset(basePath:String, folder:String, stepGraphic:String):Null<String>
		{
			return (Assets.exists(Paths.imagePath('$basePath/$folder/$stepGraphic', 'shared'))) ? '$basePath/$folder/$stepGraphic' : null;
		}

		var characterResult:Null<String> = checkForAsset(path, 'characters/${char.id}', stepGraphic);
		var countdownResult = checkForAsset(path, '${char.countdownGraphicType}', stepGraphic);

		if (characterResult != null)
		{
			return characterResult;
		}
		else if (countdownResult != null)
		{
			return countdownResult;
		}
		else
		{
			return '$path/normal/$stepGraphic';
		}
	}

	/**
	 * Gets the name of the graphic for the given step.
	 * @param step The step to get the graphic name for.
	 * @return The name of the graphic for the step.
	 */
	static function countdownGraphicStep(step:CountdownStep):Null<String>
	{
		return switch (step)
		{
			case TWO: 'ready';
			case ONE: 'set';
			case GO: 'go';
			default: null;
		}
	}

	/**
	 * Gets the sound asset path for the given countdown step.
	 * @param step The step to get the asset path for.
	 * @return The asset path for the step.
	 */
	static function countdownSound(step:CountdownStep):Null<String>
	{
		var stepSound:Null<String> = countdownSoundStep(step);
		if (stepSound == null)
			return null;

		if (Assets.exists(Paths.soundPath('countdown/${char.countdownSoundType}/$stepSound')))
		{
			return 'countdown/${char.countdownSoundType}/$stepSound';
		}
		else
		{
			return 'countdown/default/$stepSound';
		}
	}

	/**
	 * Gets the name of the sound for the given step.
	 * @param step The step to get the sound asset name for.
	 * @return The name of the sound for the step.
	 */
	static function countdownSoundStep(step:CountdownStep):Null<String>
	{
		return switch (step)
		{
			case THREE: 'intro3';
			case TWO: 'intro2';
			case ONE: 'intro1';
			case GO: 'introGo';
			default: null;
		}
	}

	/**
	 * Caches all of the graphic that'll be played during the Countdown.
	 * Helps with majorly decreasing lag, and loading times.
	 */
	public static function cacheSprites()
	{
		for (i in [TWO, ONE, GO])
		{
			Preloader.cacheImage(Paths.imagePath(getCountdownGraphic(i)));
		}
	}

	/**
	 * Caches all of the sounds that'll be played during the Countdown.
	 * Helps with majorly decreasing lag, and loading times.
	 */
	public static function cacheSounds()
	{
		for (i in [THREE, TWO, ONE, GO])
		{
			Preloader.cacheSound(Paths.soundPath(countdownSound(i)));
		}
	}

	public static function dispatchEvent(event:ScriptEvent):Void
	{		
		var dispatcher:IEventDispatcher = cast FlxG.state;

		if (dispatcher != null)
			dispatcher?.dispatchEvent(event);
	}
}

/**
 * The progress at which the countdown is at.
 */
enum CountdownStep
{
	START;
	THREE;
	TWO;
	ONE;
	GO;
	FINISH;
}

/**
 * Defines how the camera should move during the countdown.
 */
enum CountdownCameraType
{
	/**
	 * The camera will move back and forth between the player, and opponent.
	 */
	ALTERNATE;

	/**
	 * The camera will stay in place, and not move during the countdown.
	 */
	LOCKED;
}