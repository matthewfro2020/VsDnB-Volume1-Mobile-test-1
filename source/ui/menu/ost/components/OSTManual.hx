package ui.menu.ost.components;

import data.language.LanguageManager;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;

enum ManualState
{
    START;
    UI;
    SELECTION_BAR;
    TURNTABLE;
}
class OSTManual extends FlxSpriteGroup
{
    /**
     * The current state the user is in through the manual.
     */
    private var state:ManualState = START;

    /**
     * Is the selection bar currently closed?
     * If so, skip the selection bar part of the manual.
     */
    public var selectionBarClosed:Bool = false;

    /**
     * Whether the user's allowed to keep advancing through the manual.
     */
    private var canAdvance:Bool = false;
    
    /**
     * Used to make sure there's no mouse input when the manual is opened.
     */
    var delayTimer:Float = 0.01;

    public var selectionBarManual:FlxSpriteGroup = new FlxSpriteGroup();
    public var turnTableManual:FlxSpriteGroup = new FlxSpriteGroup();
    public var uiManual:FlxSpriteGroup = new FlxSpriteGroup();

    public var onManualOpen:FlxSignal = new FlxSignal();
    public var onManualClose:FlxSignal = new FlxSignal();

    public function new()
    {
        super();

        var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
        bg.scale.set(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.alpha = 0.7;
        add(bg);

        buildSelectionBarManual();
        buildTurnTableManual();
        buildUIManual();

        advanceManual();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (delayTimer > 0)
            delayTimer -= elapsed;

        if (FlxG.mouse.justPressed && canAdvance && delayTimer <= 0)
        {
            advanceManual();
        }
    }

    public function startManual():Void
    {
        onManualOpen.dispatch();
        delayTimer = 0.1;

        state = START;
        advanceManual();
    }
    
    public function onSelectionBarToggle(value:Bool)
    {
        selectionBarClosed = !value;

        // Reposition the turntable tutorial since the turntable's centered now.
        turnTableManual.x = value ? 0 : -150;
    }

    function advanceManual():Void
    {
        uiManual.visible = false;
        selectionBarManual.visible = false;
        turnTableManual.visible = false;

        // Skip the selection bar tutorial because it's closed.
        if (selectionBarClosed && state == UI)
            state = SELECTION_BAR;

        switch (state)
        {
            case START:
                canAdvance = true;
                uiManual.visible = true;
                state = ManualState.UI;
            case UI:
                selectionBarManual.visible = true;
                state = ManualState.SELECTION_BAR;
            case SELECTION_BAR:
                turnTableManual.visible = true;
                state = ManualState.TURNTABLE;
            case TURNTABLE:
                canAdvance = false;
                onManualClose.dispatch();
        }
    }

    function buildSelectionBarManual():Void
    {
        add(selectionBarManual);

        var categoryInstruction = new OSTManualInstruction(313, 10, LanguageManager.getTextString('ost_manual_selectBarCategory'), 15, 'category_selection_line', FlxTextAlign.LEFT, 'center');
        selectionBarManual.add(categoryInstruction);

        var songInstruction = new OSTManualInstruction(295, 200, LanguageManager.getTextString('ost_manual_selectBarSong'), 15, 'song_selection_line', FlxTextAlign.LEFT, 'center');
        selectionBarManual.add(songInstruction);
    }

    function buildTurnTableManual():Void
    {
        // Reposition the turntable tutorial if the turntable's centered.
        turnTableManual.x = !selectionBarClosed ? 0 : -150;
        add(turnTableManual);

        var playButtonInstruction = new OSTManualInstruction(405, 116, LanguageManager.getTextString('ost_manual_playButton'), 15, 'play_button_line', FlxTextAlign.RIGHT, 'bottom');
        turnTableManual.add(playButtonInstruction);
        
        var pauseButtonInstruction = new OSTManualInstruction(395, 190, LanguageManager.getTextString('ost_manual_pauseButton'), 15, 'pause_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(pauseButtonInstruction);

        var speedButtonInstruction = new OSTManualInstruction(392, 268, LanguageManager.getTextString('ost_manual_speedButton'), 12, 'speed_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(speedButtonInstruction);
        
        var slowButtonInstruction = new OSTManualInstruction(389, 338, LanguageManager.getTextString('ost_manual_speedButton'), 12, 'slow_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(slowButtonInstruction);

        var timeMonitorInstruction = new OSTManualInstruction(406, 527, LanguageManager.getTextString('ost_manual_timeMonitor'), 12, 'time_monitor_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(timeMonitorInstruction);

        var vocalsButtonInstruction = new OSTManualInstruction(997, 124, LanguageManager.getTextString('ost_manual_vocals'), 15, 'vocals_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(vocalsButtonInstruction);
        
        var instButtonInstruction = new OSTManualInstruction(992, 204, LanguageManager.getTextString('ost_manual_inst'), 15, 'instrumental_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(instButtonInstruction);

        var remixButtonInstruction = new OSTManualInstruction(997, 263, LanguageManager.getTextString('ost_manual_remix'), 15, 'remix_mode_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(remixButtonInstruction);
        
        var manualButtonInstruction = new OSTManualInstruction(1011, 367, LanguageManager.getTextString('ost_manual_manualButton'), 15, 'manual_button_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(manualButtonInstruction);

        var audioMonitorInstruction = new OSTManualInstruction(951, 532, LanguageManager.getTextString('ost_manual_audio'), 15, 'audio_monitor_line', FlxTextAlign.RIGHT, 'center');
        turnTableManual.add(audioMonitorInstruction);
    }

    function buildUIManual():Void
    {
        add(uiManual);
        
        var playrobotInstruction = new OSTManualInstruction(1171, 687, LanguageManager.getTextString('ost_manual_playrobot'), 15, 'playrobot_button_line', FlxTextAlign.RIGHT, 'center');
        uiManual.add(playrobotInstruction);
    }
}

class OSTManualInstruction extends FlxSpriteGroup
{
    public function new(x:Float = 0, y:Float = 0, text:String = '', size:Int = 15, graphic:String, textAlign:FlxTextAlign, direction:String)
    {
        super(x, y);

        var line:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ost/manual/$graphic'));
        add(line);

        var text:FlxText = new FlxText(0, 0, 0, text);
        text.setFormat(Paths.font('comic_normal.ttf'), size, FlxColor.WHITE, textAlign);
        add(text);
        
        text.x = switch (textAlign)
        {
            case LEFT: line.x + line.width + 10;
            case CENTER: line.x + (text.textField.textWidth - line.width) / 2;
            case RIGHT: line.x - text.textField.textWidth - 10;
            default: 0;
        }

        text.y = switch (direction)
        {
            case 'top': line.y;
            case 'center': line.y + (line.height - text.textField.textHeight) / 2;
            default: line.y - text.textField.textHeight;
        }
    }
}