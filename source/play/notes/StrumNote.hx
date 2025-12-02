package play.notes;

import flixel.FlxG;
import flixel.FlxSprite;

/**
 * A visual receptor used to help calculate note positions, and give visual feedback while playing.
 */
class StrumNote extends FlxSprite
{
	/**
	 * The current note style being used for this strum.
	 */
	public var style(default, set):NoteStyle;
	
	function set_style(value:NoteStyle):NoteStyle 
	{
		if (style != value)
		{
			this.x -= style.noteStyleOffsets.x;
			this.y -= style.noteStyleOffsets.y;

			value.applyStyleToStrum(this);

			baseScale = [value.styleSize, value.styleSize];
			return style = value;
		}
		return value;
	}

	/**
	 * The x position, in terms of the strumline position, in which the strum is centered.
	 * Essentially, the 'middlescroll' position.
	 */
	public var centerX(get, null):Float;

	function get_centerX():Float
		return baseX + 320 * (playerStrum ? -1 : 1) + 78 / 4;

	/**
	 * The style from when this strum was first created.
	 */
	public var baseStyle:NoteStyle;

	/**
	 * The x posiiton from when the strum was first created.
	 */
	public var baseX:Float;
	
	/**
	 * The y position from when the strum was first created.
	 */
	public var baseY:Float;

	/**
	 * The scale from when the strum was first created.
	 */
	public var baseScale:Array<Float> = [];
	
	/**
	 * The trigonometric rotation of this strum object.
	 * Used for when the notes use trigonometric rotation for calculation it's position.
	 */
	public var rotation:Float;

	/**
	 * Whether this strum is controlled by the player, or cpu.
	 */
	public var playerStrum:Bool;
	
	/**
	 * Internal variable used for shape notes to used for whether the 'key5' button is pressed.
	 */
	public var pressingKey5:Bool;

	/**
	 * A Map representing the offsets used for any animations that need them.
	 */
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();


	public function new(x:Float, y:Float, type:NoteStyle, strumID:Int, playerStrum:Bool)
	{
		super(x, y);
		
		scrollFactor.set();

		baseY = y;
		pressingKey5 = false;
		this.playerStrum = playerStrum;
		ID = strumID;

		style = type;
		baseStyle = type;
		
		baseScale = [baseStyle.styleSize, baseStyle.styleSize];
		
		animation.onFinish.add(function(name:String)
		{
			switch (name)
			{
				case 'confirm':
					if (!this.playerStrum)
					{
						playAnim('static');
					}
			}
		});
	}

	/**
	 * Plays the strum's 'static' animation. 
	 * @param force Whether to play the animation immediately.
	 */
	public function playStatic(force:Bool = true)
	{
		playAnim('static', force);
	}
	
	/**
	 * Plays the strum's 'press' animation.
	 * @param force Whether to play the animation immediately.
	 */
	public function playPress(force:Bool = true)
	{
		playAnim('pressed', force);
	}

	/**
	 * Plays the strum's 'confirm' animation. 
	 * @param force Whether to play the animation immediately.
	 */
	public function playConfirm(force:Bool = true)
	{
		playAnim('confirm', force);
	}

	/**
	 * Plays the confirm animation for when a hold note is being held down.
	 * Normally, this is the same as the regular confirm animation.
	 * However, this is a separate animation to allow for customizability.
	 */
	public function holdConfirm(force = false)
	{
		if (animation.curAnim.name == 'confirm-hold')
		{
			return;
		}
		playAnim('confirm-hold', force);
	}

	/**
	 * Plays a strum animation. Takes into account any offsets that need to be done.
	 * @param anim The animation to play.
	 * @param force Whether the animation should immediately play, or wait until no other animation is playing.
	 */
	public function playAnim(anim:String, force:Bool = false)
	{
		animation.play(anim, force);
		
		centerOrigin();
		centerOffsets();
		
		if (animOffsets.exists(anim)) {
			var offsets = animOffsets.get(anim);
			
			offset.x += offsets[0];
			offset.y += offsets[1];
		}
	}

	public inline function resetX()
		x = baseX;

	public inline function resetY()
		y = baseY;

	public inline function centerStrum()
		x = centerX;
}