package;

import flixel.FlxSprite;

class AttachedAchievement extends Sprite
{
	public var sprTracker:FlxSprite;
	private var tag:String;

	public function new(x:Float = 0, y:Float = 0, name:String):Void
	{
		super(x, y);

		changeAchievement(name);
	}

	public function changeAchievement(tag:String, ?disableLock:Bool = false):Void
	{
		this.tag = tag;

		reloadAchievementImage(disableLock);
	}

	public function reloadAchievementImage(disableLock:Bool = false):Void
	{
		var antialias:Bool = true;

		if (disableLock)
		{
			if (Paths.fileExists('images/achievements/' + tag + '-pixel.png', IMAGE))
			{
				loadGraphic(Paths.getImage('achievements/' + tag + '-pixel'));
				antialias = false;
			}
			else if (Paths.fileExists('images/achievements/' + tag + '.png', IMAGE)){
				loadGraphic(Paths.getImage('achievements/' + tag));
			}
			else {
				loadGraphic(Paths.getImage('achievements/debugger'));
			}
		}
		else
		{
			if (Achievements.isUnlocked(tag))
			{
				if (Paths.fileExists('images/achievements/' + tag + '-pixel.png', IMAGE))
				{
					loadGraphic(Paths.getImage('achievements/' + tag + '-pixel'));
					antialias = false;
				}
				else if (Paths.fileExists('images/achievements/' + tag + '.png', IMAGE)){
					loadGraphic(Paths.getImage('achievements/' + tag));
				}
				else {
					loadGraphic(Paths.getImage('achievements/debugger'));
				}
			}
			else {
				loadGraphic(Paths.getImage('achievements/lockedachievement'));
			}
		}

		antialiasing = ClientPrefs.globalAntialiasing && antialias;

		scale.set(0.7, 0.7);
		updateHitbox();
	}

	override function update(elapsed:Float):Void
	{
		if (sprTracker != null) {
			setPosition(sprTracker.x - 130, sprTracker.y + 25);
		}

		super.update(elapsed);
	}
}