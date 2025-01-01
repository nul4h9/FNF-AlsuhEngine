package;

class Rating
{
	public var name:String = '';
	public var image:String = '';
	public var hitWindow:Null<Int> = 0; //ms
	public var ratingMod:Float = 1;
	public var healthDisabled:Bool = false;
	public var health:Float = 0.025;
	public var score:Int = 350;
	public var noteSplash:Bool = true;
	public var hits:Int = 0;

	public function new(name:String):Void
	{
		this.name = name;
		image = name;
		hitWindow = 0;

		var window:String = name + 'Window';

		try {
			hitWindow = Reflect.field(ClientPrefs, window);
		}
		catch (e:Dynamic) Debug.logError(e);
	}

	public static function loadDefault():Array<Rating>
	{
		var ratingsData:Array<Rating> = [new Rating('sick')]; // highest rating goes first

		var rating:Rating = new Rating('good');
		rating.ratingMod = 0.67;
		rating.score = 200;
		rating.noteSplash = false;
		rating.health = 0.015;
		ratingsData.push(rating);

		var rating:Rating = new Rating('bad');
		rating.ratingMod = 0.34;
		rating.score = 100;
		rating.noteSplash = false;
		rating.health = 0.010;
		ratingsData.push(rating);

		var rating:Rating = new Rating('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		rating.health = 0.005;
		ratingsData.push(rating);

		return ratingsData;
	}

	public static function fromListByName(ratingsData:Array<Rating>, name:String):Rating
	{
		for (i in ratingsData)
		{
			if (i.name == name) {
				return i;
			}
		}

		return null;
	}
}