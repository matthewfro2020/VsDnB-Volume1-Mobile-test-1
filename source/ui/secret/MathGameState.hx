package ui.secret;

import audio.GameSound;
import audio.SoundGroup;
import backend.Conductor;
import data.language.LanguageManager;
import data.song.SongRegistry;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.util.FlxColor;
import openfl.text.AntiAliasType;
import play.PlayState;
import play.PlayStatePlaylist;
import play.save.Preferences;
import play.song.Song;
import ui.Cursor;
import ui.menu.freeplay.FreeplayState;
import util.PlatformUtil;

typedef QueuedSound = 
{
	var sound:FlxSoundAsset;
	var ?soundType:SoundType;
}

enum abstract Operation(String) from String to String
{
	var ADDITION = 'Plus';
	var SUBTRACTION = 'Minus';
}
class MathGameState extends MusicBeatState
{
	/**
	 * Whether the user has failed the game, and needs to return back to the state.
	 */
	public static var failedGame:Bool = false;

	/**
	 * A list of all the available operations the player can get for a problem.
	 */
	final operationsList:Array<Operation> = [ADDITION, SUBTRACTION];

	/**
	 * A list of hint texts that display whenever a player gets a problem wrong.
	 */
	final wrongHintTexts:Array<String> = [LanguageManager.getTextString('math_wrongHintText_1'), LanguageManager.getTextString('math_wrongHintText_2')];

	/**
	 * A list of hint texts that display whenever a player gets a problem wrong.
	 */
	final correctHintTexts:Array<String> = [LanguageManager.getTextString('math_correctHintText_1')];

	// AUDIO //

	/**
	 * The group that holds all of the learn music, and it's stems.
	 */
	var learnMusicGroup:SoundGroup;

	/**
	 * The base of the learn music, plays when the player's on problem 1.
	 */
	var baseLearnMusic:GameSound;
	
	/**
	 * The first stem of the learn music that plays when the player's on problem 2.
	 */
	var learnMusic2:GameSound;
	
	/**
	 * The second stem of the learn music that plays when the player's on problem 3.
	 */
	var learnMusic3:GameSound;

	/**
	 * A list of sounds currently in the queue that have yet to be played.
	 */
	var queuedSoundList:Array<QueuedSound> = [];

	/**
	 * The current sound playing from the queue.
	 */
	var queuedSound:GameSound = new GameSound();


	// RENDER OBJECTS //

	/**
	 * The group that holds the players resulting for each question.
	 */
	var resultsGroup:FlxSpriteGroup;

	/**
	 * The baldi display shown on the YCTP.
	 */
	var baldi:YCTPBaldi;

	/**
	 * The text that displays information about the current problem.
	 */
	var infoText:FlxText;

	/**
	 * The text that displays information about the current problem's equation.
	 */
	var equationText:FlxText;

	/**
	 * The text that displays the user's current input.
	 * 
	 */
	var inputText:FlxText;

	/**
	 * The current problem the player's on,
	 */
	var problem:Int = 0;

	/**
	 * The answer the player needs to get this right.
	 * Generated when the problem is generated.
	 */
	var problemAnswer:Int = 0;

	/**
	 * Whether the YCTP game has ended, and we are to go back.
	 */
	var isEndingGame:Bool = false;
	
	/**
	 * The delay until the player goes back to normal gameplay, after completing the YCTP.
	 */
	var endDelay:Float = 2;


	public override function create()
	{
		super.create();

		SoundController?.music?.stop();

		// This state is meant to be purely aliased.
		FlxSprite.defaultAntialiasing = false;

		FlxG.signals.preStateSwitch.addOnce(() ->
		{
			// Make sure the game runs on antialiasing again after moving from this state.
			FlxSprite.defaultAntialiasing = true;

			// Switch border information back.
			FlxG.stage.window.title = Main.applicationName;
			PlatformUtil.setDarkMode(FlxG.stage.window.title, Preferences.darkMode);

			// Reset cursor.
			Cursor.reset();
			Cursor.hide();
		});
		
		FlxG.stage.window.title = "Baldi's Basics Classic Remastered";

		// Set to light mode.
		PlatformUtil.setDarkMode(FlxG.stage.window.title, false);

		buildCursor();
		buildYCTP();
		buildMusic();
		playIntro();
		generateProblem();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.instance.update(learnMusicGroup.time);

		if (queuedSoundList.length > 0 && (queuedSound == null || !queuedSound.playing))
		{
			playQueue();
		} 
		
		if (queuedSoundList.length <= 0 && !queuedSound.playing && isEndingGame)
		{
			endDelay -= elapsed;
			if (endDelay <= 0)
			{
				isEndingGame = false;
				endGame();
			}
		}
	}

	function buildCursor():Void
	{
		Cursor.load({graphic: Paths.image('backgrounds/math/CursorSprite'), scale: 0.5});
		Cursor.show();
	}

	function buildBaldiDisplay():Void
	{
		baldi = new YCTPBaldi(344, 476);
		add(baldi);
		baldi.updateHitbox();
	}

	function buildYCTP():Void
	{
		var white:FlxSprite = new FlxSprite(317, 258).makeGraphic(1, 1, FlxColor.WHITE);
		white.setGraphicSize(541, 351);
		white.updateHitbox();
		add(white);

		resultsGroup = new FlxSpriteGroup();
		resultsGroup.scrollFactor.set();
		add(resultsGroup);

		buildBaldiDisplay();

		infoText = new FlxText(457, 260, 380, 'I HEAR MATH THAT BAD');
		infoText.setFormat(Paths.font('comic_normal.ttf'), 36, FlxColor.BLACK, FlxTextAlign.LEFT);
		infoText.textField.antiAliasType = AntiAliasType.ADVANCED;
		infoText.textField.sharpness = 400;
		add(infoText);
		
		equationText = new FlxText(457, 370, 380, '');
		equationText.setFormat(Paths.font('comic_normal.ttf'), 36, FlxColor.BLACK, FlxTextAlign.LEFT);
		equationText.textField.antiAliasType = AntiAliasType.ADVANCED;
		equationText.textField.sharpness = 400;
		add(equationText);
		
		var yctp = new YCTPSprite(160, 0, Paths.image('backgrounds/math/YCTP_Base'));
		add(yctp);

		buildButtons();

		inputText = new FlxText(540, 512, 260);
		inputText.setFormat(Paths.font('comic_normal.ttf'), 48, FlxColor.BLACK, FlxTextAlign.LEFT);
		inputText.textField.antiAliasType = AntiAliasType.ADVANCED;
		inputText.textField.sharpness = 400;
		add(inputText);
	}

	function buildButtons():Void
	{
		var xPositions:Array<Float> = [908, 972, 1036];
		var yPositions:Array<Float> = [248, 312, 376, 440];
		var buttons:Array<String> = [
			'7', '8', '9', 
			'4', '5', '6', 
			'1', '2', '3', 
			'clear', '0', 'minus'
		];

		for (index => buttonId in buttons)
		{
			var xPos:Float = xPositions[index % 3];
			var yPos:Float = yPositions[Math.floor(index / 3)];

			var buttonSprite:YCTPButton = new YCTPButton(xPos, yPos, buttonId);
			add(buttonSprite);
			
			buttonSprite.onClick = () -> switch (buttonId)
			{
				case 'clear': clearInputText();
				case 'minus':
					inputText.text += '-';
				default:
					inputText.text += buttonId;
			}
		}

		var okButton:YCTPButton = new YCTPButton(940, 504, 'ok');
		okButton.onClick = checkAnswer;
		add(okButton);
	}

	function buildMusic():Void
	{
		learnMusicGroup = new SoundGroup();

		baseLearnMusic = new GameSound(MUSIC).load(Paths.music('math/learn/learnNew_1'), true, true);

		learnMusic2 = new GameSound(MUSIC).load(Paths.music('math/learn/learnNew_2'), true, true);
		learnMusic2.volume = 0.0;

		learnMusic3 = new GameSound(MUSIC).load(Paths.music('math/learn/learnNew_3'), true, true);
		learnMusic3.volume = 0.0;

		for (sound in [baseLearnMusic, learnMusic2, learnMusic3])
		{
			SoundController.add(sound);
			learnMusicGroup.add(sound);
		}
		learnMusicGroup.time = 0.0;
		learnMusicGroup.play();
		
		Conductor.instance.loadMusicData('learn-music');

		queuedSound.soundType = VOICES;
		SoundController.add(queuedSound);
		baldi.talkAudio = queuedSound;
	}

	function playIntro():Void
	{
		queueAudio({sound: Paths.sound('math/intro/BAL_Math_Intro1')});
		queueAudio({sound: Paths.sound('math/intro/BAL_Math_Intro2')});
		queueAudio({sound: Paths.sound('math/intro/BAL_Math_Intro3')});
		
		queueAudio({sound: Paths.sound('math/yctp/BAL_YCTP_Intro1')});
		queueAudio({sound: Paths.sound('math/yctp/BAL_YCTP_Intro2')});
	}

	function queueAudio(sound:QueuedSound):Void
	{
		queuedSoundList.push(sound);
	}

	function clearQueue():Void
	{
		queuedSoundList = [];
		queuedSound.stop();
	}

	function playQueue():Void
	{
		if (queuedSoundList.length > 0)
			playNextQueueSound();
	}

	function playNextQueueSound():Void
	{
		var sound:QueuedSound = queuedSoundList.shift();
		var soundType:SoundType = sound.soundType ?? VOICES;

		queuedSound.soundType = soundType;
		queuedSound.load(sound.sound);
		queuedSound.play();
	}

	function generateProblem():Void
	{
		problem++;

		var operation:Operation = FlxG.random.getObject(operationsList);

		var num1:Int = FlxG.random.int(0, 9);
		var num2:Int = FlxG.random.int(0, 9);

		infoText.text = LanguageManager.getTextString('math_solveMath') + ' Q$problem\n';
		infoText.text += '\n';

		equationText.text = '$num1';
		equationText.text += switch (operation) {
			case ADDITION: '+';
			case SUBTRACTION: '-';
		}
		equationText.text += '$num2';
		equationText.text += '=';

		problemAnswer = switch (operation)
		{
			case ADDITION: num1 + num2;
			case SUBTRACTION: num1 - num2;
		}

		if (!failedGame)
		{
			queueAudio({sound: Paths.sound('math/problem/BAL_YCTP_Problem$problem')});

			queueAudio({sound: Paths.sound('math/number/BAL_Math_${num1}')});
			queueAudio({sound: Paths.sound('math/operations/BAL_Math_${operation}')});
			queueAudio({sound: Paths.sound('math/number/BAL_Math_${num2}')});
			queueAudio({sound: Paths.sound('math/operations/BAL_Math_Equals')});
		}
	}

	function clearInputText():Void
	{
		inputText.text = '';
	}

	function checkAnswer():Void
	{
		// Make sure the player can't check their answer if the game has ended.
		if (problem > 3 || isEndingGame)
			return;

		var playerAnswer:Null<Int> = Std.parseInt(inputText.text.trim());
		var isRight:Bool = playerAnswer != null && playerAnswer == problemAnswer;

		if (isRight)
		{
			problemRight();
		}
		else
		{
			problemWrong();
		}
		updateYCTPAnswer(problem, isRight);
		clearInputText();

		if (problem >= 3)
		{
			isEndingGame = true;
			showHintText();
		}
		else
		{
			generateProblem();
		}
	}

	function problemRight():Void
	{
		if (!failedGame)
		{
			clearQueue();
			baldiPraise();
			updateLearnMusic();
		}
	}

	function problemWrong():Void
	{
		clearQueue();
		if (!failedGame)
		{
			handleHangMusic();
			baldi.frown();

			failedGame = true;
		}
	}
	
	function baldiPraise():Void
	{
		queueAudio({sound: Paths.soundRandom('math/praise/BAL_Praise', 1, 6)});
	}

	function updateLearnMusic():Void
	{
		switch (problem)
		{
			case 1:
				learnMusic2.volume = 1.0;
			case 2:
				learnMusic3.volume = 1.0;
			default:
		}
	}

	function handleHangMusic():Void
	{
		var learnTimeBeat:Float = learnMusicGroup.time % Conductor.instance.crochet;

		// Completely stop the learn music from playing after the player gets a problem wrong.
		learnMusicGroup.pause();
		learnMusicGroup.stop();
		learnMusicGroup.volume = 0.0;

		// Play the given hang music based on the beat we're on (so it's synced with the instrument).
		var hangType:String = (Conductor.instance.curBeat % 2 == 0) ? 'mus_hang_1' :  'mus_hang_2';
		
		var hangAudio:GameSound = new GameSound(MUSIC).load(Paths.music('math/hang/${hangType}'));
		SoundController.add(hangAudio);
		hangAudio.play(true, learnTimeBeat);
		hangAudio.onComplete = () -> {
			SoundController.remove(hangAudio);
		}
	}

	function updateYCTPAnswer(problem:Int, correct:Bool)
	{
		var yPositions:Array<Float> = [260, 336, 412];
		var graphic:FlxGraphic = Paths.image('backgrounds/math/${correct ? 'Check' : 'X'}');

		var sprite:YCTPSprite = new YCTPSprite(352, yPositions[problem - 1], graphic);
		resultsGroup.add(sprite);
	}

	function showHintText():Void
	{
		var hintTexts:Array<String> = failedGame ? wrongHintTexts : correctHintTexts;
		var randomText:String = FlxG.random.getObject(hintTexts);

		infoText.text = randomText;
		equationText.text = '';
	}

	function endGame():Void
	{
		if (failedGame)
		{
			FlxG.switchState(() -> new PlayState({
				targetSong: PlayState.lastParams.targetSong,
				targetVariation: PlayState.lastParams.targetVariation
			}));
		}
		else
		{
			var roofsSong:Song = SongRegistry.instance.fetchEntry('roofs');
			PlayStatePlaylist.storyWeek = 7;

			FreeplayState.unlockSong('roofs');

			FlxG.switchState(() -> new PlayState({
				targetSong: roofsSong,
				targetVariation: PlayState.lastParams.targetVariation
			}));
		}
	}
}

class YCTPBaldi extends YCTPSprite
{
	/**
	 * The current sound that's being used to make Baldi talk.
	 */
	public var talkAudio:GameSound;

	/**
	 * Whether baldi is allowed to talk, or not.
	 */
	public var talking:Bool = true;

	public function new(?x:Float, ?y:Float)
	{
		super(x, y);
		
		frames = Paths.getSparrowAtlas('backgrounds/math/Baldi_MathGame_Sheet');
		animation.addByPrefix('talk', 'talk', 30, false);
		animation.addByPrefix('frown', 'frown0', 30, false);
		animation.play('talk', true);

		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (talking && talkAudio != null)
		{
			if (talkAudio.playing)
			{
				// TODO: See if it's possible to make the frames change based on the audio.
				animation.play('talk');
			}
			else
			{
				animation.play('talk', true, false, 0);
			}
		}
	}

	public function frown():Void
	{
		talking = false;
		talkAudio = null;
		animation.play('frown', true);
	}
}

class YCTPButton extends YCTPSprite
{
	/**
	 * The id of this button.
	 */
	final id:String;

	/**
	 * Function called when the user clicks on this button.
	 */
	public var onClick:Void->Void;

	/**
	 * The normal/idle graphic.
	 */
	var normalSprite:FlxGraphic;

	/**
	 * The press graphic used for this sprite, when it's being selected.
	 */
	var pressedSprite:FlxGraphic;

	public function new(?x:Float, ?y:Float, id:String)
	{
		this.id = id;

		normalSprite = Paths.image('backgrounds/math/buttons/btn_$id');
		pressedSprite = Paths.image('backgrounds/math/buttons/btn_${id}_pressed');

		super(x, y, normalSprite);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.overlaps(this))
		{
			switchGraphic(pressedSprite);
			if (FlxG.mouse.justPressed)
			{
				if (onClick != null)
					onClick();
			}
		}
		else 
		{
			switchGraphic(normalSprite);
		}
	}
	
	function switchGraphic(target:FlxGraphic)
	{
		if (this.graphic != target)
		{
			loadGraphic(target);
			updateHitbox();
		}
	}
}

/**
 * A sprite used for the YCTP.
 */
class YCTPSprite extends FlxSprite
{
	public function new(?x:Float, ?y:Float, ?graphic:FlxGraphicAsset)
	{
		super(x, y, graphic);

		// Every YCTP sprite in accordance to the game is scaled by 2.
		scale.set(2, 2);
		updateHitbox();

		scrollFactor.set();
	}
}