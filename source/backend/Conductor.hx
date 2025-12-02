package backend;

import data.song.SongData.SongMusicData;
import data.song.SongData.SongTimeChange;
import data.song.SongRegistry;
import flixel.FlxG;
import flixel.util.FlxSignal;
import util.SortUtil;
import play.save.Preferences;

/**
 * A core handled used to help calculate musical timings, and beats for a song.
 * This is an essential core in the game that's used in both playing, and in menus.
 * 
 * While there is a 'main' Conductor instance that's used throughout the game.
 * You are able to create as many Conductor instances as you want for a multitude of purposes.
 * 
 * 1 step = 16th note
 * 4/4 = 4 beats every measure, 1 beat = 1 quarter note / 4 16th notes / 4 steps
 * 4/2 = 4 beats every measure, 1 beat = 1 half note / 8 16th notes / 8 steps
 * 7/4 = 7 beats every measure, 1 beat = 1 quarter note / 4 16th notes / 4 steps
 */
class Conductor
{
	/**
	 * The default BPM if none is available.
	 */
	final DEFAULT_BPM:Float = 100.0;

	/**
	 * The current instance of this Conductor.
	 * This is the main instance of the Conductor that the game uses, and can be reset whenever.
	 */
	public static var instance(get, never):Conductor;

	static function get_instance():Conductor
	{
		if (_instance == null)
			_instance = new Conductor();

		return _instance;
	}

	static var _instance:Conductor;

	// CONSTANTS //

	/**
	 * A constant value that represents the length of one step, used for time signature calculations.
	 */
	public static final STEP_VALUE:Int = 16;
	
	/**
	 * The number of frames the player has to hit a note before it's considered too early, or late.
	 */
	static final safeFrames:Int = 10;
	
	/**
	 * The hit window the player has to hit a note before it's considered too early, or late.
	 * Calculated based on beats.
	 */
	public final safeZoneOffset:Float = (safeFrames / 60) * 1000; // is calculated in create(), is safeFrames in milliseconds

	
	// CONDUCTOR INFORMATION //

	/**
	 * The current position this Conductor in at, in milliseconds.
	 * Used to help calculate the Conductor's musical information.
	 */
	public var songPosition:Float;

	/**
	 * The amount of milliseconds this Conductor will be offset by.
	 * Used normally to help with things like latency delay.
	 */
	public var offsets:Float;
	
	/**
	 * The current time change this Conductor is at.
	 */
	public var currentTimeChange(default, null):SongTimeChange;

	/**
	 * The starting BPM from when the Conductor was initalized.
	 * Can be changed in-case you want to load another song, or use the Conductor for something else.
	 */
	public var startingBpm(get, null):Float;

	function get_startingBpm():Float
	{
		return timeChangeMap[0].bpm ?? DEFAULT_BPM;
	}

	/**
	 * The current BPM of this Conductor.
	 */
	public var bpm(get, never):Float;

	function get_bpm():Float
	{
		if (currentTimeChange == null) return DEFAULT_BPM;
		return currentTimeChange.bpm;
	}

	/**
	 * The target step that the Conductor has yet to go to.
	 * This is used so we can easily take into account if any steps, beats, or measures have been skipped, and call them.
	 */
	static var newStep:Int;

	/**
	 * The current step of this Conductor.
	 */
	public var curStep(default, null):Int;

	/**
	 * The current beat of this Conductor.
	 */
	public var curBeat(default, null):Int;

	/**
	 * The current measure of this Conductor.
	 */
	public var curMeasure(default, null):Int;


	/**
	 * The length of a step for this Conductor, in milliseconds.
	 */
	public var stepCrochet(get, never):Float;

	function get_stepCrochet():Float
		return stepCrochetOf(bpm, currentTimeChange.numerator, currentTimeChange.denominator);

	/**
	 * The length of a beat for this Conductor, in milliseconds.
	 */
	public var crochet(get, never):Float;

	function get_crochet():Float
		return crochetOf(bpm, currentTimeChange.numerator, currentTimeChange.denominator);

	/**
	 * The length of a measure for this Conductor, in milliseconds.
	 */
	public var measureLength(get, never):Float;

	function get_measureLength():Float
		return measureLengthOf(bpm, currentTimeChange.numerator, currentTimeChange.denominator);


	/**
	 * The offset used for this Conductor.
	 * Used in-case the player has any latency issues.
	 */
	public var offset:Float = 0;

	// SIGNALS //
	
	/**
	 * Signal that fires whenever this Conductor has passed a step.
	 */
	public var onStepHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	
	/**
	 * Signal that fires whenever this Conductor has passed a beat.
	 */
	public var onBeatHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	
	/**
	 * Signal that fires whenever the Conductor has passed a measure.
	 */
	public var onMeasureHit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	
	/**
	 * Signal that fires whenever the Conductor has passed a time change event.
	 */
	public var onTimeChangeHit:FlxTypedSignal<SongTimeChange->Void> = new FlxTypedSignal<SongTimeChange->Void>();

	/**
	 * A list of all of the current time changes for this Conductor.
	 */
	public var timeChangeMap:Array<SongTimeChange> = [];

	public function new() {}

	/**
	 * Resets the Conductor back to the start.
	 */
	public function reset()
	{
		update(0, false);
	}

	/**
	 * Initalizes the Conductor with time change basic parameters.
	 * @param time The time of the Conductor
	 * @param bpm 
	 * @param numerator 
	 * @param denominator 
	 */
	public function initalize(bpm:Float, numerator:Int = 4, denominator:Int = 4)
	{
		// Create a basic time change object.
		var timeChange:SongTimeChange = new SongTimeChange(0.0, bpm, numerator, denominator);		
		
		// Map the time change to further set it up, and reset the Conductor.
		mapTimeChanges([timeChange]);
		reset();
	}
	
	/**
	 * Updates this Conductor's position, and updates any musical information for it.
	 * @param songPos The position to update it with.
	 * @param canDispatch Whether signals should be dispatched if they're able to be.
	 * @param applyOffsets Whether any global offsets are applied.
	 */
	public function update(?songPos:Float, canDispatch:Bool = true, applyOffsets:Bool = true)
	{
		var currentTime = SoundController?.music?.time ?? 0.0;
		var currentLength = SoundController?.music?.length ?? 0.0;

		if (songPos == null)
			songPos = Math.min(currentLength, currentTime);

		if (applyOffsets)
			songPos += offsets;

		songPosition = songPos;

		if (timeChangeMap.length == 0)
			return;

		var newTimeChange = getTimeChangeAt(songPosition);
		
		if (currentTimeChange == null)
			currentTimeChange = newTimeChange;

		if (currentTimeChange != newTimeChange)
		{
			currentTimeChange = newTimeChange;
			if (canDispatch)
			{
				onTimeChangeHit.dispatch(currentTimeChange);
			}
		}
		updateStepsInfo(songPos, canDispatch);
	}

	/**
	 * Sets up and maps all of the given time changes.
	 * @param songTimeChanges The time changes to map into the Conductor.
	 */
	public function mapTimeChanges(songTimeChanges:Array<SongTimeChange>)
	{
		if (songTimeChanges == null || songTimeChanges.length == 0)
			return;

		timeChangeMap = [];
		
		songTimeChanges.sort(SortUtil.sortTimeChanges);
		
		for (timeChange in songTimeChanges)
		{
			if (timeChangeMap.length == 0)
			{
				// This takes into account of in-case non zero timestamps.
				var numerator:Int = timeChange.numerator;
				var denominator:Int = timeChange.denominator;

				timeChange.stepTime = timeChange.time / stepCrochetOf(timeChange.bpm, numerator, denominator);
				timeChange.beatTime = timeChange.time / crochetOf(timeChange.bpm, numerator, denominator);
				timeChange.measureTime = timeChange.time / measureLengthOf(timeChange.bpm, numerator, denominator);
			}
			else
			{
				var prevTimeChange:SongTimeChange = timeChangeMap[timeChangeMap.length - 1];
				var prevNumerator:Int = prevTimeChange.numerator;
				var prevDenominator:Int = prevTimeChange.denominator;

				timeChange.stepTime = prevTimeChange.stepTime + ((timeChange.time - prevTimeChange.time) / stepCrochetOf(prevTimeChange.bpm, prevNumerator, prevDenominator));
				timeChange.beatTime = prevTimeChange.beatTime + ((timeChange.time - prevTimeChange.time) / crochetOf(prevTimeChange.bpm, prevNumerator, prevDenominator));
				timeChange.measureTime = prevTimeChange.measureTime + ((timeChange.time - prevTimeChange.time) / measureLengthOf(prevTimeChange.bpm, prevNumerator, prevDenominator));
			}
			timeChangeMap.push(timeChange);
		}
	}

	/**
	 * Gets a time change at a given position.
	 * If none exists, it defaults to the fallback time change.
	 * @param position The position to get the time change for.
	 * @return A `SongTimeChange` object.
	 */
	public function getTimeChangeAt(position:Float):SongTimeChange
	{
		var foundTimeChange = timeChangeMap[0];
		if (timeChangeMap.length > 0)
		{
			for (timeChange in timeChangeMap)
			{
				if (timeChange.time < position)
				{
					foundTimeChange = timeChange;
				}
				if (timeChange.time > position)
					break;
			}
		}
		return foundTimeChange;
	}

	/**
	 * Gets a step value at a certain time.
	 * @param time The time in milliseconds to get the step value at.
	 * @return A value in steps representing the time.
	 */
	public function getStepAtTime(time:Float):Float
	{
		if (timeChangeMap.length == 0)
			return time / stepCrochetOf(bpm);

		var baseTimeChange:SongTimeChange = getTimeChangeAt(time);
		return baseTimeChange.stepTime + ((time - baseTimeChange.time) / stepCrochetOf(baseTimeChange.bpm, baseTimeChange.numerator, baseTimeChange.denominator));
	}

	/**
	 * Given a step time, retrieve the time in milliseconds equal to the step time.
	 * @param stepTime The step time to get the time in milliseconds for.
	 * @return The stepTime in milliseconds.
	 */
	public function getTimeAtStepTime(stepTime:Float):Float
	{
		if (timeChangeMap.length == 0)
			return stepTime * stepCrochetOf(bpm);

		var lastChange:SongTimeChange = timeChangeMap[0];
		for (timeChange in timeChangeMap)
		{
			if (timeChange.stepTime < stepTime)
				lastChange = timeChange;

			if (timeChange.stepTime > stepTime) break;
		}
		return lastChange.time + ((stepTime - lastChange.stepTime) * stepCrochetOf(lastChange.bpm));
	}

	/**
	 * Gets the start time for a given section of a song
	 * @param section The section to get the time at.
	 * @return The sections start time, in milliseconds.
	 */
	public function measureStartTime(section:Int):Float
	{
		var baseTimeChange:SongTimeChange = timeChangeMap[0];
		for (timeChange in timeChangeMap)
		{
			if (timeChange.measureTime < section)
			{
				baseTimeChange = timeChange;
			}
			if (timeChange.measureTime > section)
				break;
		}
		return baseTimeChange.time + ((section - baseTimeChange.measureTime) * measureLengthOf(baseTimeChange.bpm, baseTimeChange.numerator, baseTimeChange.denominator));
	}

	/**
	 * Updates this Conductor's musical information, and dispatches any events if necessary.
	 * @param position The position to update based on.
	 * @param canDispatch Whether any signals should be dispatched.
	 */
	function updateStepsInfo(position:Float, canDispatch:Bool = true)
	{
		function updateStep(position:Float, step:Int)
		{
			var deltaTime = position - currentTimeChange.time;

			curStep = step;
			curBeat = Math.floor(currentTimeChange.beatTime + (deltaTime / crochet));
			curMeasure = Math.floor(currentTimeChange.measureTime + (deltaTime / measureLength));
		}
		var oldStep:Int = curStep;
		var oldBeat:Int = curBeat;
		var oldMeasure:Int = curMeasure;

		newStep = Math.floor(currentTimeChange.stepTime + ((position - currentTimeChange.time) / stepCrochet));

		if (curStep != newStep)
		{
			if (newStep > curStep)
			{
				while (curStep < newStep)
				{
					updateStep(position, curStep + 1);

					if (canDispatch)
					{
						if (oldStep != curStep)
							onStepHit.dispatch(curStep);

						if (oldBeat != curBeat)
							onBeatHit.dispatch(curBeat);

						if (oldMeasure != curMeasure)
							onMeasureHit.dispatch(curMeasure);
					}
					oldStep = curStep;
					oldBeat = curBeat;
					oldMeasure = curMeasure;
				}
			}
			else
			{
				updateStep(position, newStep);
			}
		}
	}

	/**
	 * Loads a music data file from the given entry id and variation.
	 * This'll also map any time changes the music data file will have.
	 * @param id The entry id of the music data
	 * @param variation (Optional) The variation of the music data.
	 */
	public function loadMusicData(id:String, ?variation:String):Void
	{
		if (!SongRegistry.instance.hasMusicDataFile(id, variation))
			return;

		var musicData:SongMusicData = SongRegistry.instance.loadMusicDataFile(id, variation);
		applyMusicData(musicData);
	}

	/**
	 * Applies the given music data to this Conductor.
	 * This'll also map the time changes the music data file may have.
	 * @param musicData The music data to apply to this Conductor.
	 */
	public function applyMusicData(musicData:SongMusicData)
	{
		mapTimeChanges(musicData.timeChanges);
		reset();
	}

	/**
	 * Adds this Conductor's musical information into the flixel watch console. 
	 */
	public function quickWatch():Void
	{
		FlxG.watch.addQuick('bpm', bpm);
		FlxG.watch.addQuick('songPosition', songPosition);
		FlxG.watch.addQuick('timeChange', currentTimeChange);

		FlxG.watch.addQuick('curStep', curStep);
		FlxG.watch.addQuick('curBeat', curBeat);
		FlxG.watch.addQuick('curMeasure', curMeasure);
	}

	/**
	 * Calculates the amount of steps needed for a beat given a denominator.
	 * @param denominator The denominator to check.
	 * @return The amount of steps needed for this demoniator.
	 */
	public static function beatSteps(denominator:Int = 4):Int
		return Std.int(STEP_VALUE / denominator);

	/**
	 * Returns the length of a beat based on a given BPM.
	 * @param bpm The BPM to check.
	 * @return The length of a beat, in milliseconds.
	 */
	public static function beatLength(bpm:Float)
		return (60 / bpm) * 1000;

	/**
	 * Returns the length of a step based on a given BPM, and time signature.
	 * @param bpm The BPM to check.
	 * @return The length of a step, in milliseconds.
	 */
	public static function stepCrochetOf(bpm:Float, numerator:Int = 4, denominator:Int = 4)
		return beatLength(bpm) / 4;

	/**
	 * Returns the length of a beat based on a given BPM, and time signature.
	 * @param bpm The BPM to check
	 * @return The length of a beat, in milliseconds.
	 */
	public static function crochetOf(bpm:Float, numerator:Int = 4, denominator:Int = 4):Float
		return stepCrochetOf(bpm, numerator, denominator) * beatSteps(denominator);

	/**
	 * Returns the length of a measure based on a given BPM, and time signature.
	 * @param bpm The BPM to check
	 * @param ts The time signature to check
	 * @return The length of a measure, in milliseconds.
	 */
	public static function measureLengthOf(bpm:Float, numerator:Int = 4, denominator:Int = 4)
		return crochetOf(bpm, numerator, denominator) * numerator;

	/**
	 * Calculates the amount of beats in a measure based on a given time signature.
	 * @param ts The time signature to check.
	 * @return The number of steps in a measure.
	 */
	public static function measureBeats(numerator:Int = 4, denominator:Int = 4):Int
		return Std.int(measureSteps(numerator, denominator) / beatSteps(denominator));

	/**
	 * Calculates the amount of steps in a measure based on a given time signature.
	 * @param ts The time signature to check.
	 * @return The number of steps in a measure.
	 */
	public static function measureSteps(numerator:Int = 4, denominator:Int = 4):Int
		return Std.int(numerator * beatSteps(denominator));

}
