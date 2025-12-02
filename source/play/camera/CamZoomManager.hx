package play.camera;

import flixel.FlxCamera;

/**
 * A data manager for helping customize how a camera zooms.
 */
class CamZoomManager
{
	/**
	 * The camera this manager holds.
	 */
	public var camera:FlxCamera;

	/**
	 * Whether the camera's able to zoom.
	 */
	public var canZoom:Bool;

	/**
	 * Whether the camera's zoom is able to be controlled by it's associated property.
	 * Ex. Having this false on `camGame` would make it not be controlled by `defaultCamZoom`
	 */
	public var canWorldZoom:Bool = true;

	/**
	 * The time camera should zoom, in either beats or steps.
	 */
	public var timeSnap:Float = 4;

	/**
	 * The amount the camera should zoom when bopping.
	 */
	public var zoomValue:Float;

	/**
	 * A multipler for the zoom value.
	 */
	public var intensity:Float = 1;

	/**
	 * Whether to use steps when telling when a camera should zoom.
	 */
	public var useSteps:Bool = false;

	/**
	 * Whether to adjust the camera's zoom time when a time signature changes.
	 */
	public var timeSignatureAdjust:Bool = true;

	public function new(camera:FlxCamera, zoomValue:Float)
	{
		this.camera = camera;
		this.zoomValue = zoomValue;
	}
}
