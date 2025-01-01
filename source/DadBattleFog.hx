package;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;

class DadBattleFog extends FlxTypedSpriteGroup<BGSprite>
{
	public function new():Void
	{
		super();

		alpha = 0;
		blend = ADD;

		var offsetX:Float = 200;

		var smoke:BGSprite = new BGSprite('smoke', -1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
		smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
		smoke.updateHitbox();
		smoke.velocity.x = FlxG.random.float(15, 22) * PlayState.instance.playbackRate;
		smoke.active = true;
		add(smoke);

		var smoke:BGSprite = new BGSprite('smoke', 1550 + offsetX, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
		smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
		smoke.updateHitbox();
		smoke.velocity.x = FlxG.random.float(-15, -22) * PlayState.instance.playbackRate;
		smoke.active = true;
		smoke.flipX = true;
		add(smoke);
	}
}