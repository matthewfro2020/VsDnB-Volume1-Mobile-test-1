package graphics.audio;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.sound.FlxSound;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BlendMode;

class SpectralAnalyzerLite {
    public var minFreq:Float = 0;
    public var maxFreq:Float = 20000;
    public var fftN:Int = 512;

    public function new() {}

    public function getLevels():Array<{ value:Float, peak:Float }> {
        return [];
    }
}

typedef VisualizerParams = {
    var barCount:Int;
    var width:Int;
    var height:Int;
    var spacing:Int;
    var peakLines:Bool;
    var color:FlxColor;
    var ?minFrequency:Float;
    var ?maxFrequency:Float;
    var ?peakColor:FlxColor;
    var ?gradient:Array<FlxColor>;
}

class SpectrogramVisualizer extends FlxSpriteGroup {
	public var analyzer:SpectralAnalyzerLite = new SpectralAnalyzerLite();
	public var bars:FlxSpriteGroup = new FlxSpriteGroup();
	public var peakLines:FlxSpriteGroup = new FlxSpriteGroup();
	public var sound:FlxSound;
	public var visualizerColor:FlxColor = FlxColor.WHITE;
	public var peakColor:FlxColor = FlxColor.WHITE;
	public var havePeakLines:Bool = true;
	public var gradientColor:Array<FlxColor>;
	public var blendMode:BlendMode;
	public var visualizerWidth:Int;
	public var visualizerHeight:Int;
	var barCount:Int;

	public function new(params:VisualizerParams) {
		super();
		this.barCount = params.barCount;
		this.visualizerWidth = params.width;
		this.visualizerHeight = params.height;

		add(bars);
		add(peakLines);

		generateLines(params.barCount, visualizerWidth, visualizerHeight, params.spacing);
		generatePeakLines(params.barCount, params.width, params.spacing);

		if (params.gradient != null)
			gradientColor = params.gradient;
		else
			visualizerColor = params.color;

		this.peakColor = params.peakColor ?? params.color;
		this.havePeakLines = params.peakLines;
	}

	public function start(sound:FlxSound) {
		this.sound = sound;
		analyzer.minFreq = 20;
		analyzer.maxFreq = 16000;
	}

	public function stop() {
		sound = null;
	}

	override function draw() {
		if (sound != null) {
			var levels = analyzer.getLevels();
		}
		super.draw();
	}

	function generateLines(barCount:Int, width:Int, height:Int, spacing:Int) {
		for (i in 0...barCount) {
			var spr = new FlxSprite((i / barCount) * width, 0)
				.makeGraphic(Std.int((1 / barCount) * width) - spacing, height, FlxColor.WHITE);
			spr.origin.set(0, spr.height);
			bars.add(spr);
		}
	}

	function generatePeakLines(barCount:Int, width:Int, spacing:Int) {
		for (i in 0...barCount) {
			var spr = new FlxSprite((i / barCount) * width, 0)
				.makeGraphic(Std.int((1 / barCount) * width) - spacing, 1, FlxColor.WHITE);
			peakLines.add(spr);
		}
	}
}
