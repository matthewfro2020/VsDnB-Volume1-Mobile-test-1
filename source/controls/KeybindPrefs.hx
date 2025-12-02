package controls;

import controls.Controls.KeyboardScheme;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

class KeybindPrefs
{
	public static var keybinds:Map<String, Array<FlxKey>> = new Map<String, Array<FlxKey>>();

	public static var defaultKeybinds:Map<String, Array<FlxKey>> = [
		'left' => [A, LEFT],
		'down' => [S, DOWN],
		'up' => [W, UP],
		'right' => [D, RIGHT],
		'accept' => [SPACE, ENTER],
		'key5' => [SPACE, SHIFT],
		'back' => [BACKSPACE, ESCAPE],
		'pause' => [ENTER, ESCAPE],
		'reset' => [R, DELETE]
	];
	public static var controlNames:Array<String> = ['left', 'down', 'up', 'right', 'key5', 'accept', 'back', 'pause', 'reset'];

	public static function saveControls()
	{
		var controlsSave:FlxSave = new FlxSave();
		controlsSave.bind('controls', 'dnbteam');
		controlsSave.data.keybinds = keybinds;
		controlsSave.flush();
	}

	public static function loadControls()
	{
		var controlsSave:FlxSave = new FlxSave();
		controlsSave.bind('controls', 'dnbteam');
		if (controlsSave != null)
		{
			keybinds = controlsSave?.data?.keybinds ?? new Map<String, Array<FlxKey>>();
			for (control => keys in defaultKeybinds)
			{
				if (!keybinds.exists(control))
					keybinds.set(control, keys);
			}
			setKeybinds(keybinds);
		}
		else
		{
			keybinds = defaultKeybinds.copy();
			saveControls();
		}
	}

	public static function setKeybindsForControl(control:String, keys:Array<FlxKey>)
	{
		keybinds[control] = keys;
		saveControls();

		PlayerSettings.controls.setKeyboardScheme(Custom);
	}

	public static function setKeybinds(customControls:Map<String, Array<FlxKey>>)
	{
		for (controlName => key in customControls)
			setKeybindsForControl(controlName, key);

		PlayerSettings.controls.setKeyboardScheme(Custom);
	}

	public static function setKeybindPreset(scheme:KeyboardScheme)
	{
		PlayerSettings.controls.setKeyboardScheme(scheme);

		for (control in controlNames)
		{
			keybinds.set(control, PlayerSettings.controls.getInputsFor(Controls.stringControlToControl(control), Controls.Device.Keys));
		}
		KeybindPrefs.saveControls();
	}
}
