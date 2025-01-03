package;

import haxe.Json;

import Song;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static function dummy():StageFile
	{
		return {
			directory: '',
			defaultZoom: 0.9,
			isPixelStage: false,

			boyfriend: [770, 100],
			girlfriend: [400, 130],
			opponent: [100, 100],
			hide_girlfriend: false,

			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		};
	}

	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong):Void
	{
		var stage:String = '';

		if (SONG.stage != null) {
			stage = SONG.stage;
		}
		else if (SONG.songID != null) {
			stage = vanillaSongStage(SONG.songID);
		}
		else {
			stage = 'stage';
		}

		var stageFile:StageFile = getStageFile(stage);

		if (stageFile == null) { // preventing crashes
			forceNextDirectory = '';
		}
		else {
			forceNextDirectory = stageFile.directory;
		}
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = 'stages/' + stage + '.json';

		if (Paths.fileExists(path, TEXT)) {
			rawJson = Paths.getTextFromFile(path);
		}

		if (rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}

		return null;
	}

	public static function vanillaSongStage(songID:String):String
	{
		switch (songID)
		{
			case 'spookeez' | 'south' | 'monster': return 'spooky';
			case 'pico' | 'blammed' | 'philly' | 'philly-nice': return 'philly';
			case 'milf' | 'satin-panties' | 'high': return 'limo';
			case 'cocoa' | 'eggnog': return 'mall';
			case 'winter-horrorland': return 'mallEvil';
			case 'senpai' | 'roses': return 'school';
			case 'thorns': return 'schoolEvil';
			case 'ugh' | 'guns' | 'stress': return 'tank';
			case 'darnell' | 'lit-up' | '2hot': return 'phillyStreets';
			case 'blazin': return 'phillyBlazin';
		}

		return 'stage';
	}
}