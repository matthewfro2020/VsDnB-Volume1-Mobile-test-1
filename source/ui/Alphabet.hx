package ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;

class ColumnData
{
	public var text:String = '';
	public var characters:Array<AlphaCharacter> = new Array<AlphaCharacter>();
	
	public function new() {}
	
	public function getCharAtIndex(textIndex:Int):AlphaCharacter
	{
		var index:Int = 0;
		for (i in 0...textIndex)
		{
			if (text.charAt(i) != ' ')
			{
				index++;
			}
		}
		return characters[index];
	}
}

class Alphabet extends FlxTypedSpriteGroup<AlphaCharacter>
{
	/**
	 * The default ease for when this sprite is being used as a menu item.
	 */
	public static var defaultEase:EaseFunction = FlxEase.circOut;

	/**
	 * The default time used for easing when this sprite is being used as a menu item.
	 */
	public static var defaultTime:Float = 0.3;

	/**
	 * The current font being used for this sprite. Defaults to the bold version.
	 */
	final font:FontData = new FontData('alphabet');

	/**
	 * The text that's currently being displayed within the sprite.
	 */
	public var text(default, set):String;

	function set_text(value:String):String 
	{
		if (this.text == value) return value;
		
		removeCharacters();

		appendText(value);
		return text = value;
	}

	/**
	 * The alignment of the text group.
	 */
	public var alignment(default, set):FlxTextAlign = FlxTextAlign.LEFT;

	function set_alignment(value:FlxTextAlign):FlxTextAlign
	{
		if (this.alignment == value) return alignment;
		
		this.alignment = value;
		updateColumns();
		return value;
	}

	/**
	 * Variable to be set if this sprite is being used as a menu item.
	 */
	public var isMenuItem:Bool;

	/**
	 * The group this alphabet belongs to if it's a menu item.
	 */
	public var menuItemGroup:Array<Alphabet>;

	/**
	 * The position index if this sprite is being used as a menu item.
	 */
	public var targetY:Float = 0;

	/**
	 * Used for when you want to offset the position of the sprite for when it's a menu item.
	 */
	public var positionOffset(default, null):FlxPoint = FlxPoint.get();

	/**
	 * Helper tween variable for when this sprite is a menu item.
	 */
	public var menuItemTween(default, null):FlxTween;

	/**
	 * Variable used to help customize the menu tween used for when this sprite is a menu item.
	 */
	public var menuTweenOptions:TweenOptions = {};

	/**
	 * Called when the sprite menu tween is complete.
	 */
	public var onMenuTweenComplete:FlxTween->Void;

	/**
	 * Variable used for when this sprite is being used as an option but you want to manipulate it's position.
	 */
	public var unlockY(default, set):Bool = false;

	function set_unlockY(value:Bool):Bool
	{
		unlockY = value;
		if (unlockY)
		{
			menuItemTween?.cancel();
			menuItemTween = null;
		}
		else
		{
			setupMenuTween(targetY);
		}
		return value;
	}

	/**
	 * The columns representing this sprite.
	 */
	var columns(default, null):Array<ColumnData> = [new ColumnData()];

	/**
	 * The current column index in this sprite.
	 */
	var column(default, null):Int = 0;

	/**
	 * The offset of the text based on how many columns there are.
	 */
	public var columnHeightOffset(get, never):Float;

	function get_columnHeightOffset():Float
	{
		return font.maxHeight * column;
	}
	
	/** 
	 * Helper variable used to track the base positions of each character. 
	 */
	public var positionMap(default, null):Map<AlphaCharacter, FlxPoint> = [];

	// Old vars for backwards compatbility
	
	public var groupX:Float = 90;
	public var groupY:Float = 0.48;

	public function new(x:Float, y:Float, ?text:String = '')
	{
		super(x, y);

		this.text = text;
	}

	function removeCharacters()
	{
		for (char in this.members)
		{
			remove(char);
		}
		clear();
		
		columns = [new ColumnData()];
		column = 0;
		positionMap = [];
	}

	function appendText(text:String)
	{
		var characters:Array<String> = text.split('');
		
		var charX:Float = 0;
		var charY:Float = 0;
		
		for (i in 0...characters.length)
		{
			var char:String = characters[i];

			switch (char)
			{
				case ' ':
					switch (alignment)
					{
						case LEFT:
							charX += font.spaceDifference;
						case CENTER:
							if (column < 1)
							{
								charX += font.spaceDifference;
							}
						case RIGHT: 
							charX += (column < 1) ? font.spaceDifference : -font.spaceDifference;
						default:
					}
					columns[column].text += ' ';
					
					updateColumns();
				case '\n':
					charX = switch (alignment)
					{
						case LEFT: 0;
						case CENTER: getHighestWidthColumn() / 2;
						case RIGHT: getHighestWidthColumn();
						default: 0;
					}
					charY += font.maxHeight;
					
					column++;
					columns.push(new ColumnData());
				case char:
					var charSprite:AlphaCharacter = new AlphaCharacter(char, font);
					
					charSprite.x = charX;
					charSprite.y = charY + (charSprite.font.maxHeight - charSprite.height);
					add(charSprite);
					
					columns[column].text += char;
					columns[column].characters.push(charSprite);

					updateColumns();

					var charOffsets:Array<Float> = charSprite.font.getCharOffsets(char);

					charSprite.x += charOffsets[0];
					charSprite.y += charOffsets[1];

					charX += charSprite.width + charOffsets[0];
					
					positionMap[charSprite] = FlxPoint.get(charSprite.x - this.x, charSprite.y - this.y);
			}
		}
	}

	function getColumnWidth(column:Int):Float
	{
		var width:Float = 0;
		var columnData:ColumnData = columns[column];

		var charIterator:Int = 0;
		
		for (character in columnData.text.split(''))
		{
			switch (character)
			{
				case ' ':
					width += font.spaceDifference;
				default:
					var char:AlphaCharacter = columnData.characters[charIterator];
					width += char.width;

					charIterator++;
			}
		}
		return width;
	}

	function getHighestWidthColumn():Float
	{
		var width:Float = 0;
		for (i in 0...columns.length)
		{
			var columnWidth:Float = getColumnWidth(i);

			width = Math.max(columnWidth, width);
		}
		return width;
	}

	/**
	 * Updates the column's text to match with the current alignment.
	 * @param columnId The column to update.
	 */
	function updateColumn(columnId:Int)
	{
		var columnData:ColumnData = columns[columnId];
		
		switch (alignment)
		{
			case CENTER:
				var centerChar:Int = Math.floor((columnData.characters.length - 1) / 2);

				if (column < 1 || columnData.characters.length <= 0) return;
				
				// Position the middle character of the column based on how many letters there are
				switch (columnData.characters.length)
				{
					case 1:
						columnData.characters[centerChar].x = (getHighestWidthColumn() - columnData.characters[centerChar].width) / 2 + this.x;
					default:
						columnData.characters[centerChar].x = switch (columnData.characters.length)
						{
							case (_ % 2 == 0) => true:
								this.x + (getHighestWidthColumn() / 2) - columnData.characters[centerChar].width;
							case (_ % 2 == 1) => true:
								this.x + (getHighestWidthColumn() - columnData.characters[centerChar].width) / 2;
								default: 0;
						}
						
						// Iterate backwards to the characters left from the middle character
						var iterator:Int = centerChar - 1;
						while (iterator >= 0)
						{
							columnData.characters[iterator].x = (columnData.characters[iterator + 1].x) - columnData.characters[iterator].width;
							iterator--;
						}
						
						// Iterate forwards to reposition the characters from the right side of the middle		
						for (i in centerChar + 1...columnData.characters.length)
						{
							columnData.characters[i].x = (columnData.characters[i - 1].x) + columnData.characters[i - 1].width;
						}
				}
				
				// Apply spaces
				for (i in 0...columnData.text.length)
				{
					if (columnData.text.charAt(i) == ' ')
					{
						var spaceType:String = "none";
						var spaceIterator:Int = i - 1;

						while (spaceIterator >= 0)
						{
							if (columnData.text.charAt(spaceIterator) != ' ')
							{
								spaceType = "left";
								break;
							}
							spaceIterator--;
						}
						
						for (j in i + 1...columnData.text.length)
						{
							if (columnData.text.charAt(j) != ' ')
							{
								if (spaceType == "left")
									spaceType = "both";
								else
									spaceType = "right";
									
								break;
							}
						}
						
						switch (spaceType)
						{
							case "left":
								for (char in columnData.characters)
								{
									char.x -= font.spaceDifference;
								}
							case "both":
								var spaceOccurance:Int = 1;
								
								var spaceIterator:Int = i - 1;
								while (spaceIterator >= 0)
								{
									if (columnData.text.charAt(spaceIterator) != ' ')
									{
										var char:AlphaCharacter = columnData.getCharAtIndex(spaceIterator);
										char.x -= font.spaceDifference / 2;
									}
									spaceIterator--;
								}
								
								spaceIterator = i + 1;
								for (j in spaceIterator...columnData.text.length)
								{
									if (columnData.text.charAt(j) != ' ')
									{
										var char:AlphaCharacter = columnData.getCharAtIndex(j);
										char.x += font.spaceDifference / 2;
									}
								}
							case "right":
								for (char in columnData.characters)
								{
									char.x += font.spaceDifference;
								}
						}
					}
				}
			case RIGHT:
				if (column < 1 || columnData.characters.length <= 0) return;
				
				columnData.characters[columnData.characters.length - 1].x = getHighestWidthColumn() - columnData.characters[columnData.characters.length - 1].width + this.x;
				
				var iterator:Int = (columnData.characters.length - 1) - 1;
				while (iterator >= 0)
				{
					columnData.characters[iterator].x = columnData.characters[iterator + 1].x - columnData.characters[iterator].width;
					iterator--;
				}
				
				// Apply Spaces
				var spaceType:String = "none";
				
				for (i in 0...columnData.text.length)
				{
					if (columnData.text.charAt(i) == ' ')
					{
						var spaceIterator:Int = i - 1;
						while (spaceIterator >= 0)
						{
							// Character exists on the left side.
							if (columnData.text.charAt(spaceIterator) != ' ')
							{
								spaceType = "left";
								break;
							}
							spaceIterator--;
						}
						
						for (j in i + 1...columnData.text.length)
						{
							// Character exists on the right side.
							if (columnData.text.charAt(j) != ' ')
							{
								// Characters only exist on the right side.
								if (spaceType == "none")
								{
									spaceType = "right";
									break;
								}
							}
						}
						
						switch (spaceType)
						{
							case "left":
								var spaceIterator:Int = i - 1;
								while (spaceIterator >= 0)
								{
									if (columnData.text.charAt(spaceIterator) != ' ')
									{
										var char:AlphaCharacter = columnData.getCharAtIndex(spaceIterator);
										char.x -= font.spaceDifference;
									}
									spaceIterator--;
								}
						}
					}
				}
			default:
		}
	}
	
	/**
	 * Iterates through each column to make sure each text is updated properly.
	 */
	public function updateColumns()
	{
		updateColumn(column);
		for (i in 0...columns.length)
		{
			if (i != column)
				updateColumn(i);
		}
	}

	/**
	 * Sets up the tween that moves the text group based on the current menu item selection.
	 * @param index The index of the text group.
	 */
	public function setupMenuTween(index:Float)
	{
		if (!isMenuItem || unlockY)
			return;

		var memberIndex:Int = menuItemGroup.indexOf(this);

		// This alphabet isn't in this array.
		if (memberIndex == -1)
			return;

		// Get the index of the current selected.
		var targetYIndex:Int = menuItemGroup.indexOf(menuItemGroup.filter((alphabet:Alphabet) -> 
		{
			return alphabet.targetY == 0;
		})[0]);

		if (targetYIndex == -1)
			return;

		var scaledY:Float = FlxMath.remapToRange(index, 0, 1, 0, 1.3);

		var newX:Float = targetY * 20 + groupX;
		var newY:Float = (scaledY * 120) + (FlxG.height * groupY);
		
		if (targetY != 0)
		{
			var totalColumnAddon:Float = 0;

			if (this.targetY > 0)
			{
				for (i in targetYIndex...memberIndex)
				{
					var m:Alphabet = menuItemGroup[i];
					totalColumnAddon += m.columnHeightOffset;
				}
			}
			else
			{
				totalColumnAddon -= columnHeightOffset;

				var iterator:Int = targetYIndex - 1;
				while (iterator > memberIndex)
				{
					var m:Alphabet = menuItemGroup[iterator];
					totalColumnAddon -= m.columnHeightOffset;

					iterator--;
				}
			}
			newY += totalColumnAddon;
		}

		menuItemTween?.cancel();
		menuItemTween = null;

		menuTweenOptions.ease = menuTweenOptions.ease ?? defaultEase;
		menuTweenOptions.onComplete = function(t:FlxTween) {
			if (onMenuTweenComplete != null)
				onMenuTweenComplete(t);

			menuItemTween?.cancel();
			menuItemTween = null;
		}
		menuItemTween = FlxTween.tween(this, {x: newX, y: newY}, defaultTime, menuTweenOptions);
	}

	public function forEachCharacter(func:AlphaCharacter->Void)
	{
		for (char in members)
		{
			if (char != null)
				func(char);
		}
	}
	
	override function get_width():Float
	{
		return getHighestWidthColumn();
	}
	
	// NOTE: Not an accurate represenation of the "height", a better way would be to get the sum of the tallest character of each column.
	override function get_height():Float
	{
		return font.maxHeight * (column + 1);
	}
}

class AlphaCharacter extends FlxSprite
{
	public var font:FontData;
	public var char(default, set):String;
	
	public function new(char:String, font:FontData)
	{
		super(0.0, 0.0);

		this.font = font;
		this.frames = font.atlas;
		this.char = char;
	}

	function loadChar(char:String)
	{
		animation.destroyAnimations();

		var prefix:String = font.getAnimPrefix(char);

		animation.addByPrefix('idle', prefix, 24);
		animation.play('idle', true);
	}

	function set_char(value:String):String 
	{
		if (char == value) return value;
		loadChar(value);
		return char = value;
	}
}

class FontData
{
	/**
	 * The TextureAtlas frames associated with this font. 
	 */
	public var atlas(default, null):FlxAtlasFrames;

	/**
	 * The max height of the font. Calculated when the font is loaded. 
	 */
	public var maxHeight(default, null):Float = 0.0;

	/**
	 * The amount of pixels the space key is worth for this font.
	 */
	public var spaceDifference:Float = 40;

	public function new(font:String)
	{
		atlas = Paths.getSparrowAtlas(font.toLowerCase());
		atlas.parent.destroyOnNoUse = false;
		atlas.parent.persist = true;

		for (frame in atlas.frames)
		{
			maxHeight = Math.max(maxHeight, frame.frame.height);
		}
	}

	/**
	 * Gets the position offsets for a character.
	 * @param char The character to get the position offsets for.
	 * @return The position offsets for this char.
	 */
	public function getCharOffsets(char:String):Array<Float>
	{
		return switch (char)
		{
			case '-': [0.0, 28.0];
			case 'ó': [0.0, -25.0];
			case 'ú': [10.0, -18.0];
			case 'õ': [0.0, -20.0];
			case 'á': [0.0, -17.0];
			default: [0.0, 0.0];
		}
	}

	/**
	  * Gets the animation prefix for the associated character.
	  * @param char The character to get the animation prefix for.
	  * @return The name of the animation prefix for this character.
	 */
	public function getAnimPrefix(char:String):String
	{
		return switch (char) {
			case "'": 'APOSTRAPHIE bold';
			case '"': "END PARENTHESES bold";
			case '""': 'start parentheses';
			case '!': 'EXCLAMATION POINT bold';
			case '.': 'PERIOD bold';
			case '?': 'QUESTION MARK bold0';

			case '&': 'bold &';
			case '(': 'bold (';
			case ')': 'bold )';
			case '*': 'bold *';
			case '+': 'bold +';
			case '-': 'bold -';
			case '<': 'bold <';
			case '>': 'bold >';
			case '^': 'bold ^';
			case '~': 'bold ~';

			case '0': 'bold0';
			case '1': 'bold1';
			case '2': 'bold2';
			case '3': 'bold3';
			case '4': 'bold4';
			case '5': 'bold5';
			case '6': 'bold6';
			case '7': 'bold7';
			case '8': 'bold8';
			case '9': 'bold9';
			
			case '¿': 'QUESTION MARK bold FLIPPED0';
			case 'É', 'è': 'Eaccent1bold';
			case '¡': 'exclamation point FLIPPED';

			default: char.toUpperCase() + ' bold';
		}
	}
}