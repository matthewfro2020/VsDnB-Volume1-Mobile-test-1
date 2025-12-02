package data.language;

import haxe.Exception;
import data.language.Language;
import flixel.FlxG;
import flixel.util.FlxColor;
import play.save.Preferences;
import util.FileUtil;

typedef LanguageList = Map<String, String>;

/**
 * A core handler for managing languages, and the current language the user has selected.
 */
class LanguageManager
{
	/**
	 * The parsed list of all of the language data.
	 * Contains the id of the language key, and the text for it.
	 */
	public static var currentLocaleList:LanguageList;

	/**
	 * The parsed list of all language data for dialogue.
	 */
	public static var currentDialogueList:LanguageList;
	
	/**
	 * The parsed list of all language data for subtitles.
	 */
	public static var currentSubtitlesList:LanguageList;
	
	/**
	 * The parsed list of all language data for subtitles.
	 */
	public static var currentCreditsList:LanguageList;

	/**
	 * Initalizes the manager.
	 * Loads, and caches all of the locale files to be used.
	 */
	public static function init()
	{
		currentLocaleList = parseLocaleFile('locale/' + Preferences.language + '/textList.txt');
		currentDialogueList = parseLocaleFile('locale/' + Preferences.language + '/dialogue.txt');
		currentSubtitlesList = parseLocaleFile('locale/' + Preferences.language + '/subtitles.txt');
		currentCreditsList = parseLocaleFile('locale/' + Preferences.language + '/credits.txt');

		FlxG.console.registerClass(LanguageManager);
	}

	/**
	 * Retrieves all languages objects.
	 * @return A list of all of the languages
	 */
	public static function getLanguages():Array<Language>
	{
		var languages:Array<Language> = [];
		var languagesText:Array<String> = FileUtil.splitText(Paths.langaugeFile());

		for (language in languagesText)
		{
			var splitInfo:Array<String> = language.split(':');
			var languageData:Language = {name: splitInfo[0], id: splitInfo[1], color: FlxColor.fromString(splitInfo[2])}

			languages.push(languageData);
		}
		return languages;
	}

	/**
	 * Retrieves a language object from an id.
	 * @param id The id of the language.
	 * @return A Language object.
	 */
	public static function languageFromId(id:String):Language
	{
		var langauges:Array<Language> = getLanguages();

		for (langauge in langauges)
		{
			if (langauge.id == id)
			{
				return langauge;
			}
		}
		return null;
	}

	/**
	 * Retrieves a string value for the given id of a locale list.
	 * @param id The id of the language key.
	 * @param list Optional, the language list to use for retrieving the string.
	 * @return The value of the language key.
	 */
	public static function getTextString(id:String, ?list:LanguageList):String
	{
		var listToUse:LanguageList = list ?? currentLocaleList;

		if (listToUse.exists(id))
		{
			var textValue:String = listToUse.get(id);
			
			textValue = textValue.replace(':linebreak:', '\n');
			textValue = textValue.replace(':addquote:', '\"');

			return textValue;
		}
		else
		{
			return id;
		}
	}

	/**
	 * Parses a locale file, and gives out a new formatted language list.
	 * @param path The asset path for the file.
	 * @return A new `LanguageList`
	 */
	static function parseLocaleFile(path:String):LanguageList
	{
		var list:LanguageList = new LanguageList();

		var splitText:Array<String> = FileUtil.splitText(Paths.file(path, TEXT, 'preload'));
		for (languageData in splitText)
		{
			try
			{
				var data:Array<String> = languageData.trim().split('==');

				var id:String = data[0];
				var text:String = data[1];

				list.set(id, text);
			}
			catch (e)
			{
				var message:String = buildErrorMessage(path, e);
				FlxG.stage.window.alert('There was an error while parsing the language. ${message}', 'Language Parsing Error');
				FlxG.stage.window.close();
			}
		}
		return list;
	}

	/**
	 * Builds an error message to use for if there's a parsing error for a language.
	 * @param file The file being parsed.
	 * @param e The error message.
	 * @return An error message.
	 */
	static function buildErrorMessage(file:String, e:Exception):String
	{
		var message:String = 'There was an error while parsing the language file for ${Preferences.language}. (${file})\n\n';
		message += e.stack.toString();

		return message;
	}
}