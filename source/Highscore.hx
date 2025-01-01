package;

import flixel.util.FlxSave;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songAccuracy:Map<String, Float> = new Map<String, Float>();

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = CoolUtil.formatSong(song, diff);

		setScore(daSong, 0);
		setAccuracy(daSong, 0);
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = CoolUtil.formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, ?diff:Int = 0, score:Int = 0, ?accuracy:Float = -1):Void
	{
		var daSong:String = CoolUtil.formatSong(song, diff);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
			{
				setScore(daSong, score);
				if (accuracy >= 0) setAccuracy(daSong, accuracy);
			}
		}
		else
		{
			setScore(daSong, score);
			if (accuracy >= 0) setAccuracy(daSong, accuracy);
		}
	}

	public static function saveWeekScore(week:String, ?diff:Int = 0, score:Int = 0):Void
	{
		var daWeek:String = CoolUtil.formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score) {
				setWeekScore(daWeek, score);
			}
		}
		else {
			setWeekScore(daWeek, score);
		}
	}

	static function setScore(song:String, score:Int):Void // YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	{
		songScores.set(song, score); // Reminder that I don't need to format this song, it should come formatted!

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());
		save.data.songScores = songScores;
		save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		weekScores.set(week, score); // Reminder that I don't need to format this song, it should come formatted!

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());
		save.data.weekScores = weekScores;
		save.flush();
	}

	static function setAccuracy(song:String, accuracy:Float):Void
	{
		songAccuracy.set(song, accuracy); // Reminder that I don't need to format this song, it should come formatted!

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());
		save.data.songAccuracy = songAccuracy;
		save.flush();
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = CoolUtil.formatSong(song, diff);

		if (!songScores.exists(daSong)) {
			setScore(daSong, 0);
		}

		return songScores.get(daSong);
	}

	public static function getAccuracy(song:String, diff:Int):Float
	{
		var daSong:String = CoolUtil.formatSong(song, diff);

		if (!songAccuracy.exists(daSong)) {
			setAccuracy(daSong, 0);
		}

		return songAccuracy.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = CoolUtil.formatSong(week, diff);

		if (!weekScores.exists(daWeek)) {
			setWeekScore(daWeek, 0);
		}

		return weekScores.get(daWeek);
	}

	public static function load():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());

		if (save.data.weekScores != null) {
			weekScores = save.data.weekScores;
		}

		if (save.data.songScores != null) {
			songScores = save.data.songScores;
		}

		if (save.data.songAccuracy != null) {
			songAccuracy = save.data.songAccuracy;
		}
	}
}