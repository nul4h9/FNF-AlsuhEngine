package;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class MenuItem extends Sprite
{
	public static var DEFAULT_COLOR:FlxColor = 0xFF33ffff;

	public var targetY:Float = 0;
	public var itemColor:FlxColor = DEFAULT_COLOR;

	public function new(x:Float, y:Float, weekName:String = ''):Void
	{
		super(x, y);

		if (Paths.fileExists('images/storymenu/' + weekName + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('storymenu/' + weekName));
		}
		else if (Paths.fileExists('images/menuitems/' + weekName + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('menuitems/' + weekName));
		}
		else {
			loadGraphic(Paths.getImage('storymenu/menuitems/' + weekName));
		}
	}

	public var isFlashing:Bool = false;
	public var inEditor:Bool = false;

	private var isColored:Bool = false;

	public function startFlashing():Void
	{
		isFlashing = true;

		new FlxTimer().start(0.06, (tmr:FlxTimer) ->
		{
			isColored = !isColored;

			if (tmr.loops > 0 && tmr.loopsLeft == 0)
			{
				isFlashing = false;
				color = FlxColor.WHITE;
			}
		}, Std.int(2 / 0.06));
	}

	public function snapToPosition():Void
	{
		y = (targetY * 120) + 465;
	}

	override function update(elapsed:Float):Void
	{
		y = FlxMath.lerp((targetY * 120) + 465, y, Math.exp(-elapsed * 10.2));

		if (!inEditor)
		{
			if (isColored) {
				color = itemColor;
			}
			else if (ClientPrefs.flashingLights) {
				color = FlxColor.WHITE;
			}
		}

		super.update(elapsed);
	}
}