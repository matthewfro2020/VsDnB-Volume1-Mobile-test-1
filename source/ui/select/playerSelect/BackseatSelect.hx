package ui.select.playerSelect;

import data.player.PlayerData;
import flixel.math.FlxPoint;
import backend.Conductor;
import flixel.FlxG;
import flixel.FlxSprite;
import ui.select.playerSelect.PlayerSelect.SelectedPlayerType;

class BackseatSelect extends PlayerSelect
{
    var elapsedTime:Float = 0;
    var baseSelectY:Float = 0;

    public function new()
    {
        super('backseat');
    }

    public override function update(elapsed:Float)
    {
        super.update(elapsed);

        elapsedTime += elapsed;
        
        selectLogo.y = baseSelectY + Math.sin(elapsedTime * 3) * 5;
    }

    function buildBackground():Void 
    {
        var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('selectMenu/playerSelect/backseat/bg'));
        bg.scale.set(0.7, 0.7);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);
    }

    function buildSelectLogo():Void
    {
        selectLogo = new FlxSprite(800, 25).loadGraphic(Paths.image('selectMenu/playerSelect/backseat/select_logo'));
        selectLogo.scale.set(0.8, 0.8);
        selectLogo.updateHitbox();
        add(selectLogo);

        baseSelectY = selectLogo.y;
    }

    function buildMusic():Void
    {
        Conductor.instance.loadMusicData('playerSelect-backseat');
        SoundController.playMusic(Paths.music('playerSelect/playerSelect-backseat'));
    }

    function getAllPortraits():Array<PlayerData> 
    {
        var tristanBackseat = new PlayerData('Tristan', 'tristan-backseat');
        tristanBackseat.charSelect = {
            gf: 'tristan-gf',
			portraitFile: 'tristan_portrait',
            unselected: {name: 'idle_unselect', prefix: 'unselected_tristan', loop: true},
            selected: {name: 'idle_select', prefix: 'selected_tristan', loop: true},
            unselectedTransition: {name: 'idle', prefix: 'transitionu_tristan'},
            selectedTransition: {name: 'selected', prefix: 'transitions_tristan'},
            page: 0,
            position: 0
        }

        var playrobotBackseat = new PlayerData('Playrobot', 'playrobot-backseat');
        playrobotBackseat.charSelect = {
            portraitFile: 'playrobot_portrait',
			gf: 'playrobot-gf',
			unselected: {name: 'idle_unselect', prefix: 'unselected_playrobot', loop: true},
			selected: {name: 'idle_select', prefix: 'selected_playrobot', loop: true},
			unselectedTransition: {name: 'idle', prefix: 'transitionu_playrobot'},
			selectedTransition: {name: 'selected', prefix: 'transitions_playrobot'},
            page: 0,
            position: 0
        }
        return [playrobotBackseat, tristanBackseat];
    }

    function getCharacterPosition():FlxPoint
    {
        return FlxPoint.get(50, 150);
    }

    function getSelectedCharacterOffset(playerType:SelectedPlayerType):FlxPoint
    {
        return switch (playerType)
        {
            case OPPONENT: FlxPoint.get(0, 50);
            case PLAYER: FlxPoint.get(0, 0);
            default: FlxPoint.get();
        }
    }
}