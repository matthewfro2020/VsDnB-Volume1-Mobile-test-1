package play.stage;

import flixel.math.FlxPoint;
import util.SortUtil;
import data.IRegistryEntry;
import data.stage.StageData;
import data.stage.StageRegistry;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

import play.character.Character;
import play.stage.BGSprite;

import scripting.IScriptedClass.IPlayStateScriptedClass;
import scripting.IScriptedClass.IStageScriptedClass;
import scripting.events.ScriptEvent;
import scripting.events.ScriptEventDispatcher;

/**
 * A group of props designed as a background for any characters to be.
 */
class Stage extends FlxSpriteGroup implements IPlayStateScriptedClass implements IStageScriptedClass implements IRegistryEntry<StageData>
{
	/**
	 * The default constant color used for if the stage is at night.
	 */
	public static final nightColor:FlxColor = 0xFF51557A;
    
	/**
	 * The default constant color used for if the stage is at sunset.
	 */
	public static final sunsetColor:FlxColor = FlxColor.fromRGB(255, 143, 178);

    /**
     * The id for this stage.
     */
    public final id:String;

    /**
     * The data used for this stage.
     * Retrieved from the registry.
     */
    private var _data:StageData;

    /**
     * The name label for this stage.
     */
    public var name(get, never):String;

    function get_name():String
    {
        return _data?.name ?? 'Unknown';
    }

    /**
     * The camera zoom that's used for this stage.
     */
    public var stageZoom(get, never):Float;

    function get_stageZoom()
    {
        return _data?.zoom ?? 1.0;
    }

    /**
     * Stores a list of all props that don't derive from `BGSprite`
     */
    var unnamedProps:Array<FlxSprite> = new Array<FlxSprite>();

    /**
     * Stores a list of all props that derive from `BGSprite`
     * This is used to easily retrieve a prop in case requested.
     */
    var namedProps:Map<String, BGSprite> = new Map<String, BGSprite>();
    
    /**
     * Stores a list of all of the characters active on this stage.
     */
    var characters:Map<String, Character> = new Map<String, Character>();

    /**
     * Create a new Stage object from the given id.
     * @param id The id to create the stage off of.
     */
    public function new(id:String)
    {
        super();

        this.id = id;

        _data = fetchData(id);
    }
    
    /**
     * Overrides the original toString to allow for easier debugging.
     * @return A string representation of this object.
     */
    override function toString():String
    {
        return 'Stage(id = $id, name = $name)';
    }

    override function destroy():Void
    {
        // Make this stage active again so objects render their update() calls.
        this.active = true;

        // Completely clear out the stage when destroyed so it can be used later when registered.
        kill();

        for (prop in unnamedProps)
        {
            remove(prop);
            prop.destroy();
            prop = null;
        }
        unnamedProps = [];

        for (prop in namedProps.values())
        {
            remove(prop);
            prop.destroy();
            prop = null;
        }
        namedProps.clear();

        for (char in characters.values())
        {
            remove(char);
            char.destroy();
            char = null;
        }
        characters.clear();

        if (group != null)
		{
			for (sprite in this.group)
			{
				if (sprite != null)
				{
					sprite.kill();
					sprite.destroy();
					remove(sprite);
				}
			}
			group.clear();
		}
    }
    
    /**
     * Loads all of the props, and necessary sprites for this stage.
     * This should be overwritten through a script.
     */
    public function load():Void {}

    /**
     * Adds a character to this stage.
     * Properly positions them based on the type of character they are.
     * @param character The character to add.
     * @param type The type of character it is.
     * @param position (Optional) Where to position the character. Defaults to the base stage position if none is provided.
     * @param reposition (Optional) Whether to reposition the character using their global offsets, or leave them as is.
     */
    public function addCharacter(character:Character, ?type:CharacterType, ?position:FlxPoint, ?reposition:Bool = true):Void
    {
        if (character == null)
            return;

        
        if (type == null)
            type = character.characterType;

        var characterStageData:StageDataCharacter = getCharacterStageData(type);

        if (characterStageData != null)
        {
            // Position the character based relative stage position.
            character.x = characterStageData.position[0];
            character.y = characterStageData.position[1];

            // Offset character's camera position based on the stage camera offsets.
            character.cameraFocusPoint.x += characterStageData.cameraOffsets[0];
            character.cameraFocusPoint.y += characterStageData.cameraOffsets[1];

            // Set scroll factors.
            character.scrollFactor.x = characterStageData.scroll[0];
            character.scrollFactor.y = characterStageData.scroll[1];
            
            character.zIndex = characterStageData.zIndex;
        }
        
        // Override position if given.
        if (position != null)
        {
            character.x = position.x;
            character.y = position.y;
        }

        if (reposition)
        {
            // Position the character based on their offsets.
            character.reposition();
        }

        character.characterType = type;

        this.add(character);
    }

    /**
     * Refreshes the stage's sorting layers by comparing each element by it's `zIndex`
     */
    function refresh():Void
    {
        sort(SortUtil.byZIndex);
    }

    /**
     * Retrieves a prop from this stage given its name.
     * @param name The name of the prop.
     * @return A `BGSprite`
     */
    public function getProp(name:String):Null<BGSprite>
    {
        return namedProps.get(name) ?? null;
    }

    /**
     * Retrieves a character from this stage given its id.
     * @param id The id of the character to get.
     * @return A `Null<Character>`.
     */
    public function getCharacter(id:String):Null<Character>
    {
        return characters.get(id) ?? null;
    }

    /**
     * Iterates through each non-character sprite in this stage.
     * @param func The stage to iterate.
     */
    public function forEachProp(func:FlxSprite->Void)
    {
        for (sprite in unnamedProps)
        {
            if (sprite == null)
                continue;
            
            func(sprite);
        }
        
        for (prop in namedProps.values())
        {
            if (prop == null)
                continue;
            
            func(prop);
        }
    }
    
    /**
     * Dispatches the given script event to all characters in this stage.
     * @param event The script event to call.
     */
    public function dispatchToCharacters(event:ScriptEvent)
    {
        for (char in characters.values())
        {
            if (char != null)
            {
                ScriptEventDispatcher.callEvent(char, event);
            }
        }
    }

    /**
     * Dispatches a script event to the given character through its id.
     * @param id The id of the character to.
     * @param event The event to call.
     */
    public function dispatchToCharacter(id:String, event:ScriptEvent)
    {
        var character:Character = getCharacter(id);
        if (character != null)
        {
            ScriptEventDispatcher.callEvent(character, event);
        }
    }

    /**
     * Removes the given sprite out of this stage and brings it to the given stage.
     * 
     * @param sprite The sprite to move.
     * @param stage The stage to put the new sprite in.
     * @param position The position to put the sprite at.
     */
    public function moveSpriteToStage(sprite:FlxSprite, stage:Stage, ?position:FlxPoint)
    {
        this.remove(sprite, true);
        stage.add(sprite);

        if (position != null)
        {
            sprite.x = position.x;
            sprite.y = position.y;
        }
    }
    
    /**
     * Removes the given prop out of this stage and brings it to the given stage.
     * 
     * @param sprite The prop to move.
     * @param stage The stage to put the new prop in.
     * @param position The position to put the sprite at.
     */
    public function movePropToStage(propName:String, stage:Stage, ?position:FlxPoint)
    {
        var prop:BGSprite = getProp(propName);
        
        this.remove(prop, true);
        stage.add(prop);

        if (position != null)
        {
            prop.x = position.x;
            prop.y = position.y;
        }
    }
    
    /**
     * Removes the given character from this stage, and adds it to the given stage.
     * @param char The character to move.
     * @param stage The stage to move the character to.
     * @param position (Optional) Where to position the character. Defaults to the base stage position if none is provided.
     * @param reposition (Optional) Whether to reposition the character using their global offsets, or leave them as is.
     */
    public function moveCharacterToStage(char:Character, stage:Stage, ?position:FlxPoint, ?reposition:Bool = true):Void
    {
        this.remove(char, true);
		stage.addCharacter(char, char.characterType, position, reposition);
        char.alpha = stage.alpha;
    }

    /**
     * Moves every character on this stage to the given stage.
     * Used usually for if the stage switches.
     * 
     * @param stage The stage to move all the characters to.
     * @param position (Optional) Where to position the character. Defaults to the base stage position if none is provided.
     * @param reposition (Optional) Whether to reposition the character using their global offsets, or leave them as is.
     */
    public function moveCharactersToStage(stage:Stage, ?position:FlxPoint, ?reposition:Bool = true):Void
    {
        for (char in characters.values())
        {
            moveCharacterToStage(char, stage, position, reposition);
        }
    }

    public function getCharacterStageData(type:CharacterType):StageDataCharacter
    {
        return switch (type)
        {
            case PLAYER: _data.player;
            case OPPONENT: _data.opponent;
            case GF: _data.gf;
            default: null;
        }
    }

    /**
     * Retrieves the data for the given stage id.
     * @param id The stage id to get the data for.
     * @return A `StageData` for the stage.
     */
    public function fetchData(id:String):StageData
    {
        return StageRegistry.instance.parseEntryDataWithMigration(id);
    }

    /**
	 * Adjusts the position and other properties of the soon-to-be child of this sprite group.
	 * Private helper to avoid duplicate code in `add()` and `insert()`.
	 *
	 * @param	Sprite	The sprite or sprite group that is about to be added or inserted into the group.
	 */
	override function preAdd(sprite:FlxSprite):Void
	{
		sprite.x += x;
		sprite.y += y;
		sprite.alpha *= alpha;

        // We don't want the scroll factor to be copied from the group to allow for it to be customized. 
        // sprite.scrollFactor.copyFrom(scrollFactor);

		sprite.cameras = _cameras; // _cameras instead of cameras because get_cameras() will not return null

		if (clipRect != null)
			clipRectTransform(sprite, clipRect);

        if (Std.isOfType(sprite, Character))
        {
            // Store the character to their associated list in the stage.
            var character:Character = cast sprite;

            this.characters.set(character.id, character);
        }
        else if (Std.isOfType(sprite, BGSprite))
        {
            // Store the character to their associated list in the stage.
            var prop:BGSprite = cast sprite;

            this.namedProps.set(prop.spriteName, prop);
        }
        else
        {
            // This sprite is un-identified. Store it in the unnamed props list.
            this.unnamedProps.push(sprite);
        }
	}


	/**
	 * Removes the specified sprite from the group.
	 *
	 * @param   sprite  The `FlxSprite` you want to remove.
	 * @param   splice  Whether the object should be cut from the array entirely or not.
	 * @return  The removed sprite.
	 */
    public override function remove(sprite:FlxSprite, splice = false):FlxSprite
    {
        if (Std.isOfType(sprite, Character))
        {
            // Character's being removed, remove it from their list.
            var character:Character = cast sprite;
            var stageData = getCharacterStageData(character.characterType);

            if (character != null)
            {
                // Remove the camera offsets.
                character.cameraFocusPoint.x -= stageData?.cameraOffsets[0] ?? 0.0;
                character.cameraFocusPoint.y -= stageData?.cameraOffsets[1] ?? 0.0;
            }

            this.characters.remove(character.id);
        }
        else if (Std.isOfType(sprite, BGSprite))
        {
            // Prop's being removed, remove it from their list.
            var prop:BGSprite = cast sprite;

            this.namedProps.remove(prop.spriteName);
        }
        else
        {
            // Remove the unnamed sprite from their group.
            this.unnamedProps.remove(sprite);
        }

        // Safe to remove them from the Stage now.
        var sprite:FlxSprite = super.remove(sprite, splice);

        // Make sure to refresh the group so everything's ordered properly.
        refresh();

        return sprite;
    }

	/**
	 * Adds a new `FlxSprite` subclass to the group.
	 *
	 * @param   Sprite   The sprite or sprite group you want to add to the group.
	 * @return  The same object that was passed in.
	 */
    override function add(sprite:FlxSprite):FlxSprite
    {
        var event:ScriptEvent = null;

        if (Std.isOfType(sprite, Character))
        {
            // Character's being added, add it to the list.
            var character:Character = cast sprite;

            this.characters.set(character.id, character);

            event = new AddCharacterScriptEvent(character, true);
        }
        else if (Std.isOfType(sprite, BGSprite))
        {
            // Sprite being added is a prop, add it to the list.
            var prop:BGSprite = cast sprite;

            this.namedProps.set(prop.spriteName, prop);
            
            event = new AddPropScriptEvent(prop, true);
        }
        else
        {
            // Add the unnamed sprite to their list.
            this.unnamedProps.push(sprite);
            
            event = new AddPropScriptEvent(sprite, true);
        }
        super.add(sprite);

        // Make sure to refresh the group so everything's ordered properly.
        refresh();

        ScriptEventDispatcher.callEvent(this, event);

        return sprite;
    }
    
    public function onAdd(event:AddPropScriptEvent):Void {}

    public function onCharacterAdd(event:AddCharacterScriptEvent):Void {}

    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onScriptEventPost(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}

    public function onUpdate(event:UpdateScriptEvent):Void {}
    
    public function onDestroy(event:ScriptEvent):Void {}
    
    public function onPreferenceChanged(event:PreferenceScriptEvent):Void {}

    public function onStepHit(event:ConductorScriptEvent):Void {}

    public function onBeatHit(event:ConductorScriptEvent):Void {}

    public function onMeasureHit(event:ConductorScriptEvent):Void {}
    
    public function onTimeChangeHit(event:ConductorScriptEvent):Void {}

    public function onCreatePost(event:ScriptEvent):Void {}

    public function onCreateUI(event:ScriptEvent):Void {}

    public function onSongStart(event:ScriptEvent):Void {}

    public function onSongLoad(event:ScriptEvent):Void {}
    
    public function onSongEnd(event:ScriptEvent):Void {} 

    public function onPause(event:ScriptEvent):Void {}

    public function onResume(event:ScriptEvent):Void {}

    public function onPressSeven(event:ScriptEvent):Void {}
    
    public function onGameOver(event:ScriptEvent):Void {}

    public function onCountdownStart(event:CountdownScriptEvent):Void {}
    
    public function onCountdownTick(event:CountdownScriptEvent):Void {}
    
    public function onCountdownTickPost(event:CountdownScriptEvent):Void {}
    
    public function onCountdownFinish(event:CountdownScriptEvent):Void {}

    public function onCameraMove(event:CameraScriptEvent):Void {}

    public function onCameraMoveSection(event:CameraScriptEvent):Void {}
    
    public function onGhostNoteMiss(event:GhostNoteScriptEvent):Void {}
    
    public function onNoteSpawn(event:NoteScriptEvent):Void {}

    public function onOpponentNoteHit(event:NoteScriptEvent):Void {}
    
    public function onPlayerNoteHit(event:NoteScriptEvent):Void {}

    public function onNoteMiss(event:NoteScriptEvent):Void {}
    
    public function onHoldNoteDrop(event:HoldNoteScriptEvent):Void {}
}