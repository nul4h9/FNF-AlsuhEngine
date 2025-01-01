package;

import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;

using StringTools;

class ComboNumberSprite extends Sprite
{
	public var number:Int = 0;
	public var group:FlxTypedGroup<ComboNumberSprite>;

	public function new(x:Float = 0, y:Float = 0):Void
	{
		super(x, y);
	}

	public function resetSprite(x:Float = 0, y:Float = 0, number:Int = 0, ?suffix:String):Void
	{
		setPosition(x, y);

		this.number = number;
		reloadImage(number, suffix);

		antialiasing = ClientPrefs.globalAntialiasing && !PlayState.isPixelStage;

		setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : 0.5)));
		updateHitbox();
	}

	public function reloadImage(number:Int, ?suffix:String):Void
	{
		if ((suffix == null || suffix.trim().length < 1) && PlayState.isPixelStage) suffix = '-pixel';

		var instance:String = 'num' + number;
		var path:String = 'ui/' + instance;

		if (suffix != null && suffix.length > 0)
		{
			path += suffix;
			var pathShit:String = instance + suffix;

			if (Paths.fileExists('images/pixelUI/' + pathShit + '.png', IMAGE) && PlayState.isPixelStage) {
				path = 'pixelUI/' + pathShit;
			}
			else if (Paths.fileExists('images/' + pathShit + '.png', IMAGE)) {
				path = pathShit;
			}
		}
		else
		{
			if (Paths.fileExists('images/pixelUI/' + instance + '.png', IMAGE) && PlayState.isPixelStage) {
				path = 'pixelUI/' + instance;
			}
			else if (Paths.fileExists('images/' + instance + '.png', IMAGE)) {
				path = instance;
			}
		}

		loadGraphic(Paths.getImage(path));
	}

	public function reoffset():Void
	{
		var offset:Array<Int> = ClientPrefs.comboOffset.copy();
		setPosition(x + offset[2], y - offset[3]);
	}

	var _disappearTween:FlxTween;

	public function disappear():Void
	{
		var playbackRate:Float = 1;

		if (PlayState.instance != null) {
			playbackRate = PlayState.instance.playbackRate;
		}

		acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		velocity.set(FlxG.random.float(-5, 5) * playbackRate, velocity.y - (FlxG.random.int(140, 160) * playbackRate));

		_disappearTween = FlxTween.tween(this, {alpha: 0}, 0.2 / playbackRate,
		{
			startDelay: Conductor.crochet * 0.002 / playbackRate,
			onComplete: function(twn:FlxTween):Void
			{
				try
				{
					kill();
					if (group != null) group.remove(this, true);
				}
				catch (_:Dynamic) {
					if (group != null) group.remove(this, true);
				}
			}
		});
	}

	override function destroy():Void
	{
		if (!destroyed)
		{
			if (_disappearTween != null)
			{
				_disappearTween.cancel();
				_disappearTween = null;
			}

			super.destroy();
		}
	}

	override function set_active(value:Bool):Bool
	{
		if (_disappearTween != null) _disappearTween.active = value;
		return super.set_active(value);
	}
}