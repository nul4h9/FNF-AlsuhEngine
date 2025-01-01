package;

import flixel.FlxG;
import flixel.math.FlxAngle;

class BackgroundTank extends BGSprite
{
	public var offsetX:Float = 400;
	public var offsetY:Float = 1300;
	public var tankSpeed:Float = 0;
	public var tankAngle:Float = 0;

	public function new():Void
	{
		super('tankRolling', 0, 0, 0.5, 0.5, ['BG tank w lighting'], true);

		tankSpeed = FlxG.random.float(5, 7);
		tankAngle = FlxG.random.int(-90, 45);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var daAngleOffset:Float = 1;
		tankAngle += elapsed * tankSpeed * PlayState.instance.playbackRate;

		angle = tankAngle - 90 + 15;

		var ourRadians:Float = FlxAngle.asRadians((tankAngle * daAngleOffset) + 180);
		setPosition(offsetX + Math.cos(ourRadians) * 1500, offsetY + Math.sin(ourRadians) * 1100);
	}
}