package play.notes;

import flixel.FlxSprite;
import flixel.util.FlxSignal.FlxTypedSignal;

/**
 * A visual animation that's played while a hold note is being clipped.
 */
@:access(play.notes.Strumline)
class HoldCover extends FlxSprite
{
    /**
     * The note style of the hold cover.
     */
    public var noteStyle(default, set):NoteStyle = '';

    function set_noteStyle(value:NoteStyle) {
        if (noteStyle == value)
            return value;

        setupHoldCoverSprite(value);

        return noteStyle = value;
    }

    /**
     * The direction of the hold cover. 
     * This is usually the same direction of the hold note.
     */
    public var direction(default, set):Int;

    function set_direction(value:Int) {
        this.direction = value;
        setupHoldCoverSprite(noteStyle);
        return this.direction;
    }

    /**
     * The strum related to this hold cover.
     */
    public var strum:StrumNote;

    /**
     * The hold note associated with this cover.
     */
    public var holdNote:SustainNote;

    /**
     * Signal that fires whenever this hold cover has been killed.
     */
    public var onKill(default, null):FlxTypedSignal<HoldCover->Void> = new FlxTypedSignal<HoldCover->Void>();

    var isFinished:Bool = false;

    /**
     * Initalize a new hold cover sprite. 
     * Usually only needed to do if all of the hold covers are full, and none are them are able to be used. They're normally recycled.
     * @param direction The direction of the hold cover.
     * @param noteStyle The note style of the hold cover.
     */
    public function new(direction:Int, noteStyle:NoteStyle)
    {
        super();

        this.noteStyle = noteStyle;
        this.direction = direction;

        this.animation.onFinish.add(onAnimationFinish);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        copyStrum();
    }

    /**
     * Sets up the hold cover based on a note style.
     * @param style The note style to apply to this hold cover.
     */
    public function setupHoldCoverSprite(style:NoteStyle)
    {
        style.applyStyleToHoldCover(this);
    }
    
    /**
     * Called when an animation for this hold cover is finished.
     * @param anim The animation that was finished.
     */
    function onAnimationFinish(anim:String)
    {
        switch (anim)
        {
            case 'start':
                playLoop();
            case 'end':
                isFinished = true;
                hide();
        }
    }

	/**
	 * Copies this hold cover's properties to it's associated strum, if it exists.
	 */
	public function copyStrum()
	{
        this.angle = strum.angle;
        this.alpha = strum.alpha;

		this.x = strum.x + (strum.width - this.width) / 2;
		this.y = strum.y + (strum.height - this.height) / 2;
	}

    /**
     * Plays a hold cover animation. Adjusts the offsets according to the animation played.
     * @param anim The animation to play.
     * @param force Whether to wait for the current animation to finish, or not.
     */
    function playAnimation(anim:String, force:Bool)
    {
        this.animation.play(anim, force);

        this.visible = true;

        updateHitbox();
        centerOffsets();
        centerOrigin();
		
        if (strum != null)
		{
			this.x = strum.x + (strum.width - this.width) / 2;
			this.y = strum.y + (strum.height - this.height) / 2;
		}
    }

    /**
     * Plays the 'start' animation for a hold cover.
     * If this animation doesn't exist, it plays the loop animation instead.
     */
    public function playStart()
    {
        if (hasStartAnimation())
        {
            playAnimation('start', true);
        }
        else
        {
            playLoop();
        }
    }

    /**
     * Plays the looping animation for this hold cover.
     */
    public function playLoop()
    {
        playAnimation('loop', true);
    }

    /**
     * Plays the ending animation for this hold cover.
     * If an animation doesn't exist, the cover is killed.
     * Else, after this is finished, then it's killed.
     */
    public function playEnd()
    {
        if (hasEndAnimation())
        {
            playAnimation('end', true);
        }
        else
        {
            hide();
        }
    }
    
    /**
     * Checks whether the hold cover for this note style has an start animation.
     * @return `Bool`
     */
    public function hasStartAnimation():Bool
    {
        return animation.exists('start');
    }

    /**
     * Checks whether the hold cover for this note style has an end animation.
     * @return `Bool`
     */
    public function hasEndAnimation():Bool
    {
        return animation.exists('end');
    }

    /**
     * Hides the cover.
     * This kills the cover allowing for it to be recycled for performance.
     */
    public function hide()
    {
        this.visible = false;
        this.kill();

        onKill.dispatch(this);
    }
}