package ui.select;

import data.player.PlayerData.PlayerCharacterSelectData;
import data.animation.Animation;
import data.animation.Animation.AnimationData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import play.ui.HealthIcon;

class CharacterPortrait extends FlxSpriteGroup
{
	/**
	 * The data used for this portrait.
	 */
	public final data:PlayerCharacterSelectData;

	/**
	 * The portrait sprite that's displayed.
	 */
	var portrait:FlxSprite;

	/**
	 * The GF icon that shows at the bottom left of the portrait to show what GF this character uses.
	 */
	public var gfIcon:HealthIcon;

	/**
	 * Whether the GF icon should show on this portrait.
	 */
	public var showGfIcon:Bool = true;

	var lastGfIconVisibility:Bool = true;

	public function new(x:Float, y:Float, data:PlayerCharacterSelectData)
	{
		super(x, y);

		scrollFactor.set();

		this.data = data;

		portrait = new FlxSprite();
		portrait.frames = Paths.getSparrowAtlas('selectMenu/ui/portraits/${this.data.portraitFile}', 'preload');

        Animation.addAnimationsToSprite(portrait, [data.unselected, data.selected, data.unselectedTransition, data.selectedTransition]);

		portrait.scale.set(0.8, 0.8);
		portrait.updateHitbox();
		portrait.animation.onFinish.add(function(anim:String)
		{
			switch (anim)
			{
				case(_ == this.data.unselectedTransition.name) => true:
					playAnim(this.data.unselected, true);
				case(_ == this.data.selectedTransition.name) => true:
					playAnim(this.data.selected, true);
				default:
			}
		});
		add(portrait);

		gfIcon = new HealthIcon(data.gf, true);
		gfIcon.autoOffset = false;
		gfIcon.active = false;
		gfIcon.scale.set(0.8, 0.8);
		gfIcon.updateHitbox();
		gfIcon.setPosition((portrait.x - x) - gfIcon.width / 2, ((portrait.y - y) + portrait.height) - gfIcon.height / 2);
		add(gfIcon);

		deselect(true);
	}

	public function playAnim(animation:AnimationData, force:Bool)
	{
		portrait.animation.play(animation.name, force);

		portrait.offset.set(-0.5 * (portrait.width - portrait.frameWidth), -0.5 * (portrait.height - portrait.frameHeight));
		portrait.offset.x += animation.offsets[0] * portrait.scale.x;
		portrait.offset.y += animation.offsets[1] * portrait.scale.y;
	}

	public function select(force:Bool = false)
	{
		gfIcon.visible = showGfIcon;
		playAnim(force ? data.selected : data.selectedTransition, true);
		portrait.scale.set(0.9, 0.9);
	}

	public function deselect(force:Bool = false)
	{
		gfIcon.visible = false;
		playAnim(force ? data.unselected : data.unselectedTransition, true);
		portrait.scale.set(0.8, 0.8);
	}
}