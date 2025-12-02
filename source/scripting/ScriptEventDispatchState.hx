package scripting;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.ui.FlxUIState;
import scripting.IScriptedClass.IEventDispatcher;
import scripting.events.ScriptEvent;

/**
 * An `FlxUIState` state that's able to dispatch script events to script classes.
 * 
 * Extend this to be able to be able to dispatch events to scripts via states.
 */
class ScriptEventDispatchState extends FlxUIState implements IEventDispatcher
{
	public function new()
	{
		super();

        this.subStateOpened.add(onOpenSubStateComplete);
        this.subStateClosed.add(onCloseSubStateComplete);
	}

	@:nullSafety(Off)
	override function startOutro(onComplete:() -> Void):Void
	{
		var event = new StateChangeScriptEvent(STATE_CHANGE, FlxG.state, true);

		dispatchEvent(event);

		if (event.eventCanceled)
		{
			return;
		}
		else
		{
			super.startOutro(onComplete);
		}
	}
    
	public function dispatchEvent(event:ScriptEvent):Void {}

    public override function openSubState(SubState:FlxSubState):Void
    {
		var event = new StateChangeScriptEvent(SUBSTATE_OPEN, null, true);
		dispatchEvent(event);

        if (event.eventCanceled)
            return;

        super.openSubState(SubState);
    }
    
    function onOpenSubStateComplete(subState:FlxSubState):Void
    {
		dispatchEvent(new StateChangeScriptEvent(SUBSTATE_OPEN_POST, subState));
    }

    override function closeSubState():Void
    {
		var event = new StateChangeScriptEvent(SUBSTATE_CLOSE, this.subState, true);
		dispatchEvent(event);

        if (event.eventCanceled)
            return;

        super.closeSubState();
    }

    function onCloseSubStateComplete(subState:FlxSubState):Void
    {
		dispatchEvent(new StateChangeScriptEvent(SUBSTATE_CLOSE_POST, subState));
    }

	public function reloadAssets():Void
	{
		modding.PolymodManager.reloadAssets();
	}
}