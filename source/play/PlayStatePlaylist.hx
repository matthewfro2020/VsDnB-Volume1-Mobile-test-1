package play;

import play.song.Song;

class PlayStatePlaylist
{
	/**
	 * Whether the player is currently in StoryMode, or not.
	 */
	public static var isStoryMode:Bool = false;

	/**
	 * The current week used for this playlist.
	 */
	public static var storyWeek:Int = 0;

	/**
	 * The list of songs to be played on this playlist.
	 */
	public static var songList:Array<String> = [];
	
	/**
	 * The current score for this campaign.
	 */
	public static var campaignScore:Int = 0;

	/**
	 * Completely resets, and wipes all data of the playlist.
	 */
	public static function reset():Void
	{
		isStoryMode = false;
		storyWeek = 0;
		campaignScore = 0;
		songList = [];
	}
}