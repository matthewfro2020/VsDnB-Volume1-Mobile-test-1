package graphics.shaders;

import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

/*
  A shader that aims to *mostly recreate how Adobe Animate/Flash handles drop shadows, but its main use here is for rim lighting.

  Has options for color, angle, distance, and a threshold to not cast the shadow on parts like outlines.
  Can also be supplied a secondary mask which can then have an alternate threshold, for when sprites have too many conflicting colors
  for the drop shadow to look right (e.g. the tankmen on GF's speakers).

  Also has an Adjust Color shader in here so they can work together when needed.
 */
class DropShadowShader extends RuntimeShader
{
  /*
    The color of the drop shadow.
   */
  public var color(default, set):FlxColor;

  function set_color(col:FlxColor):FlxColor
  {
    color = col;
    setFloatArray("dropColor", [color.red / 255, color.green / 255, color.blue / 255]);
    return color;
  }

  /*
    The angle of the drop shadow.

    for reference, depending on the angle, the affected side will be:
    0 = RIGHT
    90 = UP
    180 = LEFT
    270 = DOWN
   */
  public var angle(default, set):Float;

  function set_angle(val:Float):Float
  {
    angle = val;
    setFloat("ang", angle * FlxAngle.TO_RAD);
    return angle;
  }

  /*
    The distance or size of the drop shadow, in pixels,
    relative to the texture itself... NOT the camera.
   */
  public var distance(default, set):Float;

  function set_distance(val:Float):Float
  {
    distance = val;
    setFloat("dist", val);
    return val;
  }

  /*
    The strength of the drop shadow.
    Effectively just an alpha multiplier.
   */
  public var strength(default, set):Float;

  function set_strength(val:Float):Float
  {
    strength = val;
    setFloat("str", val);
    return val;
  }
  
  /*
    The brightness threshold for the drop shadow.
    Anything below this number will NOT be affected by the drop shadow shader.
    A value of 0 effectively means theres no threshold, and vice versa.
   */
  public var threshold(default, set):Float;

  function set_threshold(val:Float):Float
  {
    threshold = val;
    setFloat("thr", val);
    return val;
  }

  /*
    The amount of antialias samples per-pixel,
    used to smooth out any hard edges the brightness thresholding creates.
    Defaults to 2, and 0 will remove any smoothing.
   */
  public var antialiasAmt(default, set):Float;

  function set_antialiasAmt(val:Float):Float
  {
    antialiasAmt = val;
    setFloat("AA_STAGES", val);
    return val;
  }

  /*
    Whether the shader should try and use the alternate mask.
    False by default.
   */
  public var useAltMask(default, set):Bool;

  function set_useAltMask(val:Bool):Bool
  {
    useAltMask = val;
    setBool("useMask", val);
    return val;
  }

  /*
    The image for the alternate mask.
    At the moment, it uses the blue channel to specify what is or isnt going to use the alternate threshold.
    (its kinda sloppy rn i need to make it work a little nicer)
    TODO: maybe have a sort of "threshold intensity texture" as well? where higher/lower values indicate threshold strength..
   */
  public var altMaskImage(default, set):BitmapData;

  function set_altMaskImage(_bitmapData:BitmapData):BitmapData
  {
    setSampler2D("altMask", _bitmapData);

    return _bitmapData;
  }

  /*
    An alternate brightness threshold for the drop shadow.
    Anything below this number will NOT be affected by the drop shadow shader,
    but ONLY when the pixel is within the mask.
   */
  public var maskThreshold(default, set):Float;

  function set_maskThreshold(val:Float):Float
  {
    maskThreshold = val;
    setFloat("thr2", val);
    return val;
  }

  /*
    The FlxSprite that the shader should get the frame data from.
    Needed to keep the drop shadow shader in the correct bounds and rotation.
   */
  public var attachedSprite(default, set):FlxSprite;

  function set_attachedSprite(spr:FlxSprite):FlxSprite
  {
    attachedSprite = spr;
    updateFrameInfo(attachedSprite.frame);
    return spr;
  }

  /*
    The hue component of the Adjust Color part of the shader.
   */
  public var baseHue(default, set):Float;

  function set_baseHue(val:Float):Float
  {
    baseHue = val;
    setFloat("hue", val);
    return val;
  }

  /*
    The saturation component of the Adjust Color part of the shader.
   */
  public var baseSaturation(default, set):Float;

  function set_baseSaturation(val:Float):Float
  {
    baseSaturation = val;
    setFloat("saturation", val);
    return val;
  }

  /*
    The brightness component of the Adjust Color part of the shader.
   */
  public var baseBrightness(default, set):Float;

  function set_baseBrightness(val:Float):Float
  {
    baseBrightness = val;
    setFloat("brightness", val);
    return val;
  }

  /*
    The contrast component of the Adjust Color part of the shader.
   */
  public var baseContrast(default, set):Float;

  function set_baseContrast(val:Float):Float
  {
    baseContrast = val;
    setFloat("contrast", val);
    return val;
  }

  /*
    Sets all 4 adjust color values.
   */
  public function setAdjustColor(b:Float, h:Float, c:Float, s:Float)
  {
    baseBrightness = b;
    baseHue = h;
    baseContrast = c;
    baseSaturation = s;
  }

  /*
    Loads an image for the mask.
    While you *could* directly set the value of the mask, this function works for both HTML5 and desktop targets.
   */
  public function loadAltMask(path:String)
  {
    #if html5
    BitmapData.loadFromFile(path).onComplete(function(bmp:BitmapData) {
      altMaskImage = bmp;
    });
    #else
    altMaskImage = BitmapData.fromFile(path);
    #end
  }

  /*
    Should be called on the animation.callback of the attached sprite.
    TODO: figure out why the reference to the attachedSprite breaks on web??
   */
  public function onAttachedFrame(name, frameNum, frameIndex)
  {
    if (attachedSprite != null) updateFrameInfo(attachedSprite.frame);
  }

  /*
    Updates the frame bounds and angle offset of the sprite for the shader.
   */
  public function updateFrameInfo(frame:FlxFrame)
  {
    // NOTE: uv.width is actually the right pos and uv.height is the bottom pos
    setFloatArray("uFrameBounds", [frame.uv.left, frame.uv.right, frame.uv.left + frame.uv.top, frame.uv.right + frame.uv.bottom]);

    // if a frame is rotated the shader will look completely wrong lol
    setFloat("angOffset", frame.angle * FlxAngle.TO_RAD);
  }

  
  public function new()
  {
    super(Paths.frag('dropShadow'));

    angle = 0;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    antialiasAmt = 2;

    useAltMask = false;

    setFloat("angOffset", 0);
  }
}