package ui.menu.settings.components;

import data.language.LanguageManager;
import controls.Controls.Control;
import controls.Controls.KeyboardScheme;
import controls.KeybindPrefs;
import controls.PlayerSettings;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import ui.menu.settings.SettingsMenu;

enum SelectingState
{
	SelectingPreset;
	SelectingControl;
	SelectingKeybind;
	ChangeKeybind;
}


typedef ControlUI =
{
	var displayName:String;
	var controlName:String;
}

/**
 * A sub-menu in the settings menu used to help the user configure their in-game controls.
 * 
 * Allows the user to be able to manually select a control, and set their keybinds.
 * Or they can just select one of the given presets to choose.
 */
class ConfigureKeybinds extends FlxGroup
{
	/**
	 * A list of keys the user's unable to bind to prevent easy softlocks, and bugs.
	 */
	final KEYBIND_BLACKLIST = [FlxKey.ENTER, FlxKey.SPACE, FlxKey.BACKSPACE, FlxKey.ESCAPE];
	
	/**
	 * A list of all of the presets the user's allowed to switch to.
	 */
	final keybindPresets:Array<String> = ['arrowKeys', 'wasd', 'dfjk', 'askl', 'zx,.'];

	/**
	 * A constant list containing all data information for all of the configurable controls.
	 */
	final UI_CONTROLS:Array<ControlUI> = [
		{displayName: 'Left', controlName: 'left'},
		{displayName: 'Down', controlName: 'down'},
		{displayName: 'Up', controlName: 'up'},
		{displayName: 'Right', controlName: 'right'},
		{displayName: 'Accept', controlName: 'accept'},
		{displayName: 'Back', controlName: 'back'},
		{displayName: 'Reset', controlName: 'reset'},
		{displayName: 'Key5', controlName: 'key5'},
	];


	// GENERAL //

	/**
	 * The settings menu that this group belongs to.
	 */
	var parent:SettingsMenu;

	/**
	 * The current state of this menu.
	 * This can either be that the user is:
	 * 
	 * - Selecting a preset to choose from the list.
	 * - Selecting a control to change the keybinds of.
	 * - Selected a control, and is selecting a keybind to change.
	 * - Changing a keybind.  
	 */
	var curState(default, set):SelectingState;

	function set_curState(value:SelectingState):SelectingState
	{
		switch (value)
		{
			case SelectingPreset:
				for (i in [presetTextTitle, presetArrowLeft, presetText, presetArrowRight])
				{
					i.alpha = 1;
				}
				for (group in controlGroups)
				{
					group.available = false;
				}
			case SelectingControl:
				for (i in [presetTextTitle, presetArrowLeft, presetText, presetArrowRight])
				{
					i.alpha = 0.6;
				}
				for (group in controlGroups)
				{
					group.available = true;
				}
			case SelectingKeybind:
				for (group in controlGroups)
				{
					if (group != controlGroups[curControlIndex])
					{
						group.available = false;
					}
				}
			default:
		}
		return curState = value;
	}

	/**
	 * Whether the user can interact with this menu currently.
	 */
	var canInteract:Bool = true;

	// PRESETS // 

	/**
	 * The current preset that the user's selected, in terms of the index.
	 */
	var curPresetIndex:Int = 0;

	/**
	 * The left arrow used for the preset selection.
	 */
	var presetArrowLeft:FlxSprite;
	
	/**
	 * The right arrow used for the preset selection.
	 */
	var presetArrowRight:FlxSprite;

	/**
	 * The 'Select A Preset' text that shows above the preset sub-menu.
	 */
	var presetTextTitle:FlxText;

	/**
	 * The text that displays the current preset the user has selected.
	 */
	var presetText:FlxText;


	// CONTROLS //

	/**
	 * The current control that the user's selected, in terms of the index.
	 */
	var curControlIndex:Int = 0;

	/**
	 * A list of all of the control groups.
	 */
	var controlGroups:Array<ControlGroup> = [];

	/**
	 * The current control that's selected.
	 */
	var curControlGroup:ControlGroup;


	// KEYBINDS //

	/**
	 * The current keybind that the user's selected, in terms of the index.
	 */
	var curKeybindIndex:Int = 0;

	/**
	 * The current keybind that's selected.
	 */
	var curKeybind:FlxText;

	/**
	 * Initalizes a new KeybindsMenu for the user.
	 * @param parent The current settings menu.
	 */
	public function new(parent:SettingsMenu)
	{
		super();

		this.parent = parent;

		createPresetMenu();
		createKeybindsMenu();

		curState = SelectingPreset;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		var left = PlayerSettings.controls.LEFT;
		var leftP = PlayerSettings.controls.LEFT_P;

		var right = PlayerSettings.controls.RIGHT;
		var rightP = PlayerSettings.controls.RIGHT_P;

		var downP = PlayerSettings.controls.DOWN_P;
		var upP = PlayerSettings.controls.UP_P;
		var accept = PlayerSettings.controls.ACCEPT;
		var back = PlayerSettings.controls.BACK;

		if (!canInteract)
			return;

		if (back)
		{
			switch (curState)
			{
				case SelectingKeybind:
					curControlGroup.deselectKeybinds();
					changeControlSelection();

					curState = SelectingControl;
				case ChangeKeybind:
					// Do nothing.
				default:
					parent.closeKeybindsMenu();
			}
		}

		switch (curState)
		{
			case SelectingPreset:
				if (left || FlxG.mouse.overlaps(presetArrowLeft))
				{
					presetArrowLeft.scale.set(0.4, 0.4);
				}
				else
				{
					presetArrowLeft.scale.set(0.5, 0.5);
				}
				if (leftP || (FlxG.mouse.overlaps(presetArrowLeft) && FlxG.mouse.justPressed))
				{
					changePresetSelection(-1);
				}
				if (right || FlxG.mouse.overlaps(presetArrowRight))
				{
					presetArrowRight.scale.set(0.4, 0.4);
				}
				else
				{
					presetArrowRight.scale.set(0.5, 0.5);
				}
				if (rightP || (FlxG.mouse.overlaps(presetArrowRight) && FlxG.mouse.justPressed))
				{
					changePresetSelection(1);
				}

				if (downP)
				{
					curState = SelectingControl;
					changeControlSelection(0 - curControlIndex);
				}
				if (upP)
				{
					curState = SelectingControl;
					changeControlSelection((controlGroups.length - 1) - curControlIndex);
				}
				if (accept)
				{
					selectPreset(keybindPresets[curPresetIndex]);
				}
			case SelectingControl:
				if (downP)
				{
					if (curControlIndex == controlGroups.length - 1)
					{
						curState = SelectingPreset;
						controlGroups[curControlIndex].deselect();

						SoundController.play(Paths.sound('scrollMenu'), 0.7);
					}
					else
					{
						changeControlSelection(1);
					}
				}
				if (upP)
				{
					if (curControlIndex == 0)
					{
						curState = SelectingPreset;
						curControlGroup.deselect();

						SoundController.play(Paths.sound('scrollMenu'), 0.7);
					}
					else
					{
						changeControlSelection(-1);
					}
				}
				if (accept)
				{
					curControlGroup.deselect();
					changeKeybindSelection(0);
					curState = SelectingKeybind;
				}
			case SelectingKeybind:
				if (leftP)
				{
					changeKeybindSelection(-1);
				}
				if (rightP)
				{
					changeKeybindSelection(1);
				}
				if (accept)
				{
					curState = ChangeKeybind;
				}
			case ChangeKeybind:
				var keybindsForControl:Array<FlxKey> = KeybindPrefs.keybinds.get(curControlGroup.uiControl.controlName);
				var oldKeybindText:String = keybindsForControl[curKeybindIndex].toString();

				curKeybind.text = "_";
				curControlGroup.repositionText();

				var keyID:Int = FlxG.keys.firstJustPressed();
				var key = cast(keyID, FlxKey);

				// Called when the user selects an invalid keybind.
				function invalidKeybind()
				{
					changeControlSelection();
					curControlGroup.deselectKeybinds();

					curKeybind.text = oldKeybindText;
					curState = SelectingControl;
					
					FlxG.camera.shake(0.05, 0.1);
					SoundController.play(Paths.sound('missnote1'), 0.9);
				}

				if (keyID > -1)
				{
					if (!KEYBIND_BLACKLIST.contains(keyID))
					{
						var keyAlreadyBinded:Bool = false;

						for (i in 0...keybindsForControl.length)
						{
							// Don't check the keybind we're trying to bind already.
							if (i == curKeybindIndex)
								continue;

							// Key is already binded.
							if (keybindsForControl[i] == key)
								keyAlreadyBinded = true;
						}

						if (keyAlreadyBinded)
						{
							invalidKeybind();
						}
						else
						{
							keybindsForControl[curKeybindIndex] = key;
							KeybindPrefs.setKeybindsForControl(curControlGroup.uiControl.controlName, keybindsForControl);


							curKeybind.text = key.toString();
							curControlGroup.deselectKeybinds();
							curControlGroup.repositionText();

							changeControlSelection();
							
							curState = SelectingControl;
							SoundController.play(Paths.sound('confirmMenu'));
						}
					}
					else
					{
						invalidKeybind();
					}
				}
		}
	}

	function changeControlSelection(amount:Int = 0)
	{
		curControlIndex += amount;

		SoundController.play(Paths.sound('scrollMenu'), 0.7);

		if (curControlIndex < 0)
			curControlIndex = controlGroups.length - 1;

		if (curControlIndex > controlGroups.length - 1)
			curControlIndex = 0;

		selectControl();
	}

	function selectControl()
	{
		curControlGroup = controlGroups[curControlIndex];
		curControlGroup.select();
		for (i in 0...controlGroups.length)
		{
			if (i != curControlIndex)
			{
				controlGroups[i].deselect();
			}
		}
	}

	function createPresetMenu()
	{
		presetArrowLeft = createArrow();
		add(presetArrowLeft);

		presetArrowRight = createArrow();
		add(presetArrowRight);
		presetArrowRight.flipX = true;

		presetText = new FlxText(0, 200, 0, LanguageManager.getTextString('settings_keybinds_preset_${keybindPresets[0]}'));
		presetText.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.BLACK, FlxTextAlign.CENTER);
		add(presetText);

		presetTextTitle = new FlxText(0, 150, 0, LanguageManager.getTextString('settings_keybinds_preset_tutorial'));
		presetTextTitle.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.BLACK, FlxTextAlign.CENTER);
		presetTextTitle.screenCenter(X);
		add(presetTextTitle);

		updatePresetSelect();
	}

	function createKeybindsMenu()
	{
		for (i in 0...UI_CONTROLS.length)
		{
			var controlGroup = new ControlGroup(450, 275 + (50 * i), UI_CONTROLS[i]);
			add(controlGroup);
			controlGroups.push(controlGroup);
		}
	}
	
	function changeKeybindSelection(amount:Int = 0)
	{
		curKeybindIndex += amount;

		SoundController.play(Paths.sound('scrollMenu'), 0.7);

		if (curKeybindIndex < 0)
			curKeybindIndex = curControlGroup.keybindTextGroup.length - 1;
		if (curKeybindIndex > curControlGroup.keybindTextGroup.length - 1)
			curKeybindIndex = 0;

		selectKeybind();
	}

	function deselectKeybind()
	{
		for (i in 0...curControlGroup.keybindTextGroup.length)
		{
			if (i != curKeybindIndex)
			{
				curControlGroup.keybindTextGroup[i].scale.set(1, 1);
			}
			else
			{
				curControlGroup.keybindTextGroup[i].scale.set(1.2, 1.2);
			}
		}
	}
	
	function selectKeybind()
	{
		curKeybind = curControlGroup.keybindTextGroup[curKeybindIndex];
		curKeybind.scale.set(1.2, 1.2);

		for (i in 0...curControlGroup.keybindTextGroup.length)
		{
			if (i != curKeybindIndex)
			{
				curControlGroup.keybindTextGroup[i].scale.set(1, 1);
			}
		}
	}

	function changePresetSelection(amount:Int = 0)
	{
		curPresetIndex += amount;

		SoundController.play(Paths.sound('scrollMenu'), 0.7);

		if (curPresetIndex < 0)
			curPresetIndex = keybindPresets.length - 1;
		if (curPresetIndex > keybindPresets.length - 1)
			curPresetIndex = 0;

		updatePresetSelect();
	}

	function updatePresetSelect()
	{
		presetText.text = LanguageManager.getTextString('settings_keybinds_preset_${keybindPresets[curPresetIndex]}');
		presetText.screenCenter(X);

		presetArrowLeft.setPosition(presetText.x - presetArrowLeft.width - 10, presetText.y + (presetText.textField.textHeight - presetArrowLeft.height) / 2);
		presetArrowRight.setPosition(presetText.x
			+ presetText.textField.textWidth
			+ 10,
			presetText.y
			+ (presetText.textField.textHeight - presetArrowRight.height) / 2);
	}

	/**
	 * Selects a given preset, and changes the controls based on it.
	 * @param preset The preset to change to.
	 */
	function selectPreset(preset:String)
	{
		switch (preset)
		{
			case 'dfjk':
				KeybindPrefs.setKeybindPreset(KeyboardScheme.Solo);
			case 'askl':
				KeybindPrefs.setKeybindPreset(KeyboardScheme.Askl);
			case 'zx,.':
				KeybindPrefs.setKeybindPreset(KeyboardScheme.ZxCommaDot);
			default:
				KeybindPrefs.setKeybindPreset(KeyboardScheme.Duo);
		}
		SoundController.play(Paths.sound('confirmMenu'));

		canInteract = false;
		FlxFlicker.flicker(presetText, 1.1, 0.07, true, false, function(flicker:FlxFlicker)
		{
			for (i in controlGroups)
			{
				remove(i);
				i.destroy();
				i = null;
			}
			controlGroups = [];
			createKeybindsMenu();

			canInteract = true;
		});
	}

	function createArrow(x:Float = 0, y:Float = 0):FlxSprite
	{
		var arrow = new FlxSprite(x, y);
		arrow.frames = Paths.getSparrowAtlas('settings/arrow');
		arrow.animation.addByPrefix('idle', 'settings_arrow_static', 24);
		arrow.animation.play('idle', true);
		arrow.scale.set(0.5, 0.5);
		arrow.updateHitbox();
		return arrow;
	}
}

/**
 * Represents a control that the user's able to configure.
 * Contains all of the current keybinds.
 */
class ControlGroup extends FlxSpriteGroup
{
	/**
	 * Whether this control's able to be selected.
	 */
	public var available(default, set):Bool = true;

	function set_available(value:Bool):Bool
	{
		var targetAlpha = value ? 1 : 0.6;
		displayText.alpha = targetAlpha;
		for (i in keybindTextGroup)
		{
			i.alpha = targetAlpha;
		}
		return available = value;
	}

	public var uiControl:ControlUI;
	public var keybindTextGroup:Array<FlxText> = [];
	
	var displayText:FlxText;

	public function new(x:Float, y:Float, uiControl:ControlUI)
	{
		super(x, y);

		this.uiControl = uiControl;

		displayText = new FlxText(0, 0, 0, LanguageManager.getTextString('settings_keybinds_${uiControl.displayName}'));
		displayText.setFormat(Paths.font('comic_normal.ttf'), 30, FlxColor.BLACK, FlxTextAlign.LEFT);
		add(displayText);

		var controlKeybinds = KeybindPrefs.keybinds.get(uiControl.controlName);
		for (i in 0...controlKeybinds.length)
		{
			var lastKeybind = keybindTextGroup[i - 1];
			var xPos = lastKeybind != null ? ((lastKeybind.x - x) + lastKeybind.textField.textWidth + 50) : 200;

			var keybindText = new FlxText(xPos, 0, 0, controlKeybinds[i].toString());
			keybindText.setFormat(Paths.font('comic_normal.ttf'), 20, FlxColor.BLACK, FlxTextAlign.LEFT);
			add(keybindText);
			keybindText.y = displayText.y + (displayText.textField.textHeight - keybindText.textField.textHeight) / 2;
			keybindTextGroup.push(keybindText);
		}
	}

	public function repositionText():Void
	{
		for (i in 0...keybindTextGroup.length)
		{
			var lastKeybind = keybindTextGroup[i - 1];
			var xPos = lastKeybind != null ? ((lastKeybind.x - x) + lastKeybind.textField.textWidth + 50) : 200;

			keybindTextGroup[i].x = this.x + xPos;
		}
	}

	public function select()
	{
		displayText.scale.set(1.2, 1.2);
	}

	public function deselect()
	{
		displayText.scale.set(1.0, 1.0);
	}

	public function deselectKeybinds()
	{
		for (i in keybindTextGroup)
		{
			i.scale.set(1.0, 1.0);
		}
	}
}
