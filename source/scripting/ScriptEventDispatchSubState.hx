package scripting;

import flixel.FlxSubState;
import flixel.addons.ui.FlxUISubState;
import scripting.IScriptedClass.IEventDispatcher;
import scripting.events.ScriptEvent;

/**
 * An `FlxUISubState` state that's able to dispatch script events to script classes.
 * 
 * Extend this to be able to be able to dispatch events to scripts via states.
 */
class ScriptEventDispatchSubState extends FlxUISubState implements IEventDispatcher
{
    public function new()
    {
        super();
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
}