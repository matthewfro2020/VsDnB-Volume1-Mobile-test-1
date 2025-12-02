package ui.intro;

import data.language.LanguageManager;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;

class OptionsReminderState extends MusicBeatState
{
    #if desktop
    var textString:String = LanguageManager.getTextString('intro_warning');
    #else
    var textString:String = LanguageManager.getTextString('intro_warning_mobile');
    #end

    public override function create()
    {
        var text = new FlxText(0, 0, FlxG.width, textString);
        text.setFormat(Paths.font('comic.ttf'), 32, FlxColor.WHITE, FlxTextAlign.CENTER);
        text.screenCenter();
        add(text);

        super.create();
    }

    var justTouched:Bool = false;

    override function update(elapsed:Float)
    {
        #if mobile
        for (touch in FlxG.touches.list)
	        if (touch.justPressed)
		        justTouched = true;
        #end

        if (FlxG.keys.justPressed.ENTER #if mobile || justTouched #end)
        {
            FlxG.save.data.hasSeenOptionsReminder = true;
            FlxG.save.flush();

            FlxG.switchState(() -> new TitleState());
        }
        super.update(elapsed);
    }
}