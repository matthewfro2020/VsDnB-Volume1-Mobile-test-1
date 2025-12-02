package graphics.video;

import flixel.FlxG;
import hxvlc.flixel.FlxVideo;

/**
 * Handler for managing loading, and playing videos.
 */
class VideoManager
{
	/**
	 * Plays a video.
	 * @param videoPath The path of the video.
	 * @param onFinish Called when the video is finished.
	 * @return The video being played.
	 */
	public static function playVideo(videoPath:String, ?onFinish:Void->Void):FlxVideo
	{
		var video = new FlxVideo();

		video.onEndReached.add(() ->
		{
			if (onFinish != null)
				onFinish();

			video.dispose();
			FlxG.removeChild(video);
		});
		video.load(videoPath);
		FlxG.addChildBelowMouse(video);
		video.play();

		return video;
	}
}
