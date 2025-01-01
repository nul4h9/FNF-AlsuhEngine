package;

import flixel.FlxSprite;

class CheckboxThingie extends Sprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;

	public var copyAlpha:Bool = false;
	public var copyVisible:Bool = true;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked:Bool = false):Void
	{
		super(x, y);

		if (Paths.fileExists('images/ui/checkboxanim.png', IMAGE)) {
			frames = Paths.getSparrowAtlas('ui/checkboxanim');
		}
		else {
			frames = Paths.getSparrowAtlas('checkboxanim');
		}

		animation.addByPrefix('unchecked', 'checkbox0', 24, false);
		animation.addByPrefix('unchecking', 'checkbox anim reverse', 24, false);
		animation.addByPrefix('checking', 'checkbox anim0', 24, false);
		animation.addByPrefix('checked', 'checkbox finish', 24, false);

		setGraphicSize(Std.int(0.9 * width));
		updateHitbox();

		animationFinished(checked ? 'checking' : 'unchecking');
		animation.finishCallback = animationFinished;

		daValue = checked;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x - 130 + offsetX, sprTracker.y + 30 + offsetY);

			if (copyAlpha) {
				alpha = sprTracker.alpha;
			}

			if (copyVisible) {
				visible = sprTracker.visible;
			}
		}
	}

	private function set_daValue(check:Bool):Bool
	{
		daValue = check;

		if (daValue)
		{
			if (animation.curAnim.name != 'checked' && animation.curAnim.name != 'checking')
			{
				playAnim('checking', true);
				offset.set(34, 25);
			}
		}
		else if (animation.curAnim.name != 'unchecked' && animation.curAnim.name != 'unchecking')
		{
			playAnim('unchecking', true);
			offset.set(25, 28);
		}

		return check;
	}

	private function animationFinished(name:String):Void
	{
		switch (name)
		{
			case 'checking':
			{
				playAnim('checked', true);
				offset.set(3, 12);
			}
			case 'unchecking':
			{
				playAnim('unchecked', true);
				offset.set(0, 2);
			}
		}
	}
}