package play.notes;

import data.song.SongData.SongNoteData;
import flixel.FlxG;
import flixel.FlxSprite;
import play.PlayState;
import play.character.Character;
import ui.select.playerSelect.PlayerSelect;

/**
 * A visual sprite used both in-game, and outside.
 * 
 * In-game, it's used as a visual for players to hit.
 * Outside of playing, it's usually used as a visual prop.
 */
@:access(play.PlayState)
class Note extends FlxSprite
{
	/**
	 * The default color directions for 4-key notes.
	 */
	public static var COLOR_DIRECTIONS = ['purple', 'blue', 'green', 'red'];

	/**
	 * Whether the note's position should be controlled through trigonometric rotation.
	 * TODO: Re-factor this? 
	 */
	public static var rotate:Bool = false;

	// DATA PROPERTIES // 

	/**
	 * The data representing this note.
	 */
	public var noteData:SongNoteData;

	/**
	 * The time this note's supposed to be hit.
	 */
	public var strumTime(get, set):Float;
	
	function get_strumTime():Float
	{
		return noteData?.time ?? 0.0;
	}
	
	function set_strumTime(value:Float):Float
	{
		if (noteData == null) return value;
		return noteData.time = value;
	}
	
	/**
	 * The direction of the note.
	 */
	public var direction(default, set):Int;

	function set_direction(value:Int):Int
	{
		if (frames == null) return value;
		
		this.direction = value;

		playNoteAnimation();
		return value;
	}
	
	/**
	 * The type of the note this is.
	 */
	public var type(get, set):String;

	function get_type():String
	{
		return noteData?.type ?? '';
	}
	
	function set_type(value:String):String
	{
		if (noteData == null) return value;
		return noteData.type = value;
	}

	/**
	 * Whether this note is cpu controlled, or is supposed to be hit by the player.
	 */
	public var mustPress:Bool = false;


	// PROPERTIES // 
	
	/**
	 * The note style that this note is using.
	 */
	public var noteStyle(default, set):NoteStyle;
	
	function set_noteStyle(value:NoteStyle):NoteStyle 
	{
		if (noteStyle != value) {
			var animPlaying:Null<String> = animation?.curAnim?.name ?? null;

			value.applyStyleToNote(this);
			
			if (animPlaying != null) {
				animation.play(animPlaying, true);
			}
			return noteStyle = value; 
		}
		return value;
	}
	
	/**
	 * The original style of this note from when it was first generated.
	 * Good for keeping track of properties from this structure that can be used later on.
	 */
	public var baseStyle(default, null):NoteStyle;
	
	/**
	 * The scale of this note from when it was first generated.
	 * Helpful for internally making calculations for changing the scale.
	 */
	public var baseScale(get, never):Float;

	function get_baseScale():Float
	{
		return baseStyle.styleSize;
	}

	// VARIABLES // 

	/**
	 * Flag variable for if the sustain note isn't within the hit window and can't be hit.
	 * Controlled by the note's strumline.
	 */
	public var tooEarly:Bool = false;
	
	/**
	 * Whether the note's in the hit window and is allowed to be hit.
	 */
	public var canBeHit:Bool = false;

	/**
	 * Whether the note has been hit successfully.
	 */
	public var hasBeenHit:Bool = false;

	/**
	 * Flag variable for if the sustain note either too late to be hit, or was dropped as it was being held.
	 */
	public var hasMissed:Bool = false;
	
	/**
	 * Whether the logic for when the sustain note has been done.
	 */
	public var handledMissed:Bool = false;

	/**
	 * Flag variable for if the sustain note either wasn't held within the window.
	 * Controlled by the note's strumline.
	 */
	public var tooLate:Bool = false;

	/**
	 * The sustain note used for when this note needs to be held.
	 */
	public var sustainNote:SustainNote;

	/**
	 * The strum receptor associated with this note.
	 * Normally comes from the opponent's strumline, or the player strumline, but you can customize it if you want!
	 */
	public var strum:StrumNote;

	/**
	 * The character associated with this note.
	 * Normally this is either the opponent, or the player, but you can customize it if you want!
	 */
	public var character:Character;

	/**
	 * The color directions that this note is being used to render this note.
	 * TODO: Maybe re-factor this into it's own class?
	 */
	public var colorDirections:Array<String> = [];

	/**
	 * The scroll speed used for this note.
	 * Is taken into account when calculating it's y position.
	 */
	public var LocalScrollSpeed:Float = 1;
	
	/**
	 * Whether the alpha of this note should be the same as it's parent strumline, if one exists.
	 */
	public var copyAlpha:Bool = true;

	/**
	 * Whether the angle of this note should be the same as it's parent strumline, if one exists.
	 */
	public var copyAngle:Bool = true;

	/**
	 * Whether the scale of this note should be the same as it's parent strumline, if one exists.
	 */
	public var copyScale:Bool = true;
	
	/**
	 * The original direction of the note.
	 * Exists in-case the direction changes due to modcharts, or anything else.
	 */
	public var originalType:Int = 0;

	/**
	 * Internal variable for keeping track of Bambi phone smashes.
	 * TODO: Is this needed?
	 */
	public var phoneHit:Bool;

	/**
	 * This note is being used in chart editor and shouldn't have any gameplay logic done.
	 */
	public var inCharter:Bool;
	
	/**
	 * Modifier for this note's alpha.
	 */
	public var alphaModifier:Float = 1.0;

	public function new(direction:Int, ?musthit:Bool = true, noteStyle:NoteStyle = "normal",
			inCharter:Bool = false)
	{
		super(0, -9999);

		this.direction = direction;
		this.originalType = direction;
		this.mustPress = musthit;
		this.inCharter = inCharter;

		buildNoteGraphic(noteStyle);
		
		this.baseStyle = this.noteStyle;
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// Cancel gameplay logic if this note's being used in the chart editor.
		if (inCharter)
			return;

		if (strum != null) {
			copyStrum();
		}
	}

	override function kill()
	{
		super.kill();

		originalType = 0;

		tooEarly = false;
		tooLate = false;
		canBeHit = false;
		hasMissed = false;
		handledMissed = false;
	}

	override function revive()
	{
		super.revive();

		originalType = 0;
		alpha = 1;
		sustainNote = null;

		hasMissed = false;
		handledMissed = false;
		hasBeenHit = false;
	}
	
	/**
	 * Setups the animations and graphic for this note to used based on a note style.
	 * @param noteStyle The note style to use for this note.
	 */
	function buildNoteGraphic(noteStyle:NoteStyle)
	{
		this.colorDirections = COLOR_DIRECTIONS;

		if (['normal', '', null, "0"].contains(noteStyle) && !inCharter)
		{
			noteStyle = character?.skins?.get('noteSkin') ?? noteStyle;
		}
		this.noteStyle = noteStyle;
		
		playNoteAnimation();
	}

	function playNoteAnimation():Void
	{
		animation.play(this.colorDirections[this.direction] + 'Scroll');
	}

	/**
	 * Copies the properties of this note based on it's parent strum receptor.
	 */
	public function copyStrum()
	{
		if (strum == null) return;

		if (!rotate) 
			x = strum.x + (strum.width - this.width) / 2;
		
		updateAlpha();
		
		if (copyAngle)
		{
			angle = strum.angle;
		}

		if (copyScale)
		{
			scale.x = baseScale * (strum.scale.x / strum.baseScale[0]);
			scale.y = baseScale * (strum.scale.y / strum.baseScale[1]);
		}

		if (strum.pressingKey5)
		{
			if (noteStyle != "shape") alpha *= 0.5;
		}
		else
		{
			if (noteStyle == "shape")
				alpha *= 0.5;
		}
	}

	/**
	 * Updates the alpha for this note. Separate function as this has multiple states where the alpha can change.
	 */
	public function updateAlpha()
	{
		var missModifier:Float = 1.0;
		if (hasMissed)
			missModifier = 0.4;

		if (copyAlpha)
			alpha = strum.alpha * alphaModifier * missModifier;
		else
			alpha = alphaModifier * missModifier;
	}

	/**
	 * Sets the parent strum receptor for this note to use.
	 * If no custom strumline is set, it's either the opponent or player strumline based on it's data properties.
	 * @param strumLine The strumline to get this strum receptor for.
	 */
	public function setStrum(?strumLine:Strumline)
	{
		var strumGroup = strumLine;
		if (strumGroup == null)
		{
			strumGroup = (FlxG.state is PlayState) ? (mustPress ? PlayState.instance.playerStrums : PlayState.instance.dadStrums) : null;
		}
		
		strum = strumGroup?.strums?.members[this.originalType] ?? null;
		copyStrum();
	}

	/**
	 * Sets the parent character for this note to use.
	 * If no custom character is set. It's either the opponent or the player based on it's data properties.
	 * @param char The parent character to use.
	 */
	function setCharacter(?char:Character)
	{
		if (char != null)
		{
			character = char;
			return;
		}
		if (FlxG.state is PlayState)
		{
			mustPress ? {
				if (PlayState.instance.playingChar != null)
				{
					character = PlayState.instance.playingChar;
				}
			} : {
				if (PlayState.instance.dad != null)
				{
					character = PlayState.instance.playerType == PLAYER ? PlayState.instance.dad : PlayState.instance.boyfriend;
				}
			}
		}
	}
}