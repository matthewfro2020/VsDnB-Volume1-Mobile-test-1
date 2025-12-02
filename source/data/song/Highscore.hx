package data.song;

import flixel.FlxG;

/**
 * Data handler for keeping track of the user's scores.
 */
class Highscore
{
	/**
	 * A mapping of all of the user's scores for each song.
	 */
	public static var songScores:Map<String, Int> = new Map();

	/**
	 * Loads the score data into the game. 
	 */
	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
	}
	/**
	 * Saves the score for a song.
	 * @param song The song to save the score to.
	 * @param score The score the user got.
	 */
	public static function saveScore(song:String, score:Int = 0):Void
	{
		if (songScores.exists(song))
		{
			if (songScores.get(song) < score)
			{
				setScore(song, score);
			}
		}
		else
		{
			setScore(song, score);
		}
	}

	/**
	 * Saves the user's total week score.
	 * @param week The week to save to.
	 * @param score The score the user got.
	 */
	public static function saveWeekScore(week:Int = 1, score:Int = 0):Void
	{
		var weekString:String = 'week${week}';

		if (songScores.exists(weekString))
		{
			if (songScores.get(weekString) < score)
			{
				setScore(weekString, score);
			}
		}
		else
		{
			setScore(weekString, score);
		}
	}

	/**
	 * Sets the score for a song to save into the game's data.
	 * @param song The song to save to.
	 * @param score The score to save.
	 */
	public static function setScore(song:String, score:Int):Void
	{
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	/**
	 * Gets the score for a song. Saves to 0 if none exist.
	 * @param song The song to save to.
	 * @param score The score to save.
	 */
	public static function getScore(song:String):Int
	{
		if (!songScores.exists(song))
		{
			setScore(song, 0);
		}
		return songScores.get(song);
	}

	/**
	 * Gets the score for the given week. Saves to 0 if none exist.
	 * @param week The week to get the score for.
	 * @return The week's score.
	 */
	public static function getWeekScore(week:Int):Int
	{
		if (!songScores.exists('week' + week))
		{
			setScore('week' + week, 0);
		}
		return songScores.get('week' + week);
	}
}
