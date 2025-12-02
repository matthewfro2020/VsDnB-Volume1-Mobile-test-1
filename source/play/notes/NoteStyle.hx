package play.notes;

import backend.Conductor;
import data.animation.Animation.AnimationData;
import flixel.math.FlxPoint;

import flixel.FlxSprite;

/**
 * A structure that represents the data for the style of a note.
 */
@:access(Note)
abstract NoteStyle(String) from String to String
{
	/**
	 * List of note styles that have aliasing.
	 */
	static final aliasedStyles = ['3d', 'pixel', 'shape'];
	
	/**
	 * The path to this the note assets of this note style.
	 */
	public var path(get, never):String;
	
	function get_path():String {
		return 'ui/notes/' + switch (this)
		{
			case '3d': '3d/NOTE_3D_assets';
			case 'shape': 'shape/NOTE_Shape_notes';
			case 'phone' | 'phone-alt': 'phone/NOTE_phone';
			case 'top10': 'top10/OMGtop10awesomehi';
			case 'pixel': 'pixel/NOTE_pixel';
			default: 'normal/NOTE_assets';
		}
	}

	/**
	 * The path to the strumline assets of this note style.
	 */
	public var strumlinePath(get, never):String;

	function get_strumlinePath():String {
		return 'ui/notes/' + switch (this)
		{
			case '3d': '3d/NOTE_3D_strumline';
			case 'shape': 'shape/NOTE_Shape_strumline';
			case 'phone' | 'phone-alt': 'phone/NOTE_phone';
			case 'top10': 'top10/OMGtop10awesomehi';
			case 'pixel': 'pixel/NOTE_pixel_strumline';
			default: 'normal/NOTE_strumline';
		}
	}

	/**
	 * The path to the hold note assets of this note style.
	 */
	public var sustainPath(get, never):String;

	function get_sustainPath():String {
		return 'ui/notes/' + switch (this)
		{
			case '3d': '3d/NOTE_3D_holds';
			case 'shape': 'shape/NOTE_Shape_holds';
			case 'phone' | 'phone-alt': 'phone/NOTE_phone';
			case 'top10': 'top10/OMGtop10awesomehi';
			case 'pixel': 'pixel/NOTE_pixel_hold';
			default: 'normal/NOTE_hold_assets';
		}
	}

	/**
	 * The size of this style.
	 */
	public var styleSize(get, never):Float;

	function get_styleSize():Float {
		return switch (this) 
		{
			case 'pixel': 6;
			case '3d': 0.65;
			default: 0.7;
		}
	}

	/**
	 * The size of a hold cover for this style.
	 */
	public var holdCoverSize(get, never):Float;

	function get_holdCoverSize():Float {
		return switch (this)
		{
			case 'pixel': 6;
			default: 1;
		}
	}

	/**
	 * Whether this note style has antialiasing, or not.
	 */
	public var antialiasing(get, never):Bool;
	
	function get_antialiasing():Bool {
		return !aliasedStyles.contains(this);
	}

	/**
	 * Whether this note style has hold covers.
	 */
	public var hasHoldCovers(get, never):Bool;

	function get_hasHoldCovers():Bool {
		return switch (this) {
			case 'normal', 'pixel', '3d': true;
			default: false;
		}
	}

	public var noteStyleOffsets(get, never):FlxPoint;

	function get_noteStyleOffsets():FlxPoint
	{
		return switch (this) {
			case 'shape': FlxPoint.get(8, 3);
			default: FlxPoint.get(0, 0);
		}
	}


	/**
	 * The type of graphic used for this note style.
	 * This can either be a sparrow asset, or a tiled graphic asset given the width, and height of the asset.
	 */
	var graphicType(get, never):NoteStyleGraphicType;

	function get_graphicType():NoteStyleGraphicType {
		return switch (this) 
		{
			case 'pixel': TILES(17, 17);
			default: Sparrow;
		}
	}

	/**
	 * Applies 'this' note style data onto a note object.
	 * @param sprite The note to apply 'this' note style to.
	 */
	public function applyStyleToNote(sprite:Note)
	{
		loadStyleToSprite(sprite, path);
		applyAnimsToNote(sprite);
		applyPropertiesToNote(sprite);
	}

	/**
	 * Applies 'this' note style data onto a sustain object.
	 * @param sprite The sustain note to apply the note style to.
	 */
	public function applyStyleToSustain(sprite:SustainNote)
	{
		loadStyleToSprite(sprite, sustainPath);
		applyAnimsToSustain(sprite);
		applyPropertiesToSustain(sprite);
	}

	/**
	 * Applies 'this' note style data onto a strum object.
	 * @param sprite The strum to apply the note style to.
	 */
	public function applyStyleToStrum(sprite:StrumNote)
	{
		loadStyleToSprite(sprite, strumlinePath);
		applyAnimsToStrum(sprite);
		applyPropertiesToStrum(sprite);
	}
	
	/**
	 * Applies 'this' note style data onto a hold cover.
	 * @param sprite The hold note to apply the note style to.
	 */
	public function applyStyleToHoldCover(sprite:HoldCover)
	{
		loadStyleToHoldCover(sprite);
		applyAnimsToHoldCover(sprite);
		applyPropertiesToHoldCover(sprite);
	}

	/**
	 * Loads the graphic asset of 'this' note style onto a note sprite.
	 * @param sprite The sprite to apply the graphic asset to.
	 * @param path The path to the sprite.
	 */
	function loadStyleToSprite(sprite:FlxSprite, path:String)
	{
		switch (graphicType) 
		{
			case TILES(width, height):
				switch (this) 
				{
					case 'pixel':
						//TODO: Is there a better way to handle paths for sustains than js this?
						if (sprite is SustainNote) {
							var noteSprite = cast(sprite, SustainNote);
							noteSprite.loadGraphic(Paths.image(path), true, 7, 6);
							return;
						}
						sprite.loadGraphic(Paths.image(path), true, width, height);
					default: 
						sprite.loadGraphic(Paths.image(path), true, width, height);
				}
			case Sparrow:
				sprite.frames = Paths.getSparrowAtlas(path, 'shared');
		}
	}

	/**
	 * Loads the graphic asset of 'this' note style onto a note sprite.
	 * @param sprite The hold cover to apply the graphic asset to.
	 */
	function loadStyleToHoldCover(sprite:HoldCover)
	{
		switch (this)
		{
			case 'pixel':
				sprite.frames = Paths.getSparrowAtlas('ui/notes/pixel/pixelNoteHoldCover', 'shared');
			case '3d':
				var directions:Array<String> = ['purple', 'blue', 'green', 'red'];

				sprite.frames = Paths.getSparrowAtlas('ui/notes/3d/covers/covers_3d_${directions[sprite.direction]}', 'shared');
			default:
				var directions:Array<String> = ['Purple', 'Blue', 'Green', 'Red'];

				sprite.frames = Paths.getSparrowAtlas('ui/notes/normal/covers/holdCover${directions[sprite.direction]}', 'shared');
		}
	}

	/**
	 * Applies the animations of 'this' note style onto a note object.
	 * @param sprite The note to apply the animations to.
	 */
	function applyAnimsToNote(sprite:Note)
	{
		switch (this) {
			case 'pixel':
				sprite.animation.add('purpleScroll', [0]);
				sprite.animation.add('blueScroll', [1]);
				sprite.animation.add('greenScroll', [2]);
				sprite.animation.add('redScroll', [3]);
			case 'shape':
				sprite.animation.addByPrefix('greenScroll', 'green0');
				sprite.animation.addByPrefix('redScroll', 'red0');
				sprite.animation.addByPrefix('blueScroll', 'blue0');
				sprite.animation.addByPrefix('purpleScroll', 'purple0');
			default:
				sprite.animation.addByPrefix('purpleScroll', 'purple0');
				sprite.animation.addByPrefix('blueScroll', 'blue0');
				sprite.animation.addByPrefix('greenScroll', 'green0');
				sprite.animation.addByPrefix('redScroll', 'red0');
		}
	}

	/**
	 * Applies the animations of 'this' note style onto a sustain object.
	 * @param sprite The sustain to apply the animations to.
	 */
	function applyAnimsToSustain(sprite:SustainNote)
	{
		switch (this)
		{
			case 'pixel':
				sprite.animation.add('purplehold', [0]);
				sprite.animation.add('bluehold', [1]);
				sprite.animation.add('greenhold', [2]);
				sprite.animation.add('redhold', [3]);

				sprite.animation.add('purpleholdend', [4]);
				sprite.animation.add('blueholdend', [5]);
				sprite.animation.add('greenholdend', [6]);
				sprite.animation.add('redholdend', [7]);
			case 'shape':
				sprite.animation.addByPrefix('purplehold', 'purple hold piece');
				sprite.animation.addByPrefix('greenhold', 'green hold piece');
				sprite.animation.addByPrefix('redhold', 'red hold piece');
				sprite.animation.addByPrefix('bluehold', 'blue hold piece');

				sprite.animation.addByPrefix('purpleholdend', 'purple hold piece');
				sprite.animation.addByPrefix('greenholdend', 'green hold piece');
				sprite.animation.addByPrefix('redholdend', 'red hold piece');
				sprite.animation.addByPrefix('blueholdend', 'blue hold piece');
			default:
				sprite.animation.addByPrefix('purpleholdend', 'pruple end hold');
				sprite.animation.addByPrefix('blueholdend', 'blue hold end');
				sprite.animation.addByPrefix('greenholdend', 'green hold end');
				sprite.animation.addByPrefix('redholdend', 'red hold end');

				sprite.animation.addByPrefix('purplehold', 'purple hold piece');
				sprite.animation.addByPrefix('bluehold', 'blue hold piece');
				sprite.animation.addByPrefix('greenhold', 'green hold piece');
				sprite.animation.addByPrefix('redhold', 'red hold piece');
		}
		sprite.updateAnimations();
	}

	/**
	 * Applies the animations of 'this' note style onto a strum object.
	 * @param sprite The strum to apply the animations to.
	 */
	function applyAnimsToStrum(sprite:StrumNote)
	{
		var ID:Int = Std.int(Math.abs(sprite.ID));
		switch (this)
		{
			case 'pixel':
				sprite.animation.add('static', [ID]);
				sprite.animation.add('pressed', [4 + ID, 8 + ID], 12, false);
				sprite.animation.add('confirm', [12 + ID, 16 + ID], 12, false);
				sprite.animation.add('confirm-hold', [12 + ID, 16 + ID], 12, false);
			default:
				var anims:Array<String> = ['left', 'down', 'up', 'right'];

				sprite.animation.addByPrefix('static', 'arrow${anims[ID].toUpperCase()}');
				sprite.animation.addByPrefix('pressed', '${anims[ID]} press', 24, false);
				sprite.animation.addByPrefix('confirm', '${anims[ID]} confirm', 24, false);
				sprite.animation.addByPrefix('confirm-hold', '${anims[ID]} confirm', 24, false);
		}
		sprite.playAnim('static');
	}

	/**
	 * Applies 'this' note style's animations to the specified hold cover.
	 * @param sprite The hold cover to apply the animations to.
	 */
	function applyAnimsToHoldCover(sprite:HoldCover)
	{
		switch (this)
		{
			case 'pixel':
				sprite.animation.addByPrefix('loop', 'loop', 24);
			case '3d':
				sprite.animation.addByPrefix('start', 'start', 24, false);
				sprite.animation.addByPrefix('loop', 'loop', 24);
				sprite.animation.addByPrefix('end', 'end', 24, false);
			default:
				sprite.animation.addByPrefix('start', 'sustain cover pre0', 24, false);
				sprite.animation.addByPrefix('loop', 'sustain cover0', 24);

				// Criticism vowed against having the splashes.
				sprite.animation.addByPrefix('end', 'sustain cover pre0', 24, false);
		}
	}

	/**
	 * Applies the properties of 'this' note style onto a note object.
	 * @param sprite The note to apply the properties to.
	 */
	function applyPropertiesToNote(sprite:Note)
	{
		sprite.scale.set(styleSize, styleSize);
		sprite.updateHitbox();
		sprite.antialiasing = antialiasing;
		
		switch (this) {
			case 'phone', 'phone-alt':
				sprite.LocalScrollSpeed = 1.08;
			default: 
				sprite.LocalScrollSpeed = 1;
		}
	}

	/**
	 * Applies the properties of 'this' note style onto a sustain object.
	 * @param sprite The sustain to apply the properties to.
	 */
	function applyPropertiesToSustain(sprite:SustainNote)
	{
		sprite.scale.x = styleSize;
		sprite.antialiasing = antialiasing;
		
		switch (this) {
			case 'shape':
				sprite.subdivisions = Std.int(Math.floor(sprite.fullSustainLength / Conductor.instance.stepCrochet));
		}
	}

	/**
	 * Applies the properties of 'this' note style onto a strum object.
	 * @param sprite The strum to apply the properties to.
	 */
	function applyPropertiesToStrum(sprite:StrumNote)
	{
		sprite.scale.set(styleSize, styleSize);
		sprite.updateHitbox();
		
		sprite.antialiasing = antialiasing;
		
		switch (this)
		{
			default:
				sprite.animOffsets.set('confirm', [0, 0]);
		}

		sprite.x += noteStyleOffsets.x;
		sprite.y += noteStyleOffsets.y;
	}

	/**
	 * Applies the properties of 'this' note style onto a strum object.
	 * @param sprite The hold cover to apply the properties to.
	 */
	function applyPropertiesToHoldCover(sprite:HoldCover)
	{
		sprite.scale.set(holdCoverSize, holdCoverSize);
		sprite.updateHitbox();

		sprite.antialiasing = antialiasing;
	}
}

enum NoteStyleGraphicType
{
	Sparrow;
	TILES(width:Int, height:Int);
}