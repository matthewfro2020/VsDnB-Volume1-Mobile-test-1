package play.character;

import backend.Conductor;
import data.IRegistryEntry;
import data.animation.Animation;
import data.character.CharacterData;
import data.character.CharacterRegistry;
import controls.PlayerSettings;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import play.notes.Note;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import scripting.IScriptedClass.IPlayStateScriptedClass;


/**
 * A type definition that defines the parameters for adding custom animations for this character.
 * This is used for if the character has animations that aren't in their spritesheet, and needs it to be loaded separately into the character.
 */
typedef CharacterSheet =
{
	var path:String;
	var anims:Array<AnimationData>;
	var ?offsetFile:String;
}

/**
 * Defines the type of player this character is.
 * Will change the behavior of how the characters work based on this.
 */
enum CharacterType
{
	PLAYER;
	OPPONENT;
	GF;
	OTHER;
}

/**
 * A player that universally bops to the beat.
 * Used both in-game being controlled by their associated strumlines, and outside used as props.
 * 
 * The behavior of the character differentiate depending on if they're CPU controlled, or not.
 */
class Character extends FlxSprite implements IRegistryEntry<CharacterData> implements IPlayStateScriptedClass
{
	// DATA //

    /**
     * The id of the entry.
     */
    public final id:String;

	public var _data:CharacterData;

	/**
	 * The readable name of this character.
	 */
	public var characterName(get, never):String;

	function get_characterName():String
	{
		return _data?.name ?? 'Unknown';
	}
	
	/**
	 * The health icon id for this character.
	 */
	public var characterIcon(get, never):String;
	
	function get_characterIcon():String
	{
		return _data?.icon ?? id;
	}
	
	/**
	 * A list of offsets to use when their given animation is played.
	 * Used mostly to offset sing animations that are offsetted.
	 */
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	
	/**
	 * The global offset used for positioning the character.
	 * This is calculated normally based on the bottom-center of BF's character.
	 */
	public var globalOffset:Array<Float> = new Array<Float>();

	/**
	 * The global offset used for positioning the character.
	 * This is calculated normally based on the bottom-center of BF's character.
	 */
	public var cameraOffset:Array<Float> = new Array<Float>();

	/**
	 * The universal color used for this character.
	 * This is used for the character's health bar, and also to help specialize a character if needed.
	 */
	public var characterColor:FlxColor;

	/**
	 * This character dances every `x` beats.
	 * 
	 * Defaults to 2, but if the character has a special way of dancing, this is recommended.
	 */
	public var danceSnap:Int = 2;

	/**
	 * The amount of time, the character should sing for in steps.
	 */
	public var singDuration:Float = 4;
	
	/**
	 * The type of graphic to use for the countdown.
	 * Only works for if this character does the countdown.
	 */
	public var countdownGraphicType:String = 'normal';

	/**
	 * The type of sound to use for the character.
	 * Only works for if this character does the countdown.
	 */
	public var countdownSoundType:String = 'default';
	
	/**
	 * A list that maps all of the skins associated with this character.
	 * Used to help customize the character.
	 *
	 * Some examples include:
	 *  
	 * - If you want the character to have a custom GF skin, you would do:
	 * ```haxe
	 * this.skins.set('gfSkin', characterId);
	 * ```
	 * 
	 * - If you want the character to have a custom note skin, you would do:
	 * ```haxe
	 * this.skins.set('noteSkin', noteStyleId);
	 * ```
	 */
	public var skins:Map<String, String> = new Map<String, String>();

	/**
	 * A list of all of the current separate data sheets this character is running on.
	 */
	public var sheetsInUse(default, null):Array<CharacterSheet> = new Array<CharacterSheet>();


	// GENERAL //

	/**
	 * The type of player this character is.
	 */
	public var characterType:CharacterType = PLAYER;

	/**
	 * Whether this character is being used for debugging purposes.
	 * Completely disables all character logic for it to be controlled.
	 */
	public var debugMode:Bool = false;

	/**
	 * The conductor this player runs on.
	 * If there's no conductor set, it runs on `Conductor.instance`
	 * 
	 * Useful for if you want a background character bopping to a different song.
	 */
	public var conductor(get, set):Conductor;

	function get_conductor():Conductor
	{
		if (_conductor == null) return Conductor.instance;
		return _conductor;
	}

	function set_conductor(value:Conductor)
	{
		// Remove the signals from the current conductor.
		removeConductor(conductor);

		// Set up the signals for the new conductor.
		setupConductor(value);

		return _conductor = value;
	}

	var _conductor:Conductor;
	
	/**
	 * The offsets used for the camera when a character hits a note.
	 * Makes the camera move a specific given direction.
	 */
	public var cameraNoteOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * The position the camera should go to when focusing on this character.
	 * This should be at the character's center position, with offsets if necessary.
	 * 
	 * Updates automatically whenever the position of the character updates.
	 */
	public var cameraFocusPoint(default, null):FlxPoint = FlxPoint.get();

	/**
	 * The player has reached the game over screen, and has died.
	 * Will disable any playable functionability to ensure they stay dead.
	 */
	public var isDead:Bool;
	
	/**
	 * Whether this character should be the one to start the countdown.
	 * Normally used for if the player should start the countdown instead of the opponent.
	 */
	public var startsCountdown:Bool = false;


	// SCALING //
	
	/**
	 * The original scale of the character from when they were first initalized.
	 * Used to help calculate the character's scale so they're relative. 
	 */
	public var baseScale:Float = 1;

	/**
	 * How much character offsets should be scaled.
	 * Normally this is the same as the character's current scale.
	 */
	public var offsetScale:Float = 1.0;
	
	/**
	 * The offsets based on the character's current scale.
	 * Used to help make sure characters are positioned.
	 */
	public var scaleOffset(default, null):FlxPoint = FlxPoint.get();
	
	
	// DANCING //

	/**
	 * Whether this character is able to dance, or not.
	 * Helpful for if you want to play a special animation.
	 */
	public var canDance:Bool = true;

	/**
	 * A list containing all the types of ways the character can dance.
	 * Helps allow for customizing how the character should dance.
	 * 
	 * Some examples of dance types that can be used are:
	 * 
	 * - Idle (`idle`)
	 *   - The default dance type. One simple animation that bops the character.
	 * 
	 * - Alternate (`alternate`)
	 *   - The character will dance based on their left, and right animation like GF.
	 * 
	 * - Easing (`ease`, `-ease`)
	 *   - The character will wait before the animation has finished playing, before dancing.
	 *   - Configurable to have it only ease for the idle, sing animations, or any animation at all.
	 */
	public var danceTypes:Array<String> = ['idle'];
	

	/**
	 * Adds to the character's dance animation, and plays based on it.
	 * Useful for alternate dance animations. 
	 */
	public var altDanceSuffix:String = '';

	/**
	 * Whether the character has danced, or not.
	 * Used for the alternate dancing animation to bop left, and right.
	 */
	private var danced:Bool = false;


	// SINGING //

	/**
	 * Whether this character is able to sing, or not.
	 * Completely disables the character from being able to sing when hitting notes if false.
	 */
	public var canSing:Bool = true;
	
	/**
	 * Adds to the character's sing animation, and plays the animations based off it.
	 * Useful for if you want the character to easily use alternate sing animations.
	 */
	public var altSingSuffix:String = ''; 

	/**
	 * The time the character has been singing for, in milliseconds.
	 * 
	 * Used to make sure the character sings for a specific amount of steps before dancing again.
	 * This helps to prevent them from dancing in-between notes.
	 */
	public var holdTimer:Float = 0;
	
	/**
	 * This character should flip their LEFT, and RIGHT animations when they're the opponent.
	 */
	public var nativelyPlayable:Bool;


    /**
     * Retrieves a new instance of a character from the given id.
     * 
     * Alias for `CharacterRegistry.instance.fetchEntry(id)`
	 * 
	 * @param x The x position of the character.
	 * @param y The y position of the character.
     * @param id The id of the character to create.
	 * @param characterType the type of character it's supposed to be.
	 * 
     * @return A new `Character` instance.
     */
	public static function create(?x:Float = 0, ?y:Float = 0, id:String, ?characterType:CharacterType = OTHER):Character
	{
		var char:Character = CharacterRegistry.instance.fetchEntry(id);
		char.characterType = characterType;
		char.setPosition(x, y);
		
		// Initalize the character through a script event.
		ScriptEventDispatcher.callEvent(char, new ScriptEvent(CREATE, false));
		
		return char;
	}

	/**
	 * Creates a new character instance.
	 * @param id The id of the character.
	 */
	public function new(id:String)
	{
		super(x, y);

		this.id = id;

		_data = fetchData(id);

		this.globalOffset = _data.globalOffset;
		this.danceSnap = _data.danceSnap;
		this.singDuration = _data.singDuration;
		this.characterColor = FlxColor.fromString(_data.color);

		this.countdownGraphicType = _data.countdownData.graphicPath;
		this.countdownSoundType = _data.countdownData.soundPath;

		this.antialiasing = _data.antialiasing;

		// Setting this property initalizes the character's offsets.
		this.flipX = _data.flipX;
		this.nativelyPlayable = _data.nativelyPlayable;
		
		skins.set('normal', id);
		skins.set('gfSkin', 'gf-none');
		skins.set('noteSkin', 'normal');
		skins.set('deathSkin', 'generic-death');
	}

	override function update(elapsed:Float)
	{
		if (animation == null || animation.curAnim == null)
		{
			super.update(elapsed);
			return;
		}
		
		super.update(elapsed);

		// Disable any character functionability if this character is being used for debugging purposes.
		if (debugMode || isDead)
			return;

		// Reset the hold timer if the player has pressed a key.
		if (justPressedNote() && characterType == PLAYER)
		{
			holdTimer = 0;
		}

		var shouldStopSinging:Bool = (this.characterType == PLAYER) ? !isHoldingNote() : true;

		// A special animation is playing, wait for it to finish before continue to dance.
		if (!isSingAnimation(animation.curAnim.name) && !isDanceAnimation(animation.curAnim.name) && !animation.curAnim.finished)
		{
			shouldStopSinging = false;
		}

		if (isSinging())
		{
			holdTimer += elapsed;

			var singTimeSteps:Float = (conductor.stepCrochet / 1000) * singDuration;
			if (holdTimer >= singTimeSteps && shouldStopSinging)
			{
				holdTimer = 0;
				dance(true);
			}
		}
		else
		{
			holdTimer = 0;
		}
	}

	override function destroy()
	{
		scaleOffset.put();
		removeConductor(conductor);

		super.destroy();
	}
	
    /**
     * Returns a string representation of this entry.
     * @return String
     */
    override function toString():String
	{
		return 'Character(id = $id, name=$characterName, type=$characterType)';
	}

	public function onCreate(event:ScriptEvent):Void
	{
		// When the animation finishes, play the dance animation again.
		animation.onFinish.add(function(anim:String)
		{
			if (hasEase(anim)) {
				holdTimer = 0;
				dance(true);
			}
		});

		// Setup the conductor add the signals.
		setupConductor(conductor);
		
		load();

		// This must be set after the character's sprite is loaded so the offsets are set properly.
		this.setScale(_data.scale, _data.scale);
		this.baseScale = _data.scale;

		dance(true);
		updateHitbox();

		resetCameraFocusPoint();

		if (characterType == PLAYER)
		{
			this.flipX = !flipX;
		}
	}

	
	/**
	 * Loads, and initalizes the character to be used.
	 * Mostly handled through the character's script.
	 */
	function load():Void {}

	/**
	 * Gets the data for a character given an id.
	 * @param id The id of the data to retrieve.
	 */
	public function fetchData(id:String):CharacterData
	{
		return CharacterRegistry.instance.fetchData(id);
	}

	/**
	 * Plays the dance animation, and handles dancing logic.
	 */
	public function dance(force:Bool = false):Void
	{
		// If the character isn't able to dance.
		// Or the current animation playing has easing and isn't finished yet
		// We don't want to be able to dance.
		if (!canDance || (!force && hasEase() && !animation.finished))
			return;
		
		if (!force && isSinging())
		{
			return;
		}
		
		cameraNoteOffset.set();

		if (danceTypes.contains('alternate'))
		{
			danced = !danced;

			if (danced)
				playAnim('danceRight', true);
			else
				playAnim('danceLeft', true);
		}
		else
		{
			playAnim('idle', true);
		}
	}

	/**
	 * Plays the sing animation for a given direction.
	 * @param direction The direction to play.
	 * @param miss Whether to play the miss variant.
	 * @param alt Optional, alt suffix to play for the animation.
	 * @param singArray The list of sing directions to play based on.
	 */
	public function sing(direction:Int, ?miss:Bool = false, ?alt:String = '', ?singArray:Array<String>)
	{
		if (singArray == null)
			singArray = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

		var noteToPlay:String = singArray[direction];

		holdTimer = 0;

		if ((characterType == PLAYER && !nativelyPlayable) || (characterType == OPPONENT && nativelyPlayable))
		{
			noteToPlay = switch (noteToPlay)
			{
				case 'LEFT': 'RIGHT';
				case 'RIGHT': 'LEFT';
				default: noteToPlay;
			}
		}
		if (miss)
		{
			noteToPlay += 'miss';
		}
		playAnim('sing${noteToPlay}' + alt, true);
	}

	/**
	 * Adds a new character atlas sheet onto the character.
	 * Only supports SparrowAtlas sheets.
	 * 
	 * @param path The path of the sheet to add.
	 * @param animations The animations to add from this sheet. 
	 * @param offsetFile Optional, the offset file containing additional offsets for animations from this sheet.
	 */
	public function addCharAtlas(path:String, animations:Array<AnimationData>, ?offsetFile:String):Void
	{
		cast(frames, FlxAtlasFrames).addAtlas(Paths.getSparrowAtlas(path));

		for (i in animations)
		{
			Animation.addToSprite(this, i);
		}
		if (offsetFile != null)
		{
			loadOffsetFile(offsetFile);
		}
		sheetsInUse.push({path: path, anims: animations, offsetFile: offsetFile});
	}

	/**
	 * Plays an animation for this character. Accounts for offsets, and any additional suffixes.
	 * @param AnimName The animation to play.
	 * @param Force Whether to play this animation immediately, or wait.
	 * @param Reversed (Optional) Whether to play this animation in reverse.
	 * @param Frame (Optional) The frame to start on.
	 */
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (animation == null || animation.getByName(AnimName) == null 
			|| (isDanceAnimation(AnimName) && !canDance) || (isSingAnimation(AnimName) && !canSing))
		{
			return;
		}

		// Increment the animation using the suffix based on the type.
		AnimName += switch (AnimName)
		{
			case (isDanceAnimation(_.toLowerCase())) => true: altDanceSuffix;
			case (isSingAnimation(_.toLowerCase())) => true: altSingSuffix;
			default: '';
		}

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set((daOffset[0] * offsetScale) + scaleOffset.x, (daOffset[1] * offsetScale) + scaleOffset.y);
		}
		else
			offset.set(scaleOffset.x, scaleOffset.y);
	}
	

    /**
     * Dispatched when the opponent hits a note.
     * @param event The data associated with this note.
     */
    public function onOpponentNoteHit(event:NoteScriptEvent):Void {}

    /**
     * Dispatched when the player hits a note.
     * @param event The data associated with this note.
     */
    public function onPlayerNoteHit(event:NoteScriptEvent):Void {}
	
    public function onNoteMiss(event:NoteScriptEvent):Void
	{
		if (event.eventCanceled || event.note.character != this)
			return;

		switch (characterType)
		{
			case GF:
				playAnim('sad', true);
			case PLAYER:
				var note:Note = event.note;
				switch (note.noteStyle)
				{
					default:
						this.sing(note.direction, true);
				}
			default:
		}
	}
	
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void
	{
		if (event.eventCanceled || event.character != this)
			return;

		switch (characterType)
		{
			case GF:
				playAnim('sad', true);
			case PLAYER:
				this.sing(event.direction, true);
			default:
		}
	}
	
    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void
	{
		if (event.eventCanceled || event.character != this)
			return;

		switch (characterType)
		{
			case GF:
				playAnim('sad', true);
			case PLAYER:
				this.sing(event.holdNote.direction, true);
			default:
		}
	}
	
	/**
	 * Plays the GF hey based on the player's current combo.
	 * @param combo The current combo the player has.
	 */
	public function playComboAnimation(combo:Int)
	{
		// Play the GF hey animation every 100 combo hits.
		if (combo % 100 == 0 && this.animation.getByName("cheer") != null)
		{
			this.canDance = false;
			this.playAnim('cheer', true);
			this.animation.onFinish.addOnce(function(anim:String) {
				this.canDance = true;
			});
		}
	}

	/**
	 * Checks whether a given animation is qualified to having ease.
	 * This checks based on the dance types this character has.
	 * @param anim The animation to check.
	 * @return Whether this animation has easing, or not.
	 */
	public function hasEase(?anim:String):Bool
	{
		var animToDo:String = anim == null ? (animation?.curAnim?.name ?? "") : anim;
		var animToCheck:String = '';
		var hasEase:Bool = false;

		for (i in danceTypes)
		{
			if (i == 'ease' || (i.endsWith('-ease') && (animToDo + '-ease') == i))
			{
				return true;
			}

			if (isDanceAnimation(animToDo))
			{
				animToCheck = 'idle';
			}
			else if (isSingAnimation(animToDo))
			{
				animToCheck = 'pose';
			}

			switch (animToCheck) {
				case 'idle': hasEase = (i == 'idleEase');
				case 'pose': hasEase = (i == 'poseEase');
			}
			if (hasEase) return true;
		}
		return false;
	}

	/**
	 * Is this character currently playing a sing animation?
	 * @return Whether the character's singing, or not.
	 */
	public function isSinging():Bool
	{
		return isSingAnimation(animation?.curAnim?.name ?? '');
	}

	/**
	 * Sets the scale of this character.
	 * Takes into the account the character's base scale, and offsets.
	 * @param x The x of the scale.
	 * @param y The y of the scale.
	 */
	public function setScale(x:Float, y:Float)
	{
		scale.set(baseScale * x, baseScale * y);
		width = Math.abs(baseScale * x) * frameWidth;
		height = Math.abs(baseScale * y) * frameHeight;
		
		scaleOffset.set(-0.5 * (width - frameWidth), -0.5 * (height - frameHeight));

		resetCameraFocusPoint();
	}

	/**
	 * Resets the camera focus position.
	 * Helpful for if the scale ends up changing.
	 */
	public function resetCameraFocusPoint():Void
	{
		this.cameraFocusPoint.x = this.x + (width / 2) + _data.cameraOffsets[0];
		this.cameraFocusPoint.y = this.y + (height / 2) + _data.cameraOffsets[1];
	}

	/**
	 * Flips the character the other way.
	 */
	public function flip():Void
	{
		this.flipX = !this.flipX;
		this.nativelyPlayable = !this.nativelyPlayable;
	}

	/**
	 * Repositions the character based on their current global position offset.
	 * Used to make sure the character's centered at BF's bottom center.
	 */
	public function reposition():Void
	{
		this.x += this.globalOffset[0];
		this.y += this.globalOffset[1];
	}
	
	/**
	 * Adds the given offsets for an animation.
	 * @param name The animation to given offsets for.
	 * @param x The x position of the offsets.
	 * @param y The y position of the offsets.
	 */
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	/**
	 * Loads an offset file to apply to the given character.
	 * @param character The character to load the offsets from.
	 */
	function loadOffsetFile(character:String):Void
	{
		if (!Assets.exists(Paths.offsetFile(character), TEXT))
		{
			return;
		}
		var offsetData:Array<String> = Assets.getText(Paths.offsetFile(character)).trim().split('\n');

		for (offsetText in offsetData)
		{
			var offsetInfo:Array<String> = offsetText.split(' ');

			addOffset(offsetInfo[0], Std.parseFloat(offsetInfo[1]), Std.parseFloat(offsetInfo[2]));
		}
	}

	/**
	 * Checks whether the user is currently holding on a note key.
	 * @return Whether the user's holding down on a note key.
	 */
	function isHoldingNote():Bool
	{
		return (PlayerSettings.controls.LEFT || PlayerSettings.controls.DOWN || PlayerSettings.controls.UP || PlayerSettings.controls.RIGHT);
	}
	
	/**
	 * Checks whether the user is just pressed a note key.
	 * @return Whether the user has pressed a note.
	 */
	function justPressedNote():Bool
	{
		return (PlayerSettings.controls.LEFT_P || PlayerSettings.controls.DOWN_P || PlayerSettings.controls.UP_P || PlayerSettings.controls.RIGHT_P);
	}
	
	/**
	 * Removes the signals of this character from the given Conductor.
	 * Used to help reset the conductor after it's been changed.
	 * @param input The conductor to remove/
	 */
	function removeConductor(input:Conductor)
	{
		input.onStepHit.remove(stepHit);
		input.onBeatHit.remove(beatHit);
		input.onMeasureHit.remove(measureHit);
	}

	/**
	 * Sets up the signals of this character from the given Conductor.
	 * @param input The conductor to set up.
	 */
	function setupConductor(input:Conductor)
	{
		input.onStepHit.add(stepHit);
		input.onBeatHit.add(beatHit);
		input.onMeasureHit.add(measureHit);
	}

	/**
	 * Checks if a given animation's playing a sing animation.
	 * @param anim The animation to check.
	 * @return Whether the animation's a sing animation.
	 */
	function isSingAnimation(anim:String):Bool
	{
		return anim.startsWith('sing');
	}

	/**
	 * Checks if a given animation's playing a dance animation.
	 * @param anim The animation to check.
	 * @return Whether the animation's a dance animation.
	 */
	function isDanceAnimation(anim:String):Bool
	{
		return (anim.startsWith('idle') || anim.startsWith('dance'));
	}

	/**
	 * Retrieves the character's original flip X from its data.
	 * @return The flipX from the data.
	 */
	function getDataFlipX():Bool
	{
		return _data?.flipX ?? false;
	}
	
	/**
	 * Called when the character's Conductor reaches a step.
	 * @param step The step reached.
	 */
	function stepHit(step:Int) {}

	/**
	 * Called when the character's Conductor reaches a beat.
	 * @param beat The beat reached.
	 */
	function beatHit(beat:Int)
	{
		if (beat % danceSnap == 0 && canDance)
		{
			dance();
		}
	}

	/**
	 * Called when the character's Conductor reaches a measure.
	 * @param measure The step reached.
	 */
	function measureHit(measure:Int) {}
	
	override function set_x(value:Float):Float
	{
		var diff:Float = value - this.x;

		this.cameraFocusPoint.x += diff;

		return super.set_x(value);
	}
	
	override function set_y(value:Float):Float
	{
		var diff:Float = value - this.y;

		this.cameraFocusPoint.y += diff;

		return super.set_y(value);
	}

	override function set_flipX(value:Bool):Bool
	{
		// Reset the character's offsets.
		animOffsets.clear();

		// `getDataFlipX` is supposed to represent the character's flipX for when they're the opponent.
		// So if this value isn't this, then it should switch to using the player's offset if viable.
		var flipped:Bool = value != getDataFlipX();

		loadOffsetFile(flipped ? _data.offsetFilePlayer : _data.offsetFileOpponent);
		return super.set_flipX(value);
	}
	
    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onUpdate(event:UpdateScriptEvent):Void {}

    public function onDestroy(event:ScriptEvent):Void {}

    public function onNoteSpawn(event:NoteScriptEvent):Void {}
	
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
}