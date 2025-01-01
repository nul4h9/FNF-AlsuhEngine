package;

import haxe.Json;

using StringTools;

typedef SwagSong =
{
	var songID:String;
	var songName:String;

	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	var ?disableNoteRGB:Bool;
	var ?arrowSkin:String;
	var ?splashSkin:String;
}

typedef SwagSection =
{
	var sectionNotes:Array<Array<Dynamic>>;
	var ?sectionBeats:Float;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Song
{
	private static function onLoadJson(songJson:Dynamic, ?isEvents:Bool = false):SwagSong // Convert old charts to newest format
	{
		var song:String = songJson.song;

		if (song != null)
		{
			if (songJson.songID == null) {
				songJson.songID = Paths.formatToSongPath(song);
			}
	
			if (songJson.songName == null) {
				songJson.songName = CoolUtil.formatToName(song);
			}
		}

		if (Reflect.hasField(songJson, 'song')) Reflect.deleteField(songJson, 'song');

		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');

		if (songJson.events == null)
		{
			songJson.events = [];
	
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Array<Dynamic>> = sec.sectionNotes;
				var len:Int = notes.length;

				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];

					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}
		
		if (!isEvents)
		{
			var sectionsData:Array<SwagSection> = songJson.notes;
			if (sectionsData == null) return null;
	
			for (section in sectionsData)
			{
				var beats:Null<Float> = cast section.sectionBeats;
	
				if (beats == null || Math.isNaN(beats))
				{
					section.sectionBeats = 4;
					if (Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
				}
			}
		}

		return cast songJson;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String = 'tutorial'):SwagSong
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		var file:String = Paths.getJson('data/' + formattedFolder + '/' + formattedSong);
		var rawJson:String = Paths.getTextFromFile(file);

		while (!rawJson.endsWith('}')) {
			rawJson = rawJson.substr(0, rawJson.length - 1); // LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var events:Bool = formattedSong == 'events';

		var songJson:Dynamic = parseJSONshit(rawJson);
		if (!events) StageData.loadDirectory(songJson);
		return onLoadJson(songJson, events);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}