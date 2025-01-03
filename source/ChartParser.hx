package;

import Song;

import openfl.errors.Error;

import flixel.FlxG;
import flixel.util.FlxStringUtil;

using StringTools;

class ChartParser
{
	public static var totalColumns:Int = 4;

	public static function parseSongChart(songData:SwagSong, playbackRate:Float = 1):Array<Note>
	{
		var unspawnNotes:Array<Note> = [];

		for (section in songData.notes)
		{
			for (i in 0...section.sectionNotes.length)
			{
				final songNotes:Array<Dynamic> = section.sectionNotes[i];

				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3) {
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note = null;

				if (unspawnNotes.length > 0) {
					oldNote = unspawnNotes[unspawnNotes.length - 1];
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));

				if (songNotes[3] != null)
				{
					if (Std.isOfType(songNotes[3], String)) {
						swagNote.noteType = songNotes[3];
					}
					else {
						swagNote.noteType = Note.defaultNoteTypes[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
					}
				}

				swagNote.scrollFactor.set();
				unspawnNotes.push(swagNote);

				var middleScroll:Bool = ClientPrefs.middleScroll;

				if (PlayState.instance != null) {
					middleScroll = PlayState.instance.middleScroll;
				}

				final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);

				if (roundSus > 0)
				{
					for (susNote in 0...roundSus + 1)
					{
						oldNote = unspawnNotes[unspawnNotes.length - 1];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), swagNote.noteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));

						if (swagNote.noteType != null) {
							sustainNote.noteType = swagNote.noteType;
						}

						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);

						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						
						sustainNote.correctionOffset = swagNote.height / 2;

						if (!PlayState.isPixelStage)
						{
							if (oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if (ClientPrefs.downScroll) {
								sustainNote.correctionOffset = 0;
							}
						}
						else if (oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) {
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (middleScroll)
						{
							sustainNote.x += 310;

							if (daNoteData > 1) { // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress) {
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (middleScroll) //Up and Right
				{
					swagNote.x += 310;

					if (daNoteData > 1) {
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (PlayState.instance != null)
				{
					var noteTypes:Array<String> = PlayState.instance.noteTypes; // Fuck you HTML5

					if (!noteTypes.contains(swagNote.noteType)) {
						noteTypes.push(swagNote.noteType);
					}
				}

				oldNote = swagNote;
			}
		}

		return unspawnNotes;
	}

	public static function parseLudumChart(songName:String, section:Int):Array<Dynamic>
	{
		var IMG_WIDTH:Int = 8;
		var regex:EReg = new EReg("[ \t]*((\r\n)|\r|\n)[ \t]*", "g");

		var csvData = FlxStringUtil.imageToCSV(Paths.getFile('data/' + songName + '/' + songName + '_section' + section + '.png'));

		var lines:Array<String> = regex.split(csvData);
		var rows:Array<String> = lines.filter(function(line) return line != "");
		csvData.replace("\n", ',');

		var heightInTiles = rows.length;
		var widthInTiles = 0;

		var row:Int = 0;

		// LMAOOOO STOLE ALL THIS FROM FLXBASETILEMAP LOLOL

		var dopeArray:Array<Int> = [];
		while (row < heightInTiles)
		{
			var rowString = rows[row];
			if (rowString.endsWith(","))
				rowString = rowString.substr(0, rowString.length - 1);
			var columns = rowString.split(",");

			if (columns.length == 0)
			{
				heightInTiles--;
				continue;
			}
			if (widthInTiles == 0)
			{
				widthInTiles = columns.length;
			}

			var column = 0;
			var pushedInColumn:Bool = false;
			while (column < widthInTiles)
			{
				// the current tile to be added:
				var columnString = columns[column];
				var curTile = Std.parseInt(columnString);

				if (curTile == null)
					throw new Error('String in row $row, column $column is not a valid integer: "$columnString"');

				if (curTile == 1)
				{
					if (column < 4)
						dopeArray.push(column + 1);
					else
					{
						var tempCol = (column + 1) * -1;
						tempCol += 4;
						dopeArray.push(tempCol);
					}

					pushedInColumn = true;
				}

				column++;
			}

			if (!pushedInColumn)
				dopeArray.push(0);

			row++;
		}
		return dopeArray;
	}
}