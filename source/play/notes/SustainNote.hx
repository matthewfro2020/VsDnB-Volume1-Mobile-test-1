package play.notes;

import data.song.SongData.SongNoteData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;
import flixel.math.FlxPoint;
import flixel.math.FlxPoint.FlxCallbackPoint;
import flixel.math.FlxMath;
import openfl.geom.Rectangle;
import play.PlayState;
import play.character.Character;
import play.save.Preferences;

/**
 * Like 'SustainTrail.hx' from Base FNF, uses 'drawTriangles()' to render a sustain trail from a note.
 * Instead of using the texture graphic, this gets the animation data for the trail, to render onto the sprite. 
 * 
 * This class has a lot of similar properties to 'Note.hx', but should have it's logic completely kept different from it.
 */
@:access(objects.ui.notes.Note)
class SustainNote extends FlxSprite
{
	// STATIC / CONSTANT VARIABLES // 
	
	/**
	 * The amount of health the player gains per second while holding down a sustain note.
	 * 7.5 % / second
	 */
	public static var HEALTH_GAIN_PER_SECOND:Float = 0.075 * 2;

	/**
	 * The amount of health the player loses when missing a hold note, per second.
	 * 15 % / per second.
	 */
	public static var HEALTH_LOSS_PER_SECOND:Float = 0.15 * 2;

	/**
	 * The max amount of health a player can lose from a hold note.
	 * 40 %.
	 */
	public static var HEALTH_LOSS_MAX:Float = 0.40 * 2;

	/**
	 * The max amount of health a player can gain from a hold note.
	 * 20 % / second.
	 */
	public static var HEALTH_GAIN_MAX:Float = 0.20 * 2;

	/**
	 * The amount of score the player contains per second while holding down a note.
	 * 200 / second.
	 */
	public static var SCORE_GAIN_PER_SECOND:Float = 200;

	/**
	 * The amount of health the player loses when missing a hold note, per second.
	 * 300 / per second.
	 */
	public static var SCORE_LOSS_PER_SECOND:Float = 300;

	/**
	 * The max amount of score a player can lose from a hold note.
	 * 1000 score.
	 */
	public static var SCORE_LOSS_MAX:Float = 1000;

	/**
	 * The length the sustain note needs to have in order to account for penalties, in milliseconds.
	 */
	public static var PENALTY_MINIMUM:Float = 100.0;


	// DATA VARIABLES //

	/**
	 * The vertices being used to draw this sprite.
	 * These are made up of points, where 3 points draw a triangle to render.
	 */
	public var vertices:DrawData<Float> = new DrawData<Float>();

	/**
	 * The indices (in point index) being used to render the sprite.
	 */
	public var indices:DrawData<Int> = new DrawData<Int>();

	/**
	 * The UV data, corresponding with the vertex points, being used to render the sprite.
	 */
	public var uvtData:DrawData<Float> = new DrawData<Float>();


	// DATA PROPERTIES // 

	/**
	 * The data for this note.
	 */
	public var noteData:SongNoteData = null;

	/**
	 * The time at which note sustain note's supposed to be held.
	 */
	public var strumTime:Float = 0;
	
	/**
	 * The direction of the sustain note.
	 */
	public var direction:Int = 0;

	/**
	 * The type of note this sustain note is.
	 */
	public var type:String;
	
	/**
	 * Whether this sustain note is cpu controlled, or is supposed to be hit by the player.
	 */
	public var mustPress:Bool = false;


	// PROPERTIES //
	
	/**
	 * The original length, in ms, of this sustain note.
	 */
	public var fullSustainLength:Float;

	/**
	 * The length of this sustain note, in ms.
	 */
	public var sustainLength(default, set):Float;

	function set_sustainLength(value:Float):Float
	{
		if (value <= 0.0)
			value = 0.0;
		if (sustainLength == value)
			return sustainLength;
		
		if (value > fullSustainLength)
			this.fullSustainLength = value;

		this.sustainLength = value;
		redraw();
		return value;
	}

	/**
	 * The note style of this sustain note.
	 */
	public var noteStyle(default, set):NoteStyle;

	function set_noteStyle(value:NoteStyle):NoteStyle
	{
		buildSustainGraphic(value);
		return noteStyle = value;
	}

	/**
	 * The amount of triangles, in sets of 2, the 'hold' piece of this sustain is divided into.
	 * Useful in case the graphic frame of the hold trail doesn't loop, and is meant to be rendered into multiple pieces.
	 * For performance, it's best to set this to as smallest as possible.
	 */
	public var subdivisions(default, set):Int = 1;

	function set_subdivisions(value:Int)
	{
		if (subdivisions == value)
			return value;

		// The sprite always needs at least 1 subdivision to render.
		value = Std.int(Math.max(value, 1));

		this.subdivisions = value;
		updateClipping();
		setupIndices(this.subdivisions);
		this.renderedSubdivisions = this.subdivisions;
		return value;
	}

	/**
	 * The current animation being played for the hold trail part of the sustain.
	 * Helps to calculate the UV data for the current frame the animation is on, to then render onto the sprite.
	 */
	var holdAnimation(default, null):FlxAnimation;

	/**
	 * The current animation being played for the 'end' part of the sustain.
	 * Helps to calculate the UV data for the current frame the animation is on, to then render onto the sprite.
	 */
	var holdEndAnimation(default, null):FlxAnimation;

	/**
	 * The current frame of the 'hold' animation.
	 * Helps to calculate the UV data to render onto the sprite.
	 */
	var holdFrame(get, never):FlxFrame;

	function get_holdFrame():FlxFrame
	{
		return frames?.frames[holdAnimation?.frames[holdAnimation?.curFrame]] ?? null;
	}

	/**
	 * The current frame of the 'end' animation.
	 * Helps to calculate the UV data to render onto the sprite.
	 */
	var holdEndFrame(get, never):FlxFrame;

	function get_holdEndFrame():FlxFrame
	{
		return frames?.frames[holdEndAnimation?.frames[holdEndAnimation?.curFrame]] ?? null;
	}

	// VARIABLES // 

	/**
	 * The original style of this note from when it was first generated.
	 * Good for keeping track of properties from this structure that can be used later on.
	 */
	public var baseStyle:NoteStyle;

	/**
	 * The strumline associated with this sustain note.
	 */
	public var parentStrumline:Strumline;
	
	/**
	 * The strum receptor associated with this sustain note.
	 */
	public var strum:StrumNote;
	
	/**
	 * The character associated with this note.
	 */
	public var character:Character;

	/**
	 * The hold cover associated with this sustain note.
	 */
	public var cover:HoldCover;

	/**
	 * The scroll speed used for this note.
	 * Is taken into account when calculating it's y position.
	 */
	public var localScrollSpeed:Float = 1.0;

	/**
	 * Whether this note uses custom triangle data to render the sprite.
	 * If this is used, you'll need to manually include the subdivision.
	 */
	public var customVertexData:Bool = false;

	/**
	 * Flag variable for when the sustain note has been hit.
	 */
	public var hasBeenHit:Bool = false;

	/**
	 * Flag variable for if the sustain note either wasn't held within the window, or was dropped as it was being held.
	 */
	public var hasMissed:Bool = false;

	/**
	 * Whether the logic for when the sustain note has been done.
	 */
	public var handledMiss:Bool = false;

	/**
	 * A Modifier that can be used to help change the alpha of this sustain note.
	 */
	public var alphaModifier:Float = 1.0;

	/**
	 * This sustain note is being used in chart editor and shouldn't have any gameplay logic done.
	 */
	public var inCharter:Bool;

	/**
	 * The graphic this sprite uses.
	 * This is so you're able to change the color/alpha without affecting the whole graphic.
	 */
	private var processedGraphic:FlxGraphic;

	/**
	 * Internal variable to help on if the sustain should be re-drawn, or not.
	 */
	private var previousSpeed:Float;

	/**
	 * Internal variable for keeping track of the actual sprite's width.
	 */
	private var spriteWidth:Float;

	/**
	 * Internal variable for keeping track of the actual sprite's height.
	 */
	private var spriteHeight:Float;

	/**
	 * Internal variable for keeping track of the amount of subdivisions being rendered on this note right now for optimization.
	 */
	private var renderedSubdivisions:Int;
	
	/**
	 * Calculates the height of a sustain note.
	 * @param sustainLength The length of the sustain note. 
	 * @param scrollSpeed The speed of the sustain note.
	 * @return A height to be used for a sustain note, in pixels.
	 */
	public inline static function sustainHeight(sustainLength:Float, scrollSpeed:Float):Float
	{
		return sustainLength * 0.45 * scrollSpeed;
	}
	
	/**
	 * Returns a default speed to use as a fallback.
	 * @return The base speed.
	 */
	static function getBaseScrollSpeed():Float
	{
		return PlayState?.instance?.songSpeed ?? 1.0;
	}

	public function new(strumTime:Float, direction:Int, mustHit:Bool, length:Float, noteStyle:NoteStyle = 'normal',
			inCharter:Bool = false)
	{
		super();

		// Reset scale as FlxCallbackPoint so the graphic immediately updates when the scale updates.
		this.scale = new FlxCallbackPoint((value:FlxPoint) -> {
			redraw();
		});
		this.scale.set(1, 1);
		
		this.strumTime = strumTime;
		this.direction = direction;
		this.mustPress = mustHit;
		this.inCharter = inCharter;
		
		this.baseStyle = noteStyle;
		this.noteStyle = noteStyle;
		
		this.flipY = Preferences.downscroll;

		this.fullSustainLength = length;
		this.sustainLength = length;

		if (inCharter)
		{
			this.scale.x *= (40.0 / (154 * 0.7));
		}

		updateClipping();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		updateAlpha();
		
		if (!inCharter && strum != null)
		{
			this.copyStrum();
		}

		if (holdAnimation == null || holdEndAnimation == null) return;

		var lastHoldFrame:FlxFrame = holdFrame;
		var lastHoldEndFrame:FlxFrame = holdEndFrame;

		holdAnimation.update(elapsed * (animation.timeScale * FlxG.animationTimeScale));
		holdEndAnimation.update(elapsed * (animation.timeScale * FlxG.animationTimeScale));

		var currentSpeed:Float = getScrollSpeed();
		if (previousSpeed != currentSpeed || (lastHoldFrame != holdFrame || lastHoldEndFrame != holdEndFrame))
		{
			redraw();
		}
		previousSpeed = currentSpeed;
	}

	override public function draw():Void
	{
		if (alpha == 0 || graphic == null || vertices == null)
			return;

		final cameras = getCamerasLegacy();

		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);

			camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing, colorTransform, shader);
		}
	}

	override function updateHitbox()
	{
		if (inCharter)
		{
			this.width = 40;
			this.height = spriteHeight;

			offset.set(-0.5 * (width - spriteWidth), 0);
		}
		else
		{
			this.width = spriteWidth;
			this.height = spriteHeight;
		}
		origin.set(this.width * 0.5, this.height * 0.5);
	}
	
	override function kill()
	{
		super.kill();

		fullSustainLength = 0;
		sustainLength = 0;
		subdivisions = 1;
		parentStrumline = null;
		character = null;
	}
	
	override function revive()
	{
		super.revive();

		strumTime = 0;
		direction = 0;
		
		fullSustainLength = 0;
		sustainLength = 0;
		subdivisions = 1;
		localScrollSpeed = 1.0;
		
		hasBeenHit = false;
		hasMissed = false;
		handledMiss = false;
	}

	override function destroy()
	{
		vertices = null;
		uvtData = null;
		indices = null;

		processedGraphic?.destroy();
		processedGraphic = null;
		
		super.destroy();
	}

	/**
	 * Sets up the sustain note's graphic and animations for it to be ready to use.
	 * @param noteStyle The note style for this sustain note to use.
	 */
	public function buildSustainGraphic(noteStyle:NoteStyle)
	{
		noteStyle.applyStyleToSustain(this);

		spriteWidth = holdFrame.frame.width * this.scale.x;
		spriteHeight = sustainHeight(sustainLength, getScrollSpeed()) * this.scale.y;
		
		updateHitbox();

		processedGraphic?.destroy();
		processedGraphic = FlxGraphic.fromGraphic(graphic, true);
		
		updateClipping();
	}

	/**
	 * Returns the speed of this sustain note.
	 * Takes into account if the sustain note has a parent strumline, and other optional variables.
	 * @return The sustain note's current scroll speed.
	 */
	function getScrollSpeed():Float
	{
		return inCharter ? 1.0 : (parentStrumline?.scrollSpeed ?? getBaseScrollSpeed()) * localScrollSpeed;
	}
	
	/**
	 * Updates the sustain note's animation data based on the current note style.
	 */
	public function updateAnimations()
	{
		var colorsToUse:Array<String> = Note.COLOR_DIRECTIONS;

		holdAnimation = animation.getByName('${colorsToUse[this.direction]}hold');
		holdEndAnimation = animation.getByName('${colorsToUse[this.direction]}holdend');

		updateClipping();
	}
	
	/**
	 * Sets the parent strum receptor for this note to use.
	 * If no custom strumline is set, it's either the opponent or player strumline based on it's data properties.
	 * @param strumLine The strumline to get this strum receptor for.
	 */
	public function setStrum(?strumLine:Strumline)
	{
		var strumGroup = strumLine;
		if (strumGroup == null)
		{
			strumGroup = (FlxG.state is PlayState) ? (mustPress ? PlayState.instance.playerStrums : PlayState.instance.dadStrums) : null;
		}
		
		strum = strumGroup?.strums?.members[this.direction] ?? null;
		updateAlpha();
		copyStrum();
	}

	/**
	 * Copies the properties of this sustain note based on it's parent strum receptor.
	 */
	public function copyStrum()
	{
		if (strum == null) return;

		if (!Note.rotate) 
			x = strum.x + (strum.width - this.spriteWidth) / 2;

		if (strum.pressingKey5)
		{
			if (noteStyle != "shape")
				alpha *= 0.5;
		}
		else
		{
			if (noteStyle == "shape")
			{
				alpha *= 0.5;
			}
		}
	}

	/**
	 * Updates the alpha for this note. Separate function as this has multiple states where the alpha can change.
	 */
	function updateAlpha()
	{		
		var missModifier:Float = 1.0;
		if (handledMiss)
			missModifier = 0.4;

		if (strum != null)
			alpha = strum.alpha * alphaModifier * missModifier;
		else
			alpha = alphaModifier * missModifier;
	}

	/**
	 * Updates the current graphic in accordance to the sustain's length, and the current song.
	 */
	function redraw()
	{
		spriteWidth = (holdFrame?.frame?.width ?? 0.0) * this.scale.x;
		spriteHeight = sustainHeight(sustainLength, getScrollSpeed()) * this.scale.y;
		
		updateClipping();
		updateHitbox();
	}

	/**
	 * The vertices the sprite should use to render.
	 * @param vertices The new vertices to use.
	 */
	public function setVertices(vertices:Array<Float>)
	{
		if (vertices.length == this.vertices.length)
		{
			for (i in 0...vertices.length)
			{
				this.vertices[i] = vertices[i];
			}
		}
		else
		{
			this.vertices = new DrawData(vertices.length, true, vertices);
		}
	}

	/**
	 * The UV data the sprite should use to render.
	 * @param uvtData The new uvtData to render.
	 */
	public function setUVTData(uvtData:Array<Float>)
	{
		if (uvtData.length == this.uvtData.length)
		{
			for (i in 0...uvtData.length)
			{
				this.uvtData[i] = uvtData[i];
			}
		}
		else
		{
			this.uvtData = new DrawData(uvtData.length, true, uvtData);
		}
	}

	/**
	 * The indices the sprite should use to render.
	 * @param indices The new indices to render. 
	 */
	public function setIndices(indices:Array<Int>)
	{
		if (indices.length == this.indices.length)
		{
			for (i in 0...indices.length)
			{
				this.indices[i] = indices[i];
			}
		}
		else
		{
			this.indices = new DrawData(indices.length, true, indices);
		}
	}

	/**
	 * Sets up the sprite with new vertices, and UV data to use for rendering. 
	 * The values are flipped if the sustain is on downscroll.
	 */
	function updateClipping()
	{
		if (graphic == null || holdFrame == null || holdEndFrame == null || sustainLength <= 0 || customVertexData)
		{
			return;
		}

		var fullClipHeight = sustainHeight(this.fullSustainLength, getScrollSpeed());
		var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength, getScrollSpeed()), 0, spriteHeight);
		if (clipHeight <= 0)
		{
			visible = false;
			return;
		}

		var bottomHeight:Float = holdEndFrame.frame.height * this.scale.x;
		var partHeight:Float = clipHeight - bottomHeight; // Represents the height of the hold without the trail end
		var fullPartHeight:Float = fullClipHeight - bottomHeight;
		
		//   HOLD VERTICES //

		// Top left
		vertices[0 * 2] = 0.0;
		vertices[0 * 2 + 1] = flipY ? clipHeight : (spriteHeight - clipHeight);

		// Top Right
		vertices[1 * 2] = spriteWidth;
		vertices[1 * 2 + 1] = vertices[0 * 2 + 1];

		// Getting the points of the bottom part of the 'hold' piece is complicated with subdivision.
		// We need to divide the height into several subdivided pieces.
		// Then, we need to create new vertex points for those subdivided pieces.
		// The last index of the vertex point will also need to be tracked for the end point of the trail.

		// Get heights split.
		var splitHeights:Array<Float> = subdivideHeight(partHeight, fullPartHeight);

		// Set the starting vertex index to the next one in the list.
		var startIndexPoint:Int = 2;
		var vertexIndex:Int = startIndexPoint;
		var lastVertexIndex:Int = startIndexPoint;

		var index:Int = 0;
		for (height in splitHeights)
		{
			// If it's the first height being added, only the bottom side is needed.
			if (index == 0)
			{
				// Bottom-Left vertex points.
				vertices[vertexIndex * 2] = vertices[0 * 2]; // Inline with the top-left point.
				vertices[vertexIndex * 2 + 1] = if (height > 0) // If there's height available, inline with the top-left side, else add it.
				{
					flipY ? vertices[0 * 2 + 1] - height : vertices[0 * 2 + 1] + height;
				}
				else
				{
					vertices[0 * 2 + 1];
				}

				// Bottom-Right vertex points.
				vertices[(vertexIndex + 1) * 2] = vertices[1 * 2]; // Inline with the top-right side.
				vertices[(vertexIndex + 1) * 2 + 1] = vertices[vertexIndex * 2 + 1]; // Inline with the left side of this vertex point.

				// Store the last vertex index before it increments for easier calculation.
				lastVertexIndex = vertexIndex;

				// Increase the vertex point by 2 since 2 points were just used up.
				vertexIndex += 2;
			}
			else // Else, we need to add a top point that starts from the last bottom point, and then add the height.
			{
				// Top-left (Inline with the bottom-left of the last vertex.)
				vertices[vertexIndex * 2] = vertices[lastVertexIndex * 2];
				vertices[vertexIndex * 2 + 1] = vertices[lastVertexIndex * 2 + 1];

				// Top-right (Inline with the bottom-right of the last vertex.)
				vertices[(vertexIndex + 1) * 2] = vertices[(lastVertexIndex + 1) * 2];
				vertices[(vertexIndex + 1) * 2 + 1] = vertices[(lastVertexIndex + 1) * 2 + 1];

				// Bottom-left side vertex points.
				vertices[(vertexIndex + 2) * 2] = vertices[vertexIndex * 2]; // Inline with the top-left point.
				vertices[(vertexIndex + 2) * 2 + 1] = flipY ? vertices[vertexIndex * 2 + 1] - height : vertices[vertexIndex * 2 + 1] + height;

				// Bottom-right side vertex points.
				vertices[(vertexIndex + 3) * 2] = vertices[(vertexIndex + 1) * 2]; // Inline with the top-right side.
				vertices[(vertexIndex + 3) * 2 + 1] = vertices[(vertexIndex + 2) * 2 + 1]; // Inline with the left side of this vertex point.

				// Store the bottom side of the last vertex index.
				lastVertexIndex = vertexIndex + 2;

				// Increase the vertex point by 4 since 4 points were just used up.
				vertexIndex += 4;
			}
			index++;
		}

		// HOLD END VERTICES //

		// This isn't as complicated, but because of the subdivided vertex points.
		// We need to take those into account for these new vertex points.

		// Store the last bottom vertices of the divided hold piece to use for calculations.
		var endVertexIndexLeft:Int = vertexIndex - 2;
		var endVertexIndexRight:Int = vertexIndex - 1;

		// Top Left
		vertices[vertexIndex * 2] = vertices[endVertexIndexLeft * 2]; // Inline with the left side last subdivided vertex point.
		vertices[vertexIndex * 2 + 1] = vertices[endVertexIndexLeft * 2 + 1]; // Inline with the y coord of the left side last subdivided vertex point.

		// Top Right
		vertices[(vertexIndex + 1) * 2] = vertices[endVertexIndexRight * 2]; // Inline with the right side last subdivided vertex point.
		vertices[(vertexIndex + 1) * 2 + 1] = vertices[endVertexIndexRight * 2 + 1]; // Inline with the y coord the right side of the last subdivided vertex point.

		// Bottom Left
		vertices[(vertexIndex + 2) * 2] = vertices[vertexIndex * 2]; // Inline with the top-left point of the end trail.
		vertices[(vertexIndex + 2) * 2 + 1] = if (partHeight > 0)
		{
			flipY ? vertices[vertexIndex * 2 + 1] - bottomHeight : (vertices[vertexIndex * 2 + 1] + bottomHeight);
		}
		else
		{
			// There is no part height, meaning the end trail needs to be clipped instead
			flipY ? (vertices[vertexIndex * 2 + 1] - bottomHeight * (clipHeight / bottomHeight)) : (vertices[vertexIndex * 2 + 1] + bottomHeight * (clipHeight / bottomHeight));
		}

		// Bottom Right
		vertices[(vertexIndex + 3) * 2] = vertices[(vertexIndex + 1) * 2]; // Inline with the top-right of the end trail.
		vertices[(vertexIndex + 3) * 2 + 1] = vertices[(vertexIndex + 2) * 2 + 1]; // Inline with the y coord of the bottom-left of the end trail.

		//  HOLD UVs //

		// UV values take a normalized value of 0-1 for it's points. This is then used to texture the graphic.
		// Since the spritesheet positions of the animation frames are stored. We can simply normalize those values to then use.

		// Top Left
		uvtData[0 * 2] = holdFrame.frame.x / graphic.width;
		uvtData[0 * 2 + 1] = (holdFrame.frame.y + (1 - Math.max(0, splitHeights[0] / (fullPartHeight / renderedSubdivisions))) * holdFrame.frame.height) / graphic.height;

		// Top Right
		uvtData[1 * 2] = (holdFrame.frame.x + holdFrame.frame.width) / graphic.width;
		uvtData[1 * 2 + 1] = uvtData[0 * 2 + 1];

		var curVertexPoint:Int = startIndexPoint;

		// 'vertexIndex' represents the end of the subdivided vertices.
		while (curVertexPoint != vertexIndex)
		{
			// This vertex point is of the bottom side.
			if (curVertexPoint == startIndexPoint)
			{
				// Bottom Left-side UVs.
				uvtData[curVertexPoint * 2] = uvtData[0 * 2]; // Inline with top-left UVs.
				uvtData[curVertexPoint * 2 + 1] = (holdFrame.frame.y + holdFrame.frame.height) / graphic.height;

				// Right-side UVs.
				uvtData[(curVertexPoint + 1) * 2] = uvtData[1 * 2]; // Inline with top-right UVs.
				uvtData[(curVertexPoint + 1) * 2 + 1] = uvtData[curVertexPoint * 2 + 1]; // Inline with bottom-left subdivided UVs.

				curVertexPoint += 2;
			}
			else
			{
				// This vertex point isn't the start index, this should use normal UVs as it isn't being clipped.

				// Top Left UVs.
				uvtData[curVertexPoint * 2] = uvtData[0 * 2]; // Inline with top-left UVs.
				uvtData[curVertexPoint * 2 + 1] = holdFrame.frame.y / graphic.height;

				// Top Right UVs.
				uvtData[(curVertexPoint + 1) * 2] = uvtData[1 * 2]; // Inline with top-right UVs.
				uvtData[(curVertexPoint + 1) * 2 + 1] = uvtData[curVertexPoint * 2 + 1]; // Inline with top-left subdivided UVs.

				// Bottom Left UVs.
				uvtData[(curVertexPoint + 2) * 2] = uvtData[curVertexPoint * 2]; // Inline with top-left UVs.
				uvtData[(curVertexPoint + 2) * 2 + 1] = (holdFrame.frame.y + holdFrame.frame.height) / graphic.height;

				// Bottom Right UVs.
				uvtData[(curVertexPoint + 3) * 2] = uvtData[(curVertexPoint + 1) * 2]; // Inline with top-right UVs.
				uvtData[(curVertexPoint + 3) * 2 + 1] = uvtData[(curVertexPoint + 2) * 2 + 1]; // Inline with bottom-left subdivided UVs.

				curVertexPoint += 4;
			}
		}

		// HOLD END UVs //

		// Top Left
		uvtData[vertexIndex * 2] = holdEndFrame.frame.x / graphic.width;
		uvtData[vertexIndex * 2 + 1] = if (partHeight > 0)
		{
			holdEndFrame.frame.y / graphic.height;
		}
		else
		{
			// No part height available, clip off the graphic using UVs.
			(holdEndFrame.frame.y + ((bottomHeight - clipHeight) / this.scale.x)) / graphic.height;
		}

		// Top Right
		uvtData[(vertexIndex + 1) * 2] = (holdEndFrame.frame.x + holdEndFrame.frame.width) / graphic.width;
		uvtData[(vertexIndex + 1) * 2 + 1] = uvtData[vertexIndex * 2 + 1]; // Inline with top-left end trail UVs.

		// Bottom Left
		uvtData[(vertexIndex + 2) * 2] = uvtData[vertexIndex * 2]; // Inline with top-left end trail UVs.
		uvtData[(vertexIndex + 2) * 2 + 1] = (holdEndFrame.frame.y + holdEndFrame.frame.height) / graphic.height;

		// Bottom Right
		uvtData[(vertexIndex + 3) * 2] = uvtData[(vertexIndex + 1) * 2]; // Inline with top-right end trail UVs.
		uvtData[(vertexIndex + 3) * 2 + 1] = uvtData[(vertexIndex + 2) * 2 + 1]; // Inline with bottom-left end trail UVs.

		if (splitHeights.length != renderedSubdivisions)
		{
			// splitHeight is in accordance to the number of subdivisions.
			// Because the length of the array changes depending on the height.
			// The indices need to be updated.

			this.renderedSubdivisions = splitHeights.length;
			setupIndices(splitHeights.length);
		}
	}

	/**
	 * Creates a new set of point indices for the sustain note to use based on the number of subdivisions
	 * @param subdivisions The amount of subdivisions to base the new indices off of.
	 */
	function setupIndices(subdivisions:Int)
	{
		// The indices are the triangles which are used to be drawn onto the sprite.
		// Normally without subdivisions, this can easily just be a static array.
		// With subdivisions though these needs to be calculated.

		// HOLD INDICES //

		var indices:Array<Int> = [];

		// 2 is the base starting vertex, and a pair of 2 triangles need 4 points.
		// At the first pair only 2 points are needed though, making it 4.
		var endVertexIndex:Int = 4;

		// Default indices that render no matter what.

		// Left-side triangle.
		indices.push(0);
		indices.push(1);
		indices.push(2);

		// Right-side triangle.
		indices.push(1);
		indices.push(2);
		indices.push(3);

		for (i in 0...subdivisions - 1)
		{
			// Bottom Left-side triangle.
			indices.push(4 + i * 4);
			indices.push(5 + i * 4);
			indices.push(6 + i * 4);

			// Bottom Right-side triangle.
			indices.push(5 + i * 4);
			indices.push(6 + i * 4);
			indices.push(7 + i * 4);

			endVertexIndex += 4;
		}

		// END TRAIL INDICES //

		indices.push(endVertexIndex);
		indices.push(endVertexIndex + 1);
		indices.push(endVertexIndex + 2);

		indices.push(endVertexIndex + 1);
		indices.push(endVertexIndex + 2);
		indices.push(endVertexIndex + 3);

		setIndices(indices);
	}

	/**
	 * Splits the height of a 'hold' trail into multiple pieces.
	 * @param height The height to split into.
	 * @param fullHeight The original height of the trail.
	 * @return A list of clipped subdivided floats.
	 */
	function subdivideHeight(height:Float, fullHeight:Float):Array<Float>
	{
		if (height < 0 || fullHeight < 0)
			return [0];

		// If the subdivision is only 1, just return the height itself.
		if (this.subdivisions == 1)
			return [height];

		// This is the current progression while the sustain is being clipped.
		var clipProgression:Float = fullHeight - height;

		// Populate an array with incrementing heights.
		var splitFullHeight:Float = (fullHeight / this.subdivisions);
		var splitHeightProgression:Array<Float> = [for (i in 0...this.subdivisions) splitFullHeight + (i * splitFullHeight)];

		// Filter the array to only include heights that haven't been clipped yet.
		var progressionFiltered:Array<Float> = splitHeightProgression.filter((height:Float) ->
		{
			return height > clipProgression;
		});

		var progressionLength:Int = progressionFiltered.length;
		var clippedHeight:Float = progressionFiltered[0];

		// Populate an array with heights based on the filtered array.
		var splitHeights:Array<Float> = [for (i in 0...progressionLength) splitFullHeight];

		splitHeights[0] = clippedHeight - clipProgression;

		return splitHeights;
	}

	// Override the flipY setter function to make sure this sustain note updates in-case a user setting is changed.
	override function set_flipY(value:Bool)
	{
		super.set_flipY(value);
		updateClipping();

		return value;
	}
}