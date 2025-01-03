package;

import Song;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	var ?stepCrochet:Float;
}

class Conductor
{
	public static var bpm(default, set):Float = 100;
	public static var crochet:Float = calculateCrochet(bpm); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float = 0;
	public static var offset:Float = 0;
	public static var safeZoneOffset:Float = 0; // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static function judgeNote(arr:Array<Rating> = null, diff:Float = 0):Rating // die
	{
		if (arr == null || arr.length < 1) arr = Rating.loadDefault();
		var data:Array<Rating> = arr;

		for (i in 0...data.length - 1) //skips last window (Shit)
		{
			if (diff <= data[i].hitWindow) {
				return data[i];
			}
		}

		return data[data.length - 1];
	}

	public static function getCrotchetAtTime(time:Float):Float
	{
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		}

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.bpmChangeMap[i].stepTime <= step) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		return lastChange;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step:Float = beat * 4;
		var lastChange:BPMChangeEvent = getBPMFromStep(step);

		return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000; // TODO: make less shit and take BPM into account PROPERLY
	}

	public static function getStep(time:Float):Float
	{
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float):Float
	{
		var lastChange:BPMChangeEvent = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float):Float
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStepRounded(time) / 4);
	}

	public static function mapBPMChanges(song:SwagSong):Void
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;

		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM == true && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = Math.round(getSectionBeats(song, i) * 4);
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}

		Debug.logInfo("new BPM map BUDDY " + bpmChangeMap);
	}

	static function getSectionBeats(song:SwagSong, section:Int):Float
	{
		if (song.notes[section] != null && song.notes[section].sectionBeats != null && song.notes[section].sectionBeats > 0) {
			return song.notes[section].sectionBeats;
		}

		return 4;
	}

	public static function calculateCrochet(bpm:Float):Float
	{
		return (60 / bpm) * 1000;
	}

	inline static function set_bpm(value:Float):Float
	{
		crochet = calculateCrochet(value);
		stepCrochet = crochet / 4;

		return bpm = value;
	}
}