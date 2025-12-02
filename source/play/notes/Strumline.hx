package play.notes;

import data.song.SongData.SongSection;
import data.song.SongData.SongNoteData;
import backend.Conductor;
import controls.PlayerSettings;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxSort;
import flixel.util.FlxSignal.FlxTypedSignal;

import play.PlayState;
import play.character.Character;
import play.notes.NoteStyle;
import play.notes.Note;
import play.notes.StrumNote;

import util.TweenUtil;

typedef StrumlineParams = 
{
	/**
	 * Whether this strumline should be cpu controlled, or controlled by the player.
	 */
	var isPlayer:Bool;

	/**
	 * The note style to be used on this strumline
	 */
	var noteStyle:NoteStyle;

	/**
	 * The scrolling type to be used on this strumline.
	 */
	var ?scrollType:String;

	/**
	 * Whether the strums should appear immediately on creation of the strumline, or remain invisible until they're faded.
	 */
	@:optional var showStrums:Bool;
}

/**
 * A group of group of sprites that handles logic behind with the strum receptors, rendering, positioning notes, and more.
 */
@:access(play.notes)
class Strumline extends FlxSpriteGroup
{
	// STATIC VARIABLES // 

	/**
	 * The normal width of a strum receptor.
	 * Used when generating the strums to position them.
	 */
	public static var NOTE_WIDTH:Float = 160 * 0.7;

    /**
     * The Base Y position of the strumline on downscroll.
     */
    public static final DOWNSCROLL_Y:Float = 555;

    /**
     * The Base Y position of the strumline on upscroll.
     */
    public static final UPSCROLL_Y:Float = 50;

    /**
     * A magic number used to control the general speed rate, in pixels, at which notes go.
     */
    public final pixelsPerMs:Float = 0.45;
    

	// PROPERTIES // 

	public var params:StrumlineParams;

	/**
	 * The custom speed at which the notes go by.
	 * If null, the song's chart speed is used instead.
	 */
	@:isVar
	public var scrollSpeed(get, set):Null<Float> = null;

    function set_scrollSpeed(value:Null<Float>):Null<Float> {
        return this.scrollSpeed = value;
    }

	function get_scrollSpeed():Null<Float> {
        return scrollSpeed != null ? scrollSpeed : PlayState.instance.songSpeed;
	}
	
	/**
	 * The current base y position on the strumline depending on if the strumline's on downscroll or upscroll.
	 */
	public var scrollY(get, null):Float = 0;
	
	function get_scrollY():Float
	{
        return (scrollType == 'downscroll') ? DOWNSCROLL_Y : UPSCROLL_Y;
	}

    /**
     * The current scrolling type of the strumline.
	 * Can either be 'downscroll' or 'upscroll'.
	 * Updating this will update the strum and sustain notes to their appropriate positions.
     */
    public var scrollType(default, set):String;
	
	function set_scrollType(value:String):String
	{
		this.scrollType = value;

		forEachStrum(function(strum:StrumNote)
		{
			// TODO: This can easily cause issues relating to tweened modcharts.
			// The best possible solution would probably be to make a separate
			// StrumCamera that flips instead of the strums itself (This would make it easier to do modcharts also).

			TweenUtil.completeTweensOf(strum, true);

			switch (value)
			{
				case 'downscroll':
					strum.y = DOWNSCROLL_Y;
				case 'upscroll':
					strum.y = UPSCROLL_Y;
			}
		});

		sustains.forEach(function(note:SustainNote)
		{
			if (note != null)
			{
				note.flipY = (value == 'downscroll');
			}
		});
		for (holdNote in recyclableHoldNotes.members)
		{
			if (holdNote == null) continue;
			
			holdNote.flipY = (value == 'downscroll');
		}
		updateNotes();

		return value;
	}

	// GROUPS // 

	/**
	 * A group containing the strums of this strumline.
	 */
	public var strums(default, null):FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup<StrumNote>();

	/**
	 * A group containing the notes currently being rendered.
	 */
	public var notes(default, null):FlxTypedSpriteGroup<Note> = new FlxTypedSpriteGroup<Note>();

	/**
	 * A group containing the notes currently being rendered.
	 */
	public var sustains(default, null):FlxTypedSpriteGroup<SustainNote> = new FlxTypedSpriteGroup<SustainNote>();

	/**
	 * A group containing the currently rendered hold covers.
	 */
	public var holdCovers(default, null):FlxTypedSpriteGroup<HoldCover> = new FlxTypedSpriteGroup<HoldCover>();

	/**
	 * A list of the current notes that have yet to be spawned.
	 */
	public var unspawnNotes(default, null):Array<SongNoteData> = [];

	/**
	 * A group containing notes that have been used, but are able to be recycled.
	 */
	private var recyclableNotes(default, null):FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
	
	/**
	 * A group containing hold notes that have been used, but are able to be recycled.
	 */
	private var recyclableHoldNotes(default, null):FlxTypedGroup<SustainNote> = new FlxTypedGroup<SustainNote>();

	/**
	 * A group containing hold covers that have been used, but are able to be recycled.
	 */
	private var recyclableHoldCovers(default, null):FlxTypedGroup<HoldCover> = new FlxTypedGroup<HoldCover>();


	// SIGNALS // 

    /**
     * A signal that dispatches for when a note spawns.
     */
    public var onNoteSpawn(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	/**
	 * A signal that dispatches for when this strumline misses a note.
	 */
	public var onNoteMiss(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	/**
	 * A signal that dispatches for when this strumline hits a note.
	 */
	public var onNoteHit(default, null):FlxTypedSignal<Note->Void> = new FlxTypedSignal<Note->Void>();

	
	// VARIABLES // 

	/**
	 * Whether the strumline is able to call the update() function.
	 * Useful for when you want the strumline to only be used for graphical purposes, like for example only showing the strum receptors.
	 */
	public var canUpdate:Bool = true;

	/**
	 * The conductor this strumline in running on.
	 * If none is specified, it uses the current static Conductor instance.
	 */
	public var conductor(get, set):Conductor;

	function get_conductor():Conductor
	{
		if (_conductor == null) return Conductor.instance;
		return _conductor;
	}

	function set_conductor(value:Conductor):Conductor
	{
		return _conductor = value;
	}

	var _conductor:Conductor;

	/**
	 * A custom function that can be used to calculate the y position of a note.
	 */
	public var noteYFunction:(strumTime:Float, strumLine:FlxSprite, speed:Float, downScroll:Bool)->Float;

	/**
	 * The amount of time before a note's strum time before the note's able to spawn.
	 */
	public var noteSpawnTime:Float = 1500;

    /**
     * Whether this strumline is cpu controlled, or is meant to be played.
     */
    public var isPlayer(default, set):Bool;

	function set_isPlayer(value:Bool)
	{
		forEachStrum((strum:StrumNote) -> 
		{
			strum.playerStrum = value;
		});
		return isPlayer = value;
	}

	/**
	 * The current note style of this strumline group.
	 */
	public var noteStyle:NoteStyle;

	/**
	 * The amount of strums this strumline has.
	 * This can be used to support multi-key.
	 */
	public var strumAmount:Int = 4;

	/**
	 * Mapping of the currently held note directions.
	 */
	private var heldKeys:Array<Bool> = [];

	/**
	 * The current starting index in the notes list.
	 * Used to iterate through the chart to spawn notes.
	 */
	private var nextNoteIndex:Int = 0;

    public function new(params:StrumlineParams)
    {
		super();
		
		noteYFunction = yFromStrumTime;

		this.params = params;
		this.params.showStrums ??= true;

		this.isPlayer = params.isPlayer;
		this.noteStyle = params.noteStyle;
		this.scrollType = params.scrollType ?? 'none';

		this.y = scrollY;

		add(strums);

		add(sustains);
		add(notes);
		add(holdCovers);

		this.generateStaticArrows(false);
		
		this.active = true;
	}
	
    override function update(elapsed:Float)
	{
		if (!canUpdate) return;

		super.update(elapsed);
		
		handleNoteSpawning();
		updateNotes();
    }

	/**
	 * Generates a list of notes from a given chart data.
	 * @param data The chart data to be used for generating the notes.
	 */
	public function generateNotes(data:Array<SongSection>)
	{
		nextNoteIndex = 0;

		var chartData:Array<SongSection> = data.copy();
		
		for (section in chartData)
		{
			for (note in section.notes)
			{
				var gottaHitNote:Bool = section.mustHitSection;

				if (note.direction > 3)
					gottaHitNote = !section.mustHitSection;
				
				if (gottaHitNote != isPlayer)
					continue;
				
				unspawnNotes.push(note);
			}
		}
		unspawnNotes.sort(sortByDataStrumTime);
	}

	/**
	 * Generates a group of strum receptors for this strumline to use.
	 * @param fadeIn Whether there should be a fade-in effect when the strums are created.
	 */
	public function generateStaticArrows(fadeIn:Bool):Void
	{
		for (i in 0...strumAmount)
		{
			var babyArrow:StrumNote = new StrumNote(0.0, 0.0, noteStyle, i, isPlayer);

			babyArrow.x += NOTE_WIDTH * Math.abs(i);
			strums.add(babyArrow);
			
			babyArrow.baseX = babyArrow.x - strums.x;
			if (!params.showStrums)
				babyArrow.alpha = 0.0;
		}
        if (fadeIn)
            fadeNotes();
	}
	
	/**
	 * Re-generates the strums receptors of this strumline.
	 * @param fadeIn Whether there should be a fade-in effect when the strums are created.
	 */
	public function regenerate(fadeIn:Bool = true)
	{
		forEachStrum(function(spr:StrumNote)
		{
			strums.remove(spr);
			spr.destroy();
		});
		generateStaticArrows(fadeIn);
	}

	/**
	 * Does a small fade-in transition for the strum receptors.
	 */
	public function fadeNotes()
	{
		for (i in 0...strums.length)
		{
			var babyArrow:StrumNote = strums.members[i];

			babyArrow.y -= 10;
			babyArrow.alpha = 0;

			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
        }
    }

	/**
	 * Controls logic behind when notes spawn and how many.
	 */
	function handleNoteSpawning()
	{
		var startRenderTime:Float = conductor.songPosition + noteSpawnTime;
		var hitWindowStart:Float = conductor.songPosition - conductor.safeZoneOffset;

		for (noteIndex in nextNoteIndex...unspawnNotes.length)
		{
			var noteData:SongNoteData = unspawnNotes[noteIndex];

			// Note's blank.
			if (noteData == null)
				return;

			// If the note's below the start of the song, or it's below the hit window.
			if (noteData.time < 0.0 || noteData.time < hitWindowStart)
			{
				nextNoteIndex = noteIndex + 1; 
				continue;
			}

			// Note's too far ahead to render.
			if (noteData.time > startRenderTime)
				break;

			var note:Note = buildNote(noteData);
			this.notes.add(note);

			if (noteData.length > 0)
			{
				note.sustainNote = buildHoldNote(noteData, note);
				this.sustains.add(note.sustainNote);
			}

			// Increment the note index.
			nextNoteIndex = noteIndex + 1;
			
			onNoteSpawn.dispatch(note);

			notes.sort(compareNotes);
			sustains.sort(compareHoldNotes);
		}
	}

	/**
	 * Updates the logic, and positioning of each note being rendered.
	 */
	function updateNotes()
	{
		forEachNote(function(note:Note)
		{
			// Update the state of the note before rendering.
			// This also updates the state of any rendering sustain notes.
			updateNoteState(note);

			var noteSpeed:Float = scrollSpeed * note.LocalScrollSpeed;
			if (note.strum != null)
			{
				if (Note.rotate)
				{
					var dist:Float = (conductor.songPosition - note.strumTime) * (pixelsPerMs * noteSpeed);
					var rotateBase:FlxPoint = rotatePosition(dist, note.strum.rotation + 90, ((scrollType == 'downscroll') ? 1 : -1));

					note.x = note.strum.x + rotateBase.x;
					note.y = note.strum.y + rotateBase.y;
				}
				else
				{
					note.y = noteYFunction(note.strumTime, note.strum, noteSpeed, scrollType == 'downscroll');
				}
			}

			// Note is outside, destroy it.
			if (conductor.songPosition >= note.strumTime + (350 / (pixelsPerMs * noteSpeed)))
			{
				if (isPlayer && note.handledMissed)
					onNoteMiss.dispatch(note);

				killNote(note);
			}
		});
		
		forEachHoldNote(function(holdNote:SustainNote)
		{
			if (holdNote.sustainLength < holdNote.fullSustainLength)
			{
				// Hold note was dropped as it was being held, it's been missed.
				if (isPlayer && (!isKeyHeld(holdNote.direction) || (!isKeyHeld(holdNote.direction) && holdNote.noteStyle == 'shape' && !PlayerSettings.controls.KEY5)))
				{
					holdNote.cover?.hide();

					strums.members[holdNote.direction].playStatic();
					holdNote.hasMissed = true;
				}
			}

			// Calculate the these values of this hold note, as they gets used in each of the hold note's states.
			var holdNoteSpeed:Float = scrollSpeed * holdNote.localScrollSpeed;
			var yPosition:Float = noteYFunction(holdNote.strumTime, holdNote.strum, holdNoteSpeed, scrollType == 'downscroll');
			
			if (conductor.songPosition >= holdNote.strumTime + holdNote.fullSustainLength + (350 / (pixelsPerMs * holdNoteSpeed)))
			{
				// Hold note is offscreen, kill it.
				killSustain(holdNote);
			}
			else if (holdNote.hasMissed && (holdNote.fullSustainLength > holdNote.sustainLength)) 
			{
				// Hold note was dropped as it was held, keep in it's clipped state.
				var yOffset:Float = SustainNote.sustainHeight(holdNote.fullSustainLength - holdNote.sustainLength, holdNoteSpeed);

				holdNote.y = if (scrollType == 'downscroll')
				{
					yPosition + holdNote.strum.height / 2 - holdNote.height - yOffset;
				}
				else
				{
					yPosition + holdNote.strum.height / 2 + yOffset;
				}

				if (holdNote.cover != null)
				{
					holdNote.cover?.hide();
				}
			}
			else if (conductor.songPosition >= holdNote.strumTime && holdNote.hasBeenHit && !holdNote.hasMissed) // Hold note's currently being hit, clip it, and position it.
			{
				strums.members[holdNote.direction].holdConfirm();

				holdNote.sustainLength = (holdNote.strumTime + holdNote.fullSustainLength) - conductor.songPosition;
				
				var character:Character = holdNote.character;
				
				// Reset the character hold timer to make sure they keep singing.
				if (character != null && character.holdTimer > 0)
				{
					character.holdTimer = 0;
				}

				// Hold note's been complete, kill it.
				if (holdNote.sustainLength <= 0)
				{
					strums.members[holdNote.direction].playStatic();

					if (holdNote.cover != null && isPlayer)
					{
						holdNote.cover.playEnd();
					}
					else 
					{
						holdNote.cover?.hide();
					}
					killSustain(holdNote);
					return;
				}
				
				holdNote.y = if (scrollType == 'downscroll')
				{
					holdNote.strum.y + holdNote.strum.height / 2 - holdNote.height;
				}
				else
				{
					holdNote.strum.y + holdNote.strum.height / 2;
				}
			}
			else
			{
				// Hold note is new, position it normally.
				holdNote.y = if (scrollType == 'downscroll')
				{
					yPosition + holdNote.strum.height / 2 - holdNote.height;
				}
				else
				{
					yPosition + holdNote.strum.height / 2;
				}
			}
		});

		for (ind => strum in strums.members)
		{
			if (isKeyHeld(ind) && strum.animation.curAnim.name == 'static')
			{
				strum.playPress();
			}
		}

		for (holdCover in holdCovers)
		{
			if (holdCover == null)
				return;

			// If the sustain note for the hold cover doesn't exist anymore
			// Clear the hold cover so it doesn't persistent.
			if (holdCover.holdNote == null || holdCover.holdNote.sustainLength <= 0 && holdCover.animation.curAnim.name.startsWith('loop'))
			{
				holdCover.hide();
			}
		}
	}

	/**
	 * Updates a note's logic checking if it's able to be hit, if it's too late, or early, etc.
	 * @param note The note to update. 
	 */
	function updateNoteState(note:Note)
	{
		var hitWindowStart:Float = note.strumTime - (conductor.safeZoneOffset * 0.5);
		var hitWindowCenter:Float = note.strumTime;
		var hitWindowEnd:Float = note.strumTime + conductor.safeZoneOffset;

		if (!isPlayer)
		{
			note.canBeHit = false;
		}
		
		if (note.hasBeenHit)
		{
			note.tooEarly = false;
			note.canBeHit = false;
			note.hasMissed = false;
			if (note.sustainNote != null)
			{
				note.sustainNote.hasMissed = false;
			}
			return;
		}

		if (conductor.songPosition > hitWindowEnd)
		{
			if (note.hasMissed || note.hasBeenHit)
				return;
			
			note.tooLate = true;
			note.canBeHit = false;
			note.hasMissed = true;
			if (note.sustainNote != null)
			{
				note.sustainNote.hasMissed = true;
			}
		}
		else if (conductor.songPosition > hitWindowCenter)
		{
			if (note.hasBeenHit)
				return;

			if (!isPlayer)
			{
				hitNote(note);
			}
		}
		else if (conductor.songPosition > hitWindowStart)
		{
			note.canBeHit = true;
			note.tooEarly = false;
		}
		else
		{
			note.canBeHit = false;
			note.tooEarly = true;
		}
	}

	/**
	 * Cleans up the strumline by removing every rendering note, and resetting any needed properties.
	 * Used for when time in a song has been skipped.
	 */
	public function clean():Void
	{
		forEachNote(function(note:Note)
		{
			killNote(note);
		});

		forEachHoldNote(function(sustain:SustainNote)
		{
			killSustain(sustain);
		});
		
		for (cover in holdCovers)
		{
			cover?.hide();
		}

		for (i in 0...heldKeys.length)
		{
			heldKeys[i] = false;
		}

		forEachStrum((strum:StrumNote) ->
		{
			strum.playStatic();
		});
		nextNoteIndex = 0;
	}

	/**
	 * Creates, or recycles a note to be reused.
	 * @return A newly created, or previously used note.
	 */
	function constructNote():Note
	{
		var note:Note = null;

		note = recyclableNotes.getFirstAvailable();

		if (note != null)
		{
			note.revive();
			recyclableNotes.remove(note);
		}
		else
		{
			note = new Note(0, false);
		}
		return note;
	}

	/**
	 * Builds a note sprite from the specified data.
	 * @param data The data to build the note off of.
	 * @return A note sprite that's ready to be used.
	 */
	function buildNote(data:SongNoteData):Note
	{
		var note:Note = constructNote();
		note.inCharter = false;
		note.noteData = data;
		note.direction = data.getDirection();
		note.originalType = data.getDirection();
		note.mustPress = this.isPlayer;

		note.hasBeenHit = false;
		note.tooEarly = true;
		note.tooEarly = true;

		note.setStrum(this);
		note.setCharacter();

		note.buildNoteGraphic(data.noteStyle);
		note.baseStyle = note.noteStyle;
		note.y = -9999;
		note.alpha = 1.0;
		note.visible = true;
		note.scrollFactor.set();
		return note;
	}

	/**
	 * Creates, or recycles a hold note to be reused.
	 * @return A newly created, or previously used note.
	 */
	function constructHoldNote():SustainNote
	{
		var note:SustainNote = null;

		note = recyclableHoldNotes.getFirstAvailable();

		if (note != null)
		{
			// Revive the previously used hold note.
			note.revive();
			this.recyclableHoldNotes.remove(note);
		}
		else
		{
			// Create a new one to be built later on.
			note = new SustainNote(0, 0, false, 0);
		}
		return note;
	}
	
	/**
	 * Builds a hold note sprite from the specified data.
	 * @param data The data to build the note off of.
	 * @return A hold note sprite that's ready to be used.
	 */
	function buildHoldNote(data:SongNoteData, parentNote:Note):SustainNote
	{
		// Setup graphic.
		var holdNote:SustainNote = constructHoldNote();
		
		// Copy properties from parent note.
		holdNote.parentStrumline = this;
		holdNote.strum = parentNote.strum;
		holdNote.character = parentNote.character;
		holdNote.localScrollSpeed = parentNote.LocalScrollSpeed;

		holdNote.noteData = data;
		holdNote.strumTime = data.time;
		holdNote.direction = data.getDirection();
		holdNote.type = data.type;
		holdNote.fullSustainLength = data.length;
		holdNote.sustainLength = data.length;
		holdNote.baseStyle = parentNote.baseStyle;
		holdNote.noteStyle = parentNote.noteStyle;

		holdNote.hasBeenHit = false;
		holdNote.hasMissed = false;
		holdNote.handledMiss = false;
		holdNote.inCharter = false;
		holdNote.localScrollSpeed = 1;
		holdNote.flipY = (scrollType == 'downscroll');

		holdNote.copyStrum();
		holdNote.updateAnimations();
		holdNote.redraw();
		holdNote.updateAlpha();

		holdNote.y = -9999;
		holdNote.scrollFactor.set();
		holdNote.visible = true;

		return holdNote;
	}

	/**
	 * Creates, or recycles a new hold cover to be built onto a hold note.
	 * @return A new hold cover.
	 */
	function constructHoldCover():HoldCover
	{
		var holdCover:HoldCover = recyclableHoldCovers.getFirstAvailable();

		if (holdCover != null)
		{
			// Revive a new hold cover to re-use.
			holdCover.revive();
			recyclableHoldCovers.remove(holdCover);
		}
		else
		{
			// Create a new hold cover.
			holdCover = new HoldCover(0, 'normal');	
		}
		holdCover.alpha = this.alpha;
		this.holdCovers.add(holdCover);
		return holdCover;
	}

	/**
	 * Sets up a new hold cover to use for a hold note.
	 * @param holdNote The hold note to build the hold cover off of.
	 * @return A new hold cover ready to be used.
	 */
	function startHoldCover(holdNote:SustainNote):HoldCover
	{
		var noteStyle:NoteStyle = holdNote.noteStyle;

		if (!noteStyle.hasHoldCovers)
			return null;

		var holdCover:HoldCover = constructHoldCover();
		if (holdCover != null)
		{
			holdCover.direction = holdNote.direction;
			holdCover.noteStyle = noteStyle;
			holdCover.strum = strums.members[holdNote.direction];
			holdNote.cover = holdCover;
			holdCover.holdNote = holdNote;
			
			// This helps prevent the hold cover showing for 1 frame before being applied.
			holdCover.alpha = holdCover.strum.alpha;
			holdNote.cover.playStart();

			holdCover.visible = true;

			holdCover.onKill.add(killHoldCover);
		}
		return holdCover;
	}

	/**
	 * Registers a note from this strumline as hit.
	 * @param note The note to hit.
	 */
	public function hitNote(note:Note)
	{
		strums.members[note.direction].playConfirm();

		note.hasBeenHit = true;
		if (note.sustainNote != null)
		{
			note.sustainNote.hasBeenHit = true;
			note.sustainNote.hasMissed = false;
			note.sustainNote.handledMiss = false;
			
			note.sustainNote.sustainLength = (note.sustainNote.strumTime + note.sustainNote.fullSustainLength) - conductor.songPosition;

			startHoldCover(note.sustainNote);
		}
		onNoteHit.dispatch(note);
		
		killNote(note);
	}

	/**
	 * Remove a note from it's associated rendering group.
	 * @param note The note to destroy.
	 */
	public function killNote(note:Note)
	{
		if (note == null)
			return;
		
		note.visible = false;

		note.kill();
		recyclableNotes.add(note);
	}

	/**
	 * Destroy a sustain note, and removes it from it's rendering group.
	 * @param note The sustain note to destroy.
	 */
	public function killSustain(note:SustainNote)
	{
		if (note == null)
			return;

		note.visible = false;
		note.kill();
		
		sustains.remove(note, false);
		recyclableHoldNotes.add(note);
	}
	
	/**
	 * Kills a hold cover, and removes it from it's rendering group.
	 * @param cover The cover to kill.
	 */
	public function killHoldCover(cover:HoldCover)
	{
		if (cover == null)
			return;

        cover.holdNote.cover = null;

		recyclableHoldCovers.add(cover);
		holdCovers.remove(cover);
		
		cover.onKill.removeAll();
	}

    /**
     * Iterates through each strum receptor.
     * @param func The function to call for each strum.
     */
    public function forEachStrum(func:StrumNote->Void)
    {
        for (i in strums.members)
		{
            if (i != null) 
			{
                func(i);
            }
        }
    }

	/**
	 * Iterates through each rendering note.
	 * @param func The function to call for each note.
	 */
	public function forEachNote(func:Note->Void)
	{
		for (i in notes.members)
		{
			if (i == null || !i.exists || !i.alive) continue;
			
			func(i);
		}
	}

	/**
	 * Iterates through each rendering hold note.
	 * @param func The function to call for each note.
	 */
	public function forEachHoldNote(func:SustainNote->Void)
	{
		for (i in sustains.members)
		{
			if (i == null || !i.exists || !i.alive) continue;
			
			func(i);
		}
	}

	/**
	 * Called when the specific note direction key is pressed.
	 * @param direction The note direction to press.
	 */
	public function pressKey(direction:Int)
	{
		heldKeys[direction] = true;
	}

	/**
	 * Called when the specific note direction key is pressed.
	 * @param direction The note direction to release.
	 */
	public function releaseKey(direction:Int)
	{
		heldKeys[direction] = false;
	}

	/**
	 * Checks whether the given note direction key is being pressed.
	 * @param direction The direction to check.
	 * @return Whether the direction key is pressed.
	 */
	function isKeyHeld(direction:Int):Bool
	{
		return heldKeys[direction];
	}

	/**
	 * Gets a list of notes that are within the hit window.
	 * @return A list of note that this strumline is able to hit.
	 */
	public function getPossibleNotes():Array<Note>
	{
		return notes.members.filter(function(note:Note) {
			return note != null && note.alive && note.canBeHit && !note.tooEarly && !note.tooLate && !note.hasBeenHit;
		});
	}

	/**
	 * The default function for calculating the y position of a note.
	 * @param strumTime The note's strum time to calculate the position for.
	 * @param strumLine The target strumline object the note's going to.
	 * @param speed The speed in which the note is going at.
	 * @param downScroll Whether the note's rendering on downscroll.
	 * @return A y position, in pixels, to be used for the note.
	 */
	function yFromStrumTime(strumTime:Float, strumLine:FlxSprite, speed:Float, downScroll:Bool):Float
	{
		var change = downScroll ? -1 : 1;
        var strumLineY = strumLine != null ? strumLine.y : this.y;
		var val:Float = strumLineY - (conductor.songPosition - strumTime) * (change * pixelsPerMs * speed);

		return val;
	}
    
	/**
	 * Rotates a position by a certain angle and multiplier.
	 * TODO: Put this in it's own utility class?
	 * @param dist The base distance to calculate off of.
	 * @param angle The angle to rotate the 'distance'
	 * @param ymult A multipler for the y value after the distance has been rotated.
	 * @return A rotated point.
	 */
	function rotatePosition(dist:Float, angle:Float, ?ymult:Float = 1):FlxPoint
	{
		var point:FlxPoint = new FlxPoint();
		point.y = (dist * Math.sin((angle) * FlxAngle.TO_RAD)) * ymult;
		point.x = (dist * Math.cos((angle) * FlxAngle.TO_RAD)) * -1;

		return point;
	}

	/**
	 * Compares a note by it's 'strumTime' value.
	 * TODO: Put this in it's own sorting utility?
	 * @param Obj1 The first note data to compare.
	 * @param Obj2 The second note data to compare.
	 * @return A comparing value to use when sorting.
	 */
	function sortByDataStrumTime(Obj1:SongNoteData, Obj2:SongNoteData):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1?.time, Obj2?.time);
	}
	
	/**
	 * Compares a note by it's 'strumTime' value.
	 * TODO: Put this in it's own sorting utility?
	 * @param order The order to sort the notes in.
	 * @param Obj1 The first note to compare.
	 * @param Obj2 The second note to compare.
	 * @return A comparing value to use when sorting.
	 */
	function compareNotes(order:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(order, Obj1?.strumTime, Obj2?.strumTime);
	}
	
	/**
	 * Compares a hold note by it's 'strumTime' value.
	 * TODO: Put this in it's own sorting utility?
	 * @param order The order to sort the notes in.
	 * @param Obj1 The first note to compare.
	 * @param Obj2 The second note to compare.
	 * @return A comparing value to use when sorting.
	 */
	function compareHoldNotes(order:Int, Obj1:SustainNote, Obj2:SustainNote):Int
	{
		return FlxSort.byValues(order, Obj1?.strumTime, Obj2?.strumTime);
	}

	override function set_x(value:Float):Float
	{
		var diff:Float = value - this.x;

		// Make sure the base X doesn't change for the strums if this strumline moves.
		forEachStrum((strum:StrumNote) -> 
		{
			strum.baseX += diff;
		});

		return super.set_x(value);
	}
}