package ui.select.charSelect;

import flixel.group.FlxSpriteGroup;
import ui.select.CharacterPortrait;
import play.player.PlayableCharacter;

class PortraitPage extends FlxTypedSpriteGroup<CharacterPortrait>
{
    var characters:Array<PlayableCharacter>;

    public function new(x:Float = 0, y:Float = 0, characters:Array<PlayableCharacter>)
    {
        super(x, y);

		this.characters = characters;

		for (ind => char in characters)
		{
			var column = Std.int(Math.floor(ind / 3));
			var row = ind % 3;

			var portrait = new CharacterPortrait((row * 225), (225 * column), char.getCharSelectData());
			add(portrait);
		}
    }

	public function setVisiblity(value:Bool):Void
	{
		this.visible = value;
		for (portrait in this.members)
		{
			// Set this value to false automatically, as the actual visibility for this icon already gets updated on portrait selection update.
			portrait.gfIcon.visible = false;
		}
	}
}