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

    final DEFAULT_DIALOGUE_SOUND:FlxSound =
        SoundController.load(Paths.sound('dialogue/pixelText'));

    var dialogueMusicPath:Null<String>;

    final boxOffsets:Map<String, FlxPoint> =
    [
        "normal" => FlxPoint.get(0, 0),
        "none"   => FlxPoint.get(0, -51)
    ];

    var dialogueList(get, never):Array<DialogueEntryData>;
    inline function get_dialogueList()
        return _data?.dialogue ?? [];

    var state:DialogueState = Opening;

    var music:GameSound = null;

    // ALL UI ELEMENTS MUST BE FlxZSprite
    var background:FlxZSprite;
    var dialogueBox:FlxZSprite;
    var textHolder:FlxZSprite;
    var textWrapper:FlxZSprite;

    var dialogueText:FlxTypeText;
    var speaker:Speaker;
    var outroTween:FlxTween;

    public var onFinish:Void->Void;
    var currentDialogueLine:Int = 0;

    var currentDialogueEntry(get, never):DialogueEntryData;
    inline function get_currentDialogueEntry()
        return dialogueList[currentDialogueLine];

    var dialogueEntryCount(get, never):Int;
    inline function get_dialogueEntryCount()
        return dialogueList.length - 1;

    public var isDialogueEnding(get, never):Bool;
    inline function get_isDialogueEnding()
        return outroTween != null;

    // -------------------------
    //  Constructor
    // -------------------------
    public function new(id:String)
    {
        super();
        this.id = id;
        _data = fetchData(id);
    }

    // -------------------------
    //  CREATE
    // -------------------------
    public function onCreate(event:ScriptEvent):Void
    {
        currentDialogueLine = 0;
        dialogueMusicPath = _data.music;

        buildMusic();
        buildBackground();
        buildDialogueBox();
        buildText();

        refresh();
    }

    // -------------------------
    //  UPDATE
    // -------------------------
    public function onUpdate(event:UpdateScriptEvent):Void
    {
        if (state == Typing && FlxG.keys.justPressed.ENTER)
            advanceDialogue();

        if (state == Idle && FlxG.keys.justPressed.ENTER)
            advanceDialogue();
    }

    // -------------------------
    //  DESTROY
    // -------------------------
    public function onDestroy(event:ScriptEvent):Void
    {
        dispatchToChildren(event);

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
            outroTween = null;
        }

        // Clean UI
        for (obj in [background, dialogueBox, textHolder, textWrapper])
        {
            if (obj != null)
            {
                remove(obj);
                obj.destroy();
            }
        }

        if (dialogueText != null)
            dialogueText.destroy();

        // Speaker
        if (speaker != null)
            killSpeaker();

        clear();
    }

    override function kill():Void
    {
        super.kill();

        if (outroTween != null)
        {
            outroTween.cancel();
            outroTween.destroy();
        }
    }

    public function refresh():Void
        sort(SortUtil.byZIndex);

    // -------------------------
    //  MUSIC
    // -------------------------
    function buildMusic():Void
    {
        if (dialogueMusicPath == null) return;

        music = new GameSound().load(Paths.music(dialogueMusicPath));
        music.looped = true;
        SoundController.add(music);

        if (_data.fadeInTime > 0)
        {
            music.volume = 0;
            FlxTween.tween(music, {volume: 0.8}, _data.fadeInTime);
        }

        music.play();
    }

    // -------------------------
    //  BACKGROUND
    // -------------------------
    function buildBackground():Void
    {
        background = new FlxZSprite().makeGraphic(1, 1, 0xFF8A9AF5);
        background.scale.set(FlxG.width * 2, FlxG.height * 2);
        background.scrollFactor.set();
        background.alpha = 0;
        background.zIndex = 0;
        add(background);
    }

    // -------------------------
    //  DIALOGUE BOX
    // -------------------------
    function buildDialogueBox():Void
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
    }

    // -------------------------
    //  TEXT
    // -------------------------
    function buildText():Void
    {
        textHolder = new FlxZSprite();
        textHolder.zIndex = 30;
        add(textHolder);

        textWrapper = new FlxZSprite();
        textWrapper.zIndex = 31;

        textHolder.add(textWrapper);

        dialogueText = new FlxTypeText(140, 425, Std.int(FlxG.width * 0.8), "", 32);
        dialogueText.font = Paths.font("comic.ttf");
        dialogueText.color = 0xFF000000;
        dialogueText.antialiasing = true;
        dialogueText.completeCallback = onTypingComplete;

        textWrapper.add(dialogueText);
    }

    // -------------------------
    //  BEGIN DIALOGUE
    // -------------------------
    function beginDialogue():Void
    {
        FlxTween.tween(dialogueBox, {alpha: 1}, 1, {
            onComplete: function(_) {
                state = Typing;
                updateDialogueToEntry();
            }
        });

        FlxTween.tween(background, {alpha: 0.7}, 4);
    }

    // -------------------------
    //  ADVANCE DIALOGUE
    // -------------------------
    function advanceDialogue():Void
    {
        var event:DialogueScriptEvent = switch (state)
        {
            case Typing: new DialogueScriptEvent(DIALOGUE_LINE_COMPLETE, this, true);
            case Idle:   new DialogueScriptEvent(DIALOGUE_LINE, this, true);
            case Ending: new DialogueScriptEvent(DIALOGUE_END, this, false);
            default:     null;
        };

        if (event != null)
            dispatchEvent(event);
    }

    // -------------------------
    //  SPEAKER HANDLING
    // -------------------------
    function updateSpeaker():Void
    {
        var speakerId = currentDialogueEntry.speaker;
        var expressionId = currentDialogueEntry.expression;
        var side = currentDialogueEntry.side;

        killSpeaker();

        var entry = SpeakerRegistry.instance.fetchEntry(speakerId);
        if (entry == null || speakerId == "generic") return;

        speaker = entry;
        speaker.revive();
        speaker.zIndex = 10;

        add(speaker);
        refresh();

        switch (side)
        {
            case "left": speaker.setPosition(100, 100);
            case "middle": speaker.setPosition(dialogueBox.x + dialogueBox.width / 2, 100);
            case "right": speaker.setPosition(800, 100);
        }

        if (expressionId != null)
            speaker.switchToExpression(expressionId);

        if (side == "middle")
            speaker.x -= speaker.width / 2;

        speaker.x += speaker.globalOffsets[0];
        speaker.y += speaker.globalOffsets[1];

        if (currentDialogueEntry.offsets != null)
        {
            speaker.x += currentDialogueEntry.offsets[0];
            speaker.y += currentDialogueEntry.offsets[1];
        }

        fadeInSpeaker(side);

        ScriptEventDispatcher.callEvent(speaker, new ScriptEvent(CREATE, false));
    }

    function killSpeaker():Void
    {
        if (speaker != null)
        {
            remove(speaker);
            speaker.kill();
            speaker = null;
        }
    }

    function fadeInSpeaker(side:String):Void
    {
        var push = switch (side)
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

    // -------------------------
    //  TEXT UPDATE
    // -------------------------
    function updateDialogueText():Void
    {
        var speed = currentDialogueEntry.typeSpeed;
        var text = LanguageManager.getTextString(currentDialogueEntry.text, LanguageManager.currentDialogueList);

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
            dialogueText.start(speed, true);
        }
    }

    function playBoxAnimation(anim:String):Void
    {
        dialogueBox.updateHitbox();
        dialogueBox.animation.play(anim, true);

        var off = boxOffsets.get(anim);
        if (off != null)
        {
            dialogueBox.offset.x += off.x;
            dialogueBox.offset.y += off.y;
        }
    }

    // -------------------------
    //  OUTRO
    // -------------------------
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

            FlxTween.tween(this, {alpha: 0}, _data.fadeOutTime, {
                onComplete: function(_) onOutroComplete()
            });
        }
        else
            onOutroComplete();
    }

    function onOutroComplete():Void
    {
        ScriptEventDispatcher.callEvent(this, new ScriptEvent(DESTROY, false));
        if (onFinish != null)
            onFinish();
    }

    // -------------------------
    //  REGISTRY
    // -------------------------
    public function fetchData(id:String):DialogueData
        return DialogueRegistry.instance.parseEntryDataWithMigration(id);

    public function onDialogueStart(e:DialogueScriptEvent):Void
    {
        dispatchToChildren(e);
        if (!e.eventCanceled)
            beginDialogue();
    }

    public function onDialogueLine(e:DialogueScriptEvent):Void
    {
        dispatchToChildren(e);

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

    public function onDialogueLineComplete(e:DialogueScriptEvent):Void
    {
        dispatchToChildren(e);
        if (!e.eventCanceled)
            dialogueText.skip();
    }

    public function onDialogueEnd(e:DialogueScriptEvent):Void
    {
        dispatchToChildren(e);
        playOutro();
    }

    public function onDialogueSkip(e:DialogueScriptEvent):Void
    {
        dispatchToChildren(e);
        if (!e.eventCanceled)
            dispatchEvent(new DialogueScriptEvent(DIALOGUE_END, this, false));
    }

    function dispatchToChildren(e:ScriptEvent):Void
    {
        if (speaker != null)
            ScriptEventDispatcher.callEvent(speaker, e);
    }

    public function onScriptEvent(e:ScriptEvent):Void {}

    public function onScriptEventPost(e:ScriptEvent):Void {}
    public function onPreferenceChanged(e:PreferenceScriptEvent):Void {}
}
