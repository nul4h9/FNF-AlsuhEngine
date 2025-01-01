package;

import flixel.FlxG;
import flixel.animation.FlxAnimationController;

using StringTools;

class SwagAnimationController extends FlxAnimationController
{
	public var followGlobalSpeed:Bool = true;

	public override function update(elapsed:Float):Void
	{
		if (_curAnim != null)
		{
			var speed:Float = timeScale;
			if (followGlobalSpeed) speed *= FlxG.animationTimeScale;
			_curAnim.update(elapsed * speed);
		}
		else if (_prerotated != null) {
			_prerotated.angle = _sprite.angle;
		}
	}
}