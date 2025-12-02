package graphics.shaders;

import flixel.addons.display.FlxRuntimeShader;
import openfl.utils.Assets;

/**
 * A shader that's generated at runtime instead of being complied.
 */
class RuntimeShader extends FlxRuntimeShader
{
	public function new(fragmentSource:String)
	{
		#if SHADERS_ENABLED
		var fragSource = Assets.getText(fragmentSource);
		#else
		var fragSource = '';
		#end
		super(fragSource);
	}
}
