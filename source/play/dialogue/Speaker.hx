package play.dialogue;

import audio.GameSound;
import audio.SoundController;
import data.IRegistryEntry;
import data.animation.Animation;
import data.dialogue.SpeakerData;
import data.dialogue.SpeakerRegistry;
import flixel.sound.FlxSound;
import scripting.IScriptedClass.IDialogueScriptedClass;
import scripting.events.ScriptEvent;
import util.FlxZSprite;

class Speaker extends FlxZSprite implements IDialogueScriptedClass implements IRegistryEntry<SpeakerData>
{
    public final id:String;
    var _data:SpeakerData;

    public var dialogueSounds:Array<FlxSound> = [];
    public var globalOffsets:Array<Float> = [0, 0];

    function get_speakerName():String return _data?.name ?? "Unknown Speaker";
    function get_globalOffsets():Array<Float> return _data?.globalOffsets ?? globalOffsets;
    function get_expressions():Array<SpeakerExpressionData> return _data?.expressions ?? [];

    public function new(id:String)
    {
        super();
        this.id = id;
        _data = fetchData(id);
    }

    public function onCreate(event:ScriptEvent):Void
    {
        if (dialogueSounds.length == 0 && _data.sounds != null)
            populateDialogueSounds();
    }

    override function kill():Void
    {
        clearDialogueSounds();
        super.kill();
    }

    public function onDestroy(event:ScriptEvent):Void
    {
        clearDialogueSounds();
    }

    public function populateDialogueSounds():Void
    {
        for (snd in _data.sounds)
        {
            var s = constructDialogueSound(snd);
            dialogueSounds.push(s);
        }
    }

    public function clearDialogueSounds():Void
    {
        for (sound in dialogueSounds)
        {
            if (sound != null)
            {
                SoundController.remove(sound);
                sound.stop();
            }
        }
        dialogueSounds = [];
    }

    function constructDialogueSound(path:String):GameSound
    {
        var s:GameSound = SoundController.load(Paths.sound(path));
        s.volume = 0.8;
        return s;
    }

    function getExpressionData(name:String):SpeakerExpressionData
    {
        for (expr in expressions)
            if (expr.name == name)
                return expr;

        return null;
    }

    public function hasExpression(name:String)
        return getExpressionData(name) != null;

    public function switchToExpression(expressionId:String):Void
    {
        var expression = getExpressionData(expressionId);
        if (expression == null) return;

        var path = expression.assetPath;

        if (expression.animation != null)
        {
            this.frames = Paths.getSparrowAtlas('ui/dialogue/portraits/$path');
            Animation.addToSprite(this, expression.animation);
            this.animation.play(expression.animation.name, true);
        }
        else
            loadGraphic(Paths.image('ui/dialogue/portraits/$path'));

        this.scale.set(expression.scale, expression.scale);
        this.antialiasing = expression.antialiasing;
        this.updateHitbox();

        this.x += expression.offsets[0];
        this.y += expression.offsets[1];

        if (expression.animation != null)
        {
            this.offset.x += expression.animation.offsets[0];
            this.offset.y += expression.animation.offsets[1];
        }
    }

    public function fetchData(id:String):SpeakerData
        return SpeakerRegistry.instance.parseEntryDataWithMigration(id);

    public function onUpdate(event:UpdateScriptEvent):Void {}
    public function onScriptEvent(event:ScriptEvent):Void {}
    public function onScriptEventPost(event:ScriptEvent):Void {}
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}
    public function onDialogueStart(event:DialogueScriptEvent):Void {}
    public function onDialogueLine(event:DialogueScriptEvent):Void {}
    public function onDialogueLineComplete(event:DialogueScriptEvent):Void {}
    public function onDialogueEnd(event:DialogueScriptEvent):Void {}
    public function onDialogueSkip(event:DialogueScriptEvent):Void {}
}
