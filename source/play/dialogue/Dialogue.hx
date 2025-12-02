package play.dialogue;

import audio.GameSound;
import audio.SoundController;
import data.IRegistryEntry;
import data.dialogue.DialogueData;
import data.dialogue.DialogueRegistry;
import data.dialogue.SpeakerRegistry;
import data.language.LanguageManager;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.addons.text.FlxTypeText;
import flixel.sound.FlxSound;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;

import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;
import scripting.IScriptedClass.IDialogueScriptedClass;
import scripting.IScriptedClass.IEventDispatcher;

import util.SortUtil;
import util.TweenUtil;
import util.FlxZSprite;

enum DialogueState
{
    Opening;
    Typing;
    Idle;
    Ending;
}

class Dialogue extends FlxSpriteGroup implements IDialogueScriptedClass implements IRegistryEntry<DialogueData>
{
    public final id:String;
    var _data:DialogueData;

    final DEFAULT_DIALOGUE_SOUND:FlxSound = SoundController.load(Paths.sound('dialogue/pixelText'));

    var dialogueMusicPath:Null<String>;

    final boxOffsets:Map<String, FlxPoint> =
    [
        "normal" => FlxPoint.get(0, 0),
        "none" => FlxPoint.get(0, -51)
    ];

    var dialogueList(get, never):Array<DialogueEntryData>;
    inline function get_dialogueList():Array<DialogueEntryData>
        return _data?.dialogue ?? [];

    var state:DialogueState = Opening;

    var music:GameSound = null;

    var background:FlxZSprite;
    var dialogueBox:FlxZSprite;

    var dialogueText:FlxTypeText;
    var textHolder:FlxZSprite;

    var speaker:Speaker;
    var outroTween:FlxTween;

    public var onFinish:Void->Void;

    var currentDialogueLine:Int = 0;

    var currentDialogueEntry(get, never):DialogueEntryData;
    inline function get_currentDialogueEntry()
        return dialogueList[currentDialogueLine];

    var dialogueEntryCount(get, never):Int;
    inline function get_dialogueEntryCount():Int
        return dialogueList.length - 1;

    public var isDialogueEnding(get, never):Bool;
    inline function get_isDialogueEnding()
        return outroTween != null;

    public function new(id:String)
    {
        super();
        this.id = id;
        _data = fetchData(id);
    }

    public function onCreate(event:ScriptEvent):Void
    {
        currentDialogueLine = 0;
        dialogueMusicPath = _data.music;

        buildMusic();
        buildBackground();
        createDialogueBox();

        refresh();
    }

    public function onUpdate(event:UpdateScriptEvent):Void
    {
        switch (state)
        {
            case Typing:
                if (FlxG.keys.justPressed.ENTER)
                    advanceDialogue();

            case Idle:
                if (FlxG.keys.justPressed.ENTER)
                    advanceDialogue();

            default:
        }
    }

    public function onDestroy(event:ScriptEvent):Void
    {
        dispatchToChildren(event);

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
            outroTween = null;
        }

        if (music != null)
        {
            SoundController.remove(music);
            music.stop();
            music = null;
        }

        if (speaker != null)
            killSpeaker();

        if (dialogueBox != null)
        {
            FlxTween.cancelTweensOf(dialogueBox);
            dialogueBox.destroy();
            remove(dialogueBox);
            dialogueBox = null;
        }

        if (background != null)
        {
            FlxTween.cancelTweensOf(background);
            background.destroy();
            remove(background);
            background = null;
        }

        if (dialogueText != null)
        {
            dialogueText.destroy();
            dialogueText = null;
        }

        if (textHolder != null)
        {
            textHolder.destroy();
            remove(textHolder);
            textHolder = null;
        }

        this.clear();
    }

    override function kill():Void
    {
        super.kill();

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
            outroTween = null;
        }
    }

    public function refresh():Void
        sort(SortUtil.byZIndex);

    function buildMusic():Void
    {
        if (dialogueMusicPath != null)
        {
            music = new GameSound().load(Paths.music(dialogueMusicPath));
            music.looped = true;
            SoundController.add(music);

            startMusicFadeIn();
            music.play();
        }
    }

    function startMusicFadeIn():Void
    {
        if (_data.fadeInTime > 0)
        {
            music.volume = 0;
            FlxTween.tween(music, {volume: 0.8}, _data.fadeInTime);
        }
    }

    function fadeOutMusic():Void
    {
        if (music != null && _data.fadeOutTime > 0)
        {
            FlxTween.cancelTweensOf(music);
            FlxTween.tween(music, {volume: 0.0}, _data.fadeOutTime);
        }
    }

    function buildBackground():Void
    {
        background = new FlxZSprite().makeGraphic(1, 1, 0xFF8A9AF5);
        background.scale.set(FlxG.width * 2, FlxG.height * 2);
        background.scrollFactor.set();
        background.alpha = 0.0;
        background.zIndex = 0;
        add(background);
    }

    function createDialogueBox():Void
    {
        dialogueBox = new FlxZSprite(0, 325);
        dialogueBox.frames = Paths.getSparrowAtlas("ui/dialogue/speech_bubble_talking");
        dialogueBox.animation.addByPrefix("normal", "chatboxnorm", 24);
        dialogueBox.animation.addByPrefix("none", "chatboxnone", 24);
        dialogueBox.screenCenter(X);

        dialogueBox.alpha = 0;
        dialogueBox.zIndex = 20;

        add(dialogueBox);

        playBoxAnimation("none");

        buildText();
    }

    function buildText():Void
    {
        textHolder = new FlxZSprite();
        textHolder.zIndex = 30;
        add(textHolder);

        dialogueText = new FlxTypeText(140, 425, Std.int(FlxG.width * 0.8), "", 32);
        dialogueText.font = Paths.font("comic.ttf");
        dialogueText.color = 0xFF000000;
        dialogueText.antialiasing = true;
        dialogueText.completeCallback = onTypingComplete;

        textHolder.add(dialogueText);
    }

    function beginDialogue():Void
    {
        FlxTween.tween(dialogueBox, {alpha: 1}, 1, {
            onComplete: function(_) {
                state = Typing;
                updateDialogueToEntry();
            }
        });

        FlxTween.tween(background, {alpha: 0.7}, 4.0);
    }

    public function start():Void
        dispatchEvent(new DialogueScriptEvent(DIALOGUE_START, this, false));

    public function skipDialogue():Void
        dispatchEvent(new DialogueScriptEvent(DIALOGUE_SKIP, this, true));

    function advanceDialogue():Void
    {
        var event:DialogueScriptEvent = null;

        switch (state)
        {
            case Typing:
                event = new DialogueScriptEvent(DIALOGUE_LINE_COMPLETE, this, true);
            case Idle:
                event = new DialogueScriptEvent(DIALOGUE_LINE, this, true);
            case Ending:
                event = new DialogueScriptEvent(DIALOGUE_END, this, false);
            default:
        }

        if (event != null)
            dispatchEvent(event);
    }

    public function onDialogueStart(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        if (!event.eventCanceled)
            beginDialogue();
    }

    public function onDialogueLine(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);

        currentDialogueLine++;

        state = Typing;

        if (currentDialogueLine > dialogueEntryCount)
        {
            state = Ending;
            advanceDialogue();
        }
        else
            updateDialogueToEntry();
    }

    public function onDialogueLineComplete(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);
        if (!event.eventCanceled)
            dialogueText.skip();
    }

    public function onDialogueSkip(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);
        if (!event.eventCanceled)
            dispatchEvent(new DialogueScriptEvent(DIALOGUE_END, this, false));
    }

    public function onDialogueEnd(event:DialogueScriptEvent):Void
    {
        dispatchToChildren(event);
        playOutro();
    }

    public function onScriptEvent(event:ScriptEvent):Void
        dispatchToChildren(event);

    public function dispatchEvent(event:ScriptEvent):Void
    {
        var handler:IEventDispatcher = cast FlxG.state;
        if (handler != null) handler.dispatchEvent(event);
    }

    function dispatchToChildren(event:ScriptEvent):Void
    {
        if (speaker != null)
            ScriptEventDispatcher.callEvent(speaker, event);
    }

    function updateDialogueToEntry():Void
    {
        updateDialogueBox();
        updateSpeaker();
        updateDialogueText();

        if (currentDialogueEntry.modifier != null)
            applyModifier(currentDialogueEntry.modifier);
    }

    function updateDialogueBox():Void
    {
        var speakerId = currentDialogueEntry.speaker;
        var side = currentDialogueEntry.side;

        if (speakerId == "generic" || side == "middle")
            playBoxAnimation("none");
        else
        {
            playBoxAnimation("normal");
            dialogueBox.flipX = (side == "right");
        }
    }

    function updateSpeaker():Void
    {
        var speakerId = currentDialogueEntry.speaker;
        var expressionId = currentDialogueEntry.expression;
        var side = currentDialogueEntry.side;

        killSpeaker();

        speaker = cast SpeakerRegistry.instance.fetchEntry(speakerId), FlxZSprite;

        if (speaker == null || speakerId == "generic")
            return;

        speaker = cast speaker;
        speaker.revive();
        speaker.zIndex = 10;

        add(speaker);
        refresh();

        switch (side)
        {
            case "left":   speaker.setPosition(100, 100);
            case "middle": speaker.setPosition(dialogueBox.x + dialogueBox.width / 2, 100);
            case "right":  speaker.setPosition(800, 100);
        }

        if (expressionId != null)
            speaker.switchToExpression(expressionId);

        if (side == "middle")
            speaker.x -= speaker.width / 2;

        speaker.x += speaker.globalOffsets[0];
        speaker.y += speaker.globalOffsets[1];

        speaker.x += currentDialogueEntry?.offsets[0] ?? 0;
        speaker.y += currentDialogueEntry?.offsets[1] ?? 0;

        fadeInSpeaker(side);

        ScriptEventDispatcher.callEvent(speaker, new ScriptEvent(CREATE, false));
    }

    function killSpeaker():Void
    {
        if (speaker != null)
        {
            speaker.kill();
            remove(speaker);
            speaker = null;
        }
    }

    function fadeInSpeaker(side:String):Void
    {
        var push:Float =
            switch (side)
            {
                case "left": -100;
                case "right": 100;
                default: -50;
            };

        speaker.x += push;
        speaker.alpha = 0;

        FlxTween.cancelTweensOf(speaker);
        FlxTween.tween(speaker, {x: speaker.x - push, alpha: 1}, 0.2);
    }

    function updateDialogueText():Void
    {
        var typingSpeed = currentDialogueEntry.typeSpeed;
        var text = LanguageManager.getTextString(
            currentDialogueEntry.text,
            LanguageManager.currentDialogueList
        );

        var sounds = (speaker != null) ? speaker.dialogueSounds : [DEFAULT_DIALOGUE_SOUND];

        if (text == "")
        {
            dialogueText.resetText(text);
            onTypingComplete();
        }
        else
        {
            dialogueText.sounds = (sounds.length == 0) ? null : sounds;
            dialogueText.resetText(text);
            dialogueText.start(typingSpeed, true);
        }
    }

    function onTypingComplete():Void
        state = Idle;

    function applyModifier(modifier:String) {}

    function playBoxAnimation(anim:String):Void
    {
        dialogueBox.updateHitbox();
        dialogueBox.animation.play(anim, true);

        dialogueBox.offset.x += boxOffsets.get(anim)?.x ?? 0;
        dialogueBox.offset.y += boxOffsets.get(anim)?.y ?? 0;
    }

    public function playOutro():Void
    {
        if (isDialogueEnding)
            return;

        if (_data.fadeOutTime > 0)
        {
            TweenUtil.completeTweensOf(background);
            TweenUtil.completeTweensOf(dialogueBox);
            if (speaker != null)
                TweenUtil.completeTweensOf(speaker);

            fadeOutMusic();

            outroTween = FlxTween.tween(this, {alpha: 0}, _data.fadeOutTime, {
                onComplete: function(_) onOutroComplete()
            });
        }
        else
            onOutroComplete();
    }

    function onOutroComplete():Void
    {
        ScriptEventDispatcher.callEvent(this, new ScriptEvent(DESTROY, false));
        if (onFinish != null) onFinish();
    }

    public function fetchData(id:String):DialogueData
        return DialogueRegistry.instance.parseEntryDataWithMigration(id);

    public function onScriptEventPost(event:ScriptEvent):Void {}
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}
}
