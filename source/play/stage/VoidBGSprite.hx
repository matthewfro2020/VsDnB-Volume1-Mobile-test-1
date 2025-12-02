package play.stage;

import data.animation.Animation;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxGraphicAsset;
import graphics.shaders.RuntimeShader;

/**
 * Parameters for initalizing VoidSprite shader.
 */
typedef VoidParams =
{
	/**
	 * The speed at which the shader should go.
	 */
	var ?speed:Float;
	
	/**
	 * The frequency of the shader.
	 */
	var ?frequency:Float;

	/**
	 * The amplitude of the shader.
	 */
	var ?amplitude:Float;
}

/**
 * A BGSprite that uses a void shader.
 * Normally used for 3D-related songs.
 */
class VoidBGSprite extends BGSprite
{
	/**
	 * The shader this sprite uses for the void effect.
	 */
	public var glitchShader(default, null):RuntimeShader;

	public function new(?name:String, ?x:Float, ?y:Float, ?graphic:FlxGraphicAsset, ?animations:Array<AnimationData>, ?params:VoidParams)
	{
		super(name, x, y, graphic, animations);

		params = validateParams(params);

		#if (SHADERS_ENABLED || mac)
		glitchShader = new RuntimeShader(Paths.frag('glitchEffect'));
		glitchShader.setFloat('uWaveAmplitude', params.amplitude);
		glitchShader.setFloat('uFrequency', params.frequency);
		glitchShader.setFloat('uSpeed', params.speed);
		glitchShader.setFloat('uAlpha', 1);
		glitchShader.setBool('enableAlpha', true);
		glitchShader.setFloat('uTime', 0);

		shader = glitchShader ?? null;
		#end
		active = true;
		antialiasing = false;
	}

	override function update(elapsed:Float)
	{
		glitchShader?.setFloat('uTime', glitchShader?.getFloat('uTime') + elapsed);
		super.update(elapsed);
	}

	/**
	 * Validates the given parameters so they're able to be used.
	 * @param params The parameters to validate.
	 * @return A new VoidParams.
	 */
	function validateParams(params:VoidParams):VoidParams
	{
		if (params == null)
			params = {speed: 2, frequency: 5, amplitude: 0.1};
		if (params.speed == null)
			params.speed = 2;
		if (params.frequency == null)
			params.frequency = 5;
		if (params.amplitude == null)
			params.amplitude = 0.1;

		return params;
	}

	override function set_alpha(value:Float):Float
	{
		glitchShader?.setFloat('uAlpha', FlxMath.bound(value, 0, 1));
		return super.set_alpha(value);
	}
}
