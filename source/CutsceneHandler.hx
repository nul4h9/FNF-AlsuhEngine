package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.util.FlxSort;

using StringTools;

class CutsceneHandler extends FlxBasic
{
	public var timedEvents:Array<Dynamic> = [];

	public var finishCallback:Void->Void = null;
	public var finishCallback2:Void->Void = null;

	public var onStart:Void->Void = null;
	public var endTime:Float = 0;
	public var objects:Array<FlxSprite> = [];
	public var music:String = null;

	public function new():Void
	{
		super();

		timer(0, function():Void
		{
			if (music != null)
			{
				FlxG.sound.playMusic(Paths.getMusic(music), 0, false);
				#if FLX_PITCH
				FlxG.sound.music.pitch = PlayState.instance.playbackRate;
				#end
				FlxG.sound.music.fadeIn();
			}

			if (onStart != null) onStart();
		});

		PlayState.instance.add(this);
	}

	private var cutsceneTime:Float = 0;
	private var firstFrame:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.state != PlayState.instance || !firstFrame)
		{
			firstFrame = true;
			return;
		}

		cutsceneTime += elapsed;

		if (endTime <= cutsceneTime)
		{
			finishCallback();
			if (finishCallback2 != null) finishCallback2();

			for (spr in objects)
			{
				spr.kill();
				PlayState.instance.remove(spr);
				spr.destroy();
			}

			kill();
			destroy();

			PlayState.instance.remove(this);
		}
		
		while (timedEvents.length > 0 && timedEvents[0][0] <= cutsceneTime)
		{
			timedEvents[0][1]();
			timedEvents.splice(0, 1);
		}
	}

	public function push(spr:FlxSprite):Void
	{
		objects.push(spr);
	}

	public function timer(time:Float, func:Void->Void):Void
	{
		timedEvents.push([time / PlayState.instance.playbackRate, func]);
		timedEvents.sort(sortByTime);
	}

	function sortByTime(obj1:Array<Dynamic>, obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1[0], obj2[0]);
	}
}