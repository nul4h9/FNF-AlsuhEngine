package debug;

import haxe.Timer;
import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxStringUtil;

#if openfl
import openfl.system.System;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", 14, color);
		autoSize = LEFT;
		multiline = true;

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	private override function __enterFrame(deltaTime:Float):Void
	{
		if (deltaTimeout > 1000)
		{
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = Timer.stamp() * 1000;
		times.push(now);

		while (times[0] < now - 1000) times.shift();

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();

		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void // so people can override it in hscript
	{
		text = '';

		if (ClientPrefs.fpsCounter) text = 'FPS: ${currentFPS}\n';
		if (ClientPrefs.memoryCounter) text += 'Memory: ' + FlxStringUtil.formatBytes(memoryMegas);

		textColor = 0xFFFFFFFF;

		if (currentFPS < FlxG.drawFramerate * 0.5) {
			textColor = 0xFFFF0000;
		}
	}

	inline function get_memoryMegas():Float
	{
		return cast (System.totalMemory, UInt);
	}
}