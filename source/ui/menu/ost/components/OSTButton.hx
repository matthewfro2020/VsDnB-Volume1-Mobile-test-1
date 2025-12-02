package ui.menu.ost.components;

import audio.SoundController;
import flixel.FlxG;
import data.animation.Animation;
import data.animation.Animation.AnimationData;
import flixel.FlxSprite;

typedef OSTButtonParams = 
{
    /**
     * The id of this button.
     */
    var id:String;

    /**
     * The animation data for when this button is still.
     */
    var idle:AnimationData;

    /**
     * The animation data for when this button is pressed.
     */
    var pressed:AnimationData;

    /**
     * The type of pressing that should be done with this button.
     */
    var pressType:ButtonPressType;

    /**
     * Used when the button isn't selected, and it's a toggle.
     */
    var ?toggleIdle:AnimationData;
    
    /**
     * Played when the button is currently selected/pressed, and it's a toggle.
     */
    var ?togglePressed:AnimationData;
    
    /**
     * The starting state that the button should be in.
     */
    var ?startingSelect:Bool;

    /**
     * Whether to immediately go to the starting selected animation.
     */
    var ?forceSelect:Bool;
}
enum ButtonPressType
{
    TOGGLE;
    SINGLE; 
}
class OSTButton extends FlxSprite
{
    /**
     * The id of this OST button.
     */
    public final id:String;

    /**
     * Used when the button isn't selected.
     */
    var idleAnimation:AnimationData;
    
    /**
     * Played when the button is currently selected/pressed.
     */
    var pressedAnimation:AnimationData;

    /**
     * Used when the button isn't selected, and it's a toggle.
     */
    var toggleIdle:AnimationData;
    
    /**
     * Played when the button is currently selected/pressed, and it's a toggle.
     */
    var togglePressed:AnimationData;

    /**
     * The type of press that this button is using.
     */
    var pressType:ButtonPressType;
    
    /**
     * Called when the user presses this button.
     */
    public var onPress:Void->Void;
    
    /**
     * Called when the user presses this button.
     */
    public var onTogglePress:Bool->Void;

    /**
     * Called when the user de-selects this button.
     */
    public var onDeselect:Void->Void;

    /**
     * Whether this button is currently selected, or not.
     */
    public var selected:Bool = false;

    /**
     * Whether this button is interactable, or not.
     */
    public var canInteract:Bool = true;
    
    /**
     * Is the button currently being pressed on by the user?
     */
    var isPressed:Bool;

    
    public function new(x:Float = 0, y:Float = 0, params:OSTButtonParams)
    {
        super(x, y);

        this.id = params.id;

        this.idleAnimation = params.idle;
        this.pressedAnimation = params.pressed;
        this.toggleIdle = params.toggleIdle;
        this.togglePressed = params.togglePressed;

        this.pressType = params.pressType;

        this.frames = Paths.getSparrowAtlas('ost/buttons/button_$id');
        
        Animation.addToSprite(this, idleAnimation);
        Animation.addToSprite(this, pressedAnimation);
        
        if (toggleIdle != null)
            Animation.addToSprite(this, toggleIdle);

        if (togglePressed != null)
            Animation.addToSprite(this, togglePressed);

        this.selected = params.startingSelect ?? false;
        playIdle(params.forceSelect);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (FlxG.mouse.overlaps(this) && canInteract)
        {
            if (FlxG.mouse.pressed && !isPressed)
            {
                SoundController.play(Paths.sound('ost/click'), 0.7);
                isPressed = true;

                playPress();
            }
        }
		if (canInteract && FlxG.mouse.justReleased && isPressed)
		{
			isPressed = false;
			switch (pressType)
			{
				case TOGGLE:
					this.selected = !selected;
					playIdle();

					if (onTogglePress != null)
						onTogglePress(this.selected);
				case SINGLE:
					playIdle();

					if (onPress != null)
						onPress();
			}
		}
    }

    function playPress(force:Bool = false):Void
    {
        switch (pressType)
        {
            case TOGGLE:
                this.animation.play(this.selected ? togglePressed.name : pressedAnimation.name, true);
            case SINGLE:
                this.animation.play(pressedAnimation.name, true);
        }
        if (force)
            this.animation.finish();
    }

    function playIdle(force:Bool = false):Void
    {
        switch (pressType)
        {
            case TOGGLE:
                this.animation.play(this.selected ? toggleIdle.name : idleAnimation.name, true);
            case SINGLE:
                this.animation.play(idleAnimation.name, true);
        }
        if (force)
            this.animation.finish();
    }
}