package ui.menu.settings.components;

import controls.PlayerSettings;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class Prompt extends FlxSpriteGroup
{
	var curSelected:Int = 0;

	var yes:FlxText;
	var no:FlxText;

	public var yesFunc:Void->Void;
	public var noFunc:Void->Void;

	var optionList:Array<FlxText> = [];

	var canAnswer:Bool = false;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		var cry = new FlxSprite();
		cry.frames = Paths.getSparrowAtlas('settings/daveCry');
		cry.animation.addByPrefix('idle', 'settings_davecry', 24);
		cry.animation.play('idle');
		add(cry);

		var questionText = new FlxText(cry.width + 10, 0, 0, 'Are you sure?', 30);
		questionText.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.BLACK, FlxTextAlign.LEFT);
		add(questionText);
		questionText.y = cry.y + (cry.height - questionText.textField.textHeight) / 2;

		yes = new FlxText(0, 0, 0, 'Yes', 24);
		yes.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.BLACK, FlxTextAlign.LEFT);
		add(yes);
		yes.setPosition(questionText.x
			+ questionText.textField.width
			+ 50,
			questionText.y
			+ (yes.textField.textHeight - questionText.textField.textHeight) / 2);

		no = new FlxText(0, 0, 0, 'No', 24);
		no.setFormat(Paths.font('comic_normal.ttf'), 24, FlxColor.BLACK, FlxTextAlign.LEFT);
		add(no);
		no.setPosition(yes.x + yes.textField.width + 25, questionText.y + (no.textField.textHeight - questionText.textField.textHeight) / 2);

		optionList = [yes, no];

		setOption(curSelected);

		canAnswer = true;
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!canAnswer)
			return;

		var leftP = PlayerSettings.controls.LEFT_P;
		var rightP = PlayerSettings.controls.RIGHT_P;
		var enter = PlayerSettings.controls.ACCEPT;

		if (leftP)
			changeSelection(-1);
		if (rightP)
			changeSelection(1);
		if (enter)
			selectOption();
	}

	function changeSelection(amount:Int)
	{
		curSelected += amount;
		if (curSelected > optionList.length - 1)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = optionList.length - 1;

		setOption(curSelected);
	}

	function setOption(selection:Int)
	{
		switch (selection)
		{
			case 0:
				yes.color = FlxColor.GREEN;
				no.color = FlxColor.BLACK;
			case 1:
				yes.color = FlxColor.BLACK;
				no.color = FlxColor.RED;
		}
	}

	function selectOption()
	{
		switch (curSelected)
		{
			case 0:
				yesFunc();
			case 1:
				noFunc();
		}
	}
}
