package;

class BGSprite extends Sprite
{
	private var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, ?scrollX:Float = 1, ?scrollY:Float = 1, ?animArray:Array<String> = null, ?loop:Bool = false):Void
	{
		super(x, y);

		if (animArray != null)
		{
			frames = Paths.getSparrowAtlas(image);

			for (i in 0...animArray.length)
			{
				var anim:String = animArray[i];
				animation.addByPrefix(anim, anim, 24, loop);

				if (idleAnim == null)
				{
					idleAnim = anim;
					playAnim(anim);
				}
			}
		}
		else
		{
			if (image != null) {
				loadGraphic(Paths.getImage(image));
			}

			active = false;
		}

		scrollFactor.set(scrollX, scrollY);
	}

	public function dance(?forceplay:Bool = false):Void
	{
		if (idleAnim != null) {
			playAnim(idleAnim, forceplay);
		}
	}
}