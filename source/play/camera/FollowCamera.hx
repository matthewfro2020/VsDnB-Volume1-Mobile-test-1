package play.camera;

import flixel.FlxObject;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxTimer;
import graphics.GameCamera;
import util.TweenUtil;

/**
 * A world camera used for following to a specific position.
 */
class FollowCamera extends GameCamera
{
    /**
     * The invisible object used for the camera to follow.
     */
    public var camFollow(default, null):FlxObject = new FlxObject(0, 0, 1, 1);

    /**
     * The current system the camera is using to follow. This can be either:
     */
    public var followType(default, set):FollowType = FollowType.LERP;

    public function set_followType(value:FollowType):FollowType
    {
        this.followType = value;
        switch (followType)
        {
            case EASE:
                followLerp = 1;
            case LERP:
                followLerp = followLerpDuration;
            case INSTANT:
                followLerp = 1;
        }
        return followType = value;
    }

    /**
     * The current target position the camera's moving to.
     */
    public var followPoint:FlxPoint = FlxPoint.get();

    /**
     * Optional var in-case you want the camera to only go to a specific point.
     */
    public var overrideFollowPoint:Null<FlxPoint> = null;

    /**
     * Optional positions offsets that can be configured with the camera.
     */
    public var followPositionOffset:FlxPoint = FlxPoint.get();
    
    /**
     * The position offset used for when a note is hit. 
     */
    public var cameraNoteOffset:FlxPoint = FlxPoint.get();

    /**
     * Whether the camera should cease any movement.
     */
    public var lockTarget:Bool = false;


    // LERPING OPTIONS //

    /**
     * The follow style to use for the camera when the following type is `FollowType.LERP`.
     */
    public var followStyle:FlxCameraFollowStyle = LOCKON;

    /**
     * How long the lerp effect should last when the camera when the following type is `FollowType.LERP`.
     */
    public var followLerpDuration:Float = 0.05;


    // EASING OPTIONS //
    
    /**
     * The tween object used to move the camera to it's given position.
     * The `setFollow()` function must be used to trigger this.
     */
    public var followTween(default, null):FlxTween;

    /**
     * Optional parameters that can be given to specified for the camera's ease.
     * For example, you can use this if you want to change the easing for the tween, or if you want something to happen when the tween complets.
     */
    public var followEaseOptions:TweenOptions = {};
    
    /**
     * How long it should take for the camera to ease to it's given position.
     * Used for when the follow type is `FollowType.LERP`.
     */
    public var followEaseDuration:Float = 1.0;


    public function new(followType:FollowType = FollowType.LERP, ?x:Float, ?y:Float, ?width:Int, ?height:Int)
    {
        super(x, y, width, height);

        follow(camFollow, followStyle, followLerpDuration);
		focusOn(camFollow.getPosition());

        this.followType = followType;
    }

    public override function update(elapsed:Float)
    {
        switch (followType)
        {
            case INSTANT:
                // Disable note camera for instant camera movement as it's ugly.
                camFollow.setPosition(followPoint.x, followPoint.y);
            default:
                camFollow.setPosition(followPoint.x + cameraNoteOffset.x, followPoint.y + cameraNoteOffset.y);
        }
        super.update(elapsed);
    }

    /**
     * Immediately brings the camera to it's given target.
     */
    public override function snapToTarget():Void
    {
        switch (followType)
		{
            case LERP:
                var lastLerp:Float = followLerp;
                
                // Set the lerp to 1 so the camera instantly goes to the necessary position.
                followLerp = 1;
                camFollow.setPosition(followPoint.x, followPoint.y);
                focusOn(camFollow.getPosition());

                // Reset the lerp back.
                followLerp = lastLerp;
                
                super.snapToTarget();
			case EASE:
				TweenUtil.completeTweensOf(this);
			case INSTANT:
				// Camera automatically snaps to the position so nothing needs to be done.
		}
    }

    /**
     * Sets the camera target destination to a given position.
     * @param x The x position the camera should go to.
     * @param y The y position the camera should go to.
     */
    public function setFollow(x:Float, y:Float):Void
    {
        if (lockTarget)
            return;

        if (overrideFollowPoint != null)
        {
            x = overrideFollowPoint.x;
            y = overrideFollowPoint.y;
        }

        switch (followType)
        {
            case EASE:
                // Clear the tween.
                followTween?.cancel();
                followTween = null;

                followTween = FlxTween.tween(followPoint, {x: x, y: y}, followEaseDuration, followEaseOptions);
            default:
                followPoint.set(x, y);
        }
    }
    
    /**
     * Snaps the camera to a given position.
     * @param x The x position the camera should snap to.
     * @param y The y position the camera should go to.
     */
    public function snapToPosition(x:Float, y:Float):Void
    {
        if (target == null)
            setTarget();
        
        setFollow(x, y);
        snapToTarget();
    }
    
    /**
     * Removes the camFollow object from this camera.
     */
    function removeTarget():Void
    {
        target = null;
    }

    /**
     * Sets the target to the `camFollow` object in this camera.
     */
    function setTarget():Void
    {
        target = camFollow;
    }
}

enum FollowType
{
    /**
     * The default following system that interpolates betweens the current position of the camera to the target position until it's reached.
     */
    EASE;

    /**
     * Tweens the camera to the given position. Can be used for custom transitions if the easing is changed, and further things can be modified via `followEaseOptions`.
     */
    LERP;

    /**
     * Immediately brings the camera to the given position. Usually isn't used, best to be used for mostly events.
     */
    INSTANT;
}