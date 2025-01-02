package editors;

import haxe.Json;
import haxe.io.Path;
import haxe.io.Bytes;

import Song;
import Conductor;
import Character;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import openfl.media.Sound;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxSort;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.sound.FlxSound;
import openfl.geom.Rectangle;
import flixel.tweens.FlxTween;
import flixel.addons.ui.FlxUI;
import lime.media.AudioBuffer;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUISlider;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.display.FlxGridOverlay;

using StringTools;

class ChartingState extends MusicBeatState
{
	var ignoreWarnings:Bool = false;
	var curNoteTypes:Array<String> = [];

	var eventStuff:Array<Dynamic> =
	[
		['', "Nothing. Yep, that's right."],
		['Dad Battle Spotlight', "Used in Dad Battle,\nValue 1: 0/1 = ON/OFF,\n2 = Target Dad\n3 = Target BF"],
		['Hey!', "Plays the \"Hey!\" animation from Bopeebo,\nValue 1: BF = Only Boyfriend, GF = Only Girlfriend,\nSomething else = Both.\nValue 2: Custom animation duration,\nleave it blank for 0.6s"],
		['Set GF Speed', "Sets GF head bopping speed,\nValue 1: 1 = Normal speed,\n2 = 1/2 speed, 4 = 1/4 speed etc.\nUsed on Fresh during the beatbox parts.\n\nWarning: Value must be integer!"],
		['Philly Glow', "Exclusive to Week 3\nValue 1: 0/1/2 = OFF/ON/Reset Gradient\n \nNo, i won't add it to other weeks."],
		['Kill Henchmen', "For Mom's songs"],
		['Add Camera Zoom', "Used on M.I.L.F on that one \"Hard\" part\nValue 1: Camera zoom add (Default: 0.015)\nValue 2: UI zoom add (Default: 0.03)\nLeave the values blank if you want to use Default."],
		['BG Freaks Expression', "Should be used only in \"school\" Stage!"],
		['Trigger BG Ghouls', "Should be used only in \"schoolEvil\" Stage!"],
		['Pico Speaker Shoot', "Shound be used only in \"pico-speaker\" GF version and \"tank\" Stage!\n\nValue 1: Left = 1, Right = 2"],
		['Play Animation', "Plays an animation on a Character,\nonce the animation is completed,\nthe animation changes to Idle\n\nValue 1: Animation to play.\nValue 2: Character (Dad, BF, GF)"],
		['Camera Follow Pos', "Value 1: X\nValue 2: Y\n\nThe camera won't change the follow point\nafter using this, for getting it back\nto normal, leave both values blank."],
		['Alt Idle Animation', "Sets a specified suffix after the idle animation name.\nYou can use this to trigger 'idle-alt' if you set\nValue 2 to -alt\n\nValue 1: Character to set (Dad, BF or GF)\nValue 2: New suffix (Leave it blank to disable)"],
		['Screen Shake', "Value 1: Camera shake\nValue 2: HUD shake\n\nEvery value works as the following example: \"1, 0.05\".\nThe first number (1) is the duration.\nThe second number (0.05) is the intensity."],
		['Change Character', "Value 1: Character to change (Dad, BF, GF)\nValue 2: New character's name"],
		['Change Scroll Speed', "Value 1: Scroll Speed Multiplier (1 is default)\nValue 2: Time it takes to change fully in seconds."],
		['Set Property', "Value 1: Variable name\nValue 2: New value"],
		['Call Method', "Value 1: Function name\nValue 2: Arguments of function (with a ', ' between\nthe values)"],
		['Play Sound', "Value 1: Sound file name\nValue 2: Volume (Default: 1), ranges from 0 to 1"],
		['Set Camera Zoom', "Value 1: New camera zoom\n(Default: Stage Camera Zoom)"],
		['Set Camera Speed', "Value 1: New camera speed\n(Default: Stage Camera Speed)"],
		['Move Camera', "Value 1: Target (Dad, GF, BF)\n\nIf empty, camera moves to\ncharacter by current section."],
		['Camera Flash', "Value 1: Arguments - Camera, Duration\nExample: \"game, 1\"\n\nValue 2: Color"],
		['Camera Fade', "Value 1: Arguments - Camera, Duration, Fade in (bool-\nean value)\nExample: \"game, 1, true\"\n\nValue 2: Color"]
	];

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	var _song:SwagSong;
	var _file:FileReference;

	public static var GRID_SIZE:Int = 40;
	var CAM_OFFSET:Int = 360;

	var UI_box:FlxUITabMenu;

	public static var curSec:Int = 0;
	public static var lastSection:Int = 0;

	var bpmTxt:FlxText;
	var strumLine:Sprite;
	var quant:AttachedSprite;

	var dummyArrow:Sprite;

	var strumLineNotes:FlxTypedGroup<StrumNote>;

	var curRenderedSustains:FlxTypedGroup<Sprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedNoteType:FlxTypedGroup<FlxText>;

	var nextRenderedSustains:FlxTypedGroup<Sprite>;
	var nextRenderedNotes:FlxTypedGroup<Note>;

	var gridBG:FlxSprite;
	var nextGridBG:FlxSprite;

	var gridMult:Int = 2;

	var daquantspot = 0;

	var curEventSelected:Int = 0;
	var curSelectedNote:Array<Dynamic> = null;

	var playbackSpeed:Float = 1;

	var vocals:FlxSound;
	var opponentVocals:FlxSound;
	var hasOpponentVocals:Bool = false;

	var zoomTxt:FlxText;
	var curZoom:Int = 1;

	var zoomList:Array<Float> = [
		0.5,
		1,
		2,
		4,
		8,
		12,
		16,
		24
	];

	var camPos:FlxObject;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	var value1InputText:FlxUIInputText;
	var value2InputText:FlxUIInputText;
	var currentSongName:String;

	private static var lastSong:String = '';

	var waveformSprite:FlxSprite;
	var gridLayer:FlxTypedGroup<FlxSprite>;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	public var quantizations:Array<Int> = [
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	var text:String = '';

	public var mouseQuant:Bool = false;
	public static var vortex:Bool = false;

	override function create():Void
	{
		if (PlayState.SONG != null) {
			_song = PlayState.SONG;
		}
		else
		{
			CoolUtil.resetDifficulties();

			_song = {
				songID: 'test',
				songName: 'Test',
				notes: [],
				events: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				stage: 'stage',
				speed: 1
			};

			addSection();
			PlayState.SONG = _song;
		}

		vortex = FlxG.save.data.chart_vortex;
		ignoreWarnings = FlxG.save.data.ignoreWarnings;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", _song.songName); // Updating Discord Rich Presence
		#end

		curSec = lastSection;

		var bg:Sprite = new Sprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.scrollFactor.set();
		bg.color = 0xFF222222;
		add(bg);

		gridLayer = new FlxTypedGroup<FlxSprite>();
		add(gridLayer);

		waveformSprite = new Sprite(GRID_SIZE, 0);
		waveformSprite.makeGraphic(FlxG.width, FlxG.height, 0x00FFFFFF);
		add(waveformSprite);

		var eventIcon:Sprite = new Sprite(-GRID_SIZE - 5, -90);
		if (Paths.fileExists('images/eventArrow.png', IMAGE)) {
			eventIcon.loadGraphic(Paths.getImage('eventArrow'));
		}
		else {
			eventIcon.loadGraphic(Paths.getImage('ui/eventArrow'));
		}
		eventIcon.scrollFactor.set(1, 1);
		eventIcon.setGraphicSize(30, 30);
		add(eventIcon);

		leftIcon = new HealthIcon('bf');
		leftIcon.scrollFactor.set(1, 1);
		leftIcon.setGraphicSize(0, 45);
		leftIcon.setPosition(GRID_SIZE + 10, -100);
		add(leftIcon);

		rightIcon = new HealthIcon('dad');
		rightIcon.scrollFactor.set(1, 1);
		rightIcon.setGraphicSize(0, 45);
		rightIcon.setPosition(GRID_SIZE * 5.2, -100);
		add(rightIcon);

		curRenderedSustains = new FlxTypedGroup<Sprite>();
		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedNoteType = new FlxTypedGroup<FlxText>();

		nextRenderedSustains = new FlxTypedGroup<Sprite>();
		nextRenderedNotes = new FlxTypedGroup<Note>();

		if (curSec >= _song.notes.length) curSec = _song.notes.length - 1;

		FlxG.mouse.visible = !controls.controllerMode;

		addSection();

		updateJsonData();
		currentSongName = Paths.formatToSongPath(_song.songID);

		loadSong();
		reloadGridLayer();

		Conductor.bpm = _song.bpm;
		Conductor.mapBPMChanges(_song);

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new Sprite(0, 50);
		strumLine.makeGraphic(Std.int(GRID_SIZE * 9), 4);
		add(strumLine);

		var ourShit:String = 'ui/chart_quant';

		if (Paths.fileExists('images/chart_quant.png', IMAGE)) {
			ourShit = 'chart_quant';
		}

		quant = new AttachedSprite(ourShit, 'chart_quant');
		quant.animation.addByPrefix('q', 'chart_quant', 0, false);
		quant.playAnim('q', true, false, 0);
		quant.sprTracker = strumLine;
		quant.xAdd = -32;
		quant.yAdd = 8;
		add(quant);

		strumLineNotes = new FlxTypedGroup<StrumNote>();

		for (i in 0...Math.floor(Note.pointers.length * 2))
		{
			var note:StrumNote = new StrumNote(GRID_SIZE * (i + 1), strumLine.y, i % Note.Note.pointers.length, 0);
			note.setGraphicSize(GRID_SIZE, GRID_SIZE);
			note.updateHitbox();
			note.playAnim('static', true);
			strumLineNotes.add(note);
			note.scrollFactor.set(1, 1);
		}

		add(strumLineNotes);

		camPos = new FlxObject(0, 0, 1, 1);
		camPos.setPosition(strumLine.x + CAM_OFFSET, strumLine.y);

		dummyArrow = new Sprite();
		dummyArrow.makeGraphic(GRID_SIZE, GRID_SIZE);
		add(dummyArrow);

		var tabs = [
			{name: "Song", label: 'Song'},
			{name: "Section", label: 'Section'},
			{name: "Note", label: 'Note'},
			{name: "Events", label: 'Events'},
			{name: "Assets", label: 'Assets'},
			{name: "Charting", label: 'Charting'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(300, 400);
		UI_box.setPosition(640 + GRID_SIZE / 2, 25);
		UI_box.scrollFactor.set();

		text = "W/S or Mouse Wheel - Change Conductor's strum time
			\nA/D - Go to the previous/next section
			\nLeft/Right - Change Snap
			\nUp/Down - Change Conductor's Strum Time with Snapping" +
			#if FLX_PITCH
			"\nLeft Bracket / Right Bracket - Change Song Playback Rate (SHIFT to go Faster)
			\nALT + Left Bracket / Right Bracket - Reset Song Playback Rate" +
			#end
			"\nHold Shift to move 4x faster
			\nHold Control and click on an arrow to select it
			\nZ/X - Zoom in/out
			\n
			\nEsc - Test your chart inside Chart Editor
			\nEnter - Play your chart
			\nQ/E - Decrease/Increase Note Sustain Length
			\nSpace - Stop/Resume song";

		var tipTextArray:Array<String> = text.split('\n');

		for (i in 0...tipTextArray.length)
		{
			var tipText:FlxText = new FlxText(UI_box.x, UI_box.y + UI_box.height + 8, 0, tipTextArray[i], 16);
			tipText.y += i * 12;
			tipText.setFormat(Paths.getFont('vcr.ttf'), 14, FlxColor.WHITE, LEFT);
			tipText.scrollFactor.set();
			add(tipText);
		}

		add(UI_box);

		addAssets();
		addChartingUI();
		addEventsUI();
		addNoteUI();
		addSectionUI();
		addSongUI();
		updateHeads();
		updateWaveform();

		if (lastSong != currentSongName) {
			changeSection();
		}

		lastSong = currentSongName;

		zoomTxt = new FlxText(10, 10, 0, "Zoom: 1x", 16);
		zoomTxt.scrollFactor.set();
		add(zoomTxt);

		add(curRenderedSustains);
		add(curRenderedNotes);
		add(curRenderedNoteType);
		add(nextRenderedSustains);
		add(nextRenderedNotes);

		updateGrid();
		super.create();
	}

	function addAssets():Void
	{
		var tab_group_assets:FlxUI = new FlxUI(null, UI_box);
		tab_group_assets.name = "Assets";

		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('characters/'), Paths.mods(Paths.currentModDirectory + '/characters/'), Paths.getPreloadPath('characters/')];

		for (mod in Paths.globalMods) {
			directories.push(Paths.mods(mod + '/characters/'));
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath('characters/')];
		#end

		var tempArray:Array<String> = [];
		var characters:Array<String> = Paths.mergeAllTextsNamed('data/characterList.txt', Paths.getPreloadPath());

		for (i in 0...characters.length) {
			tempArray.push(characters[i]);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) 
		{
			var directory:String = directories[i];
		
			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);
				
					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var charToCheck:String = file.substr(0, file.length - 5);
				
						if (charToCheck.trim().length > 0 && !charToCheck.endsWith('-dead') && !tempArray.contains(charToCheck))
						{
							tempArray.push(charToCheck);
							characters.push(charToCheck);
						}
					}
				}
			}
		}
		#end

		var player1DropDown = new FlxUIDropDownMenu(10, 50, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String):Void
		{
			_song.player1 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});

		player1DropDown.selectedLabel = _song.player1;
		blockPressWhileScrolling.push(player1DropDown);

		var player2DropDown = new FlxUIDropDownMenu(170, player1DropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String):Void
		{
			_song.player2 = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});

		player2DropDown.selectedLabel = _song.player2;
		blockPressWhileScrolling.push(player2DropDown);

		var gfVersionDropDown = new FlxUIDropDownMenu(10, player2DropDown.y + 75, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String):Void
		{
			_song.gfVersion = characters[Std.parseInt(character)];
			updateJsonData();
			updateHeads();
		});

		gfVersionDropDown.selectedLabel = _song.gfVersion;
		blockPressWhileScrolling.push(gfVersionDropDown);
	
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods('stages/'), Paths.mods(Paths.currentModDirectory + '/stages/'), Paths.getPreloadPath('stages/')];

		for (mod in Paths.globalMods) {
			directories.push(Paths.mods(mod + '/stages/'));
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath('stages/')];
		#end

		var stageFile:Array<String> = Paths.mergeAllTextsNamed('data/stageList.txt', Paths.getPreloadPath());
		var stages:Array<String> = [];

		for (stage in stageFile)
		{
			if (stage.trim().length > 0) {
				stages.push(stage);
			}

			tempArray.push(stage);
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i];

			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);

					if (!FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						var stageToCheck:String = file.substr(0, file.length - 5);

						if (stageToCheck.trim().length > 0 && !tempArray.contains(stageToCheck))
						{
							tempArray.push(stageToCheck);
							stages.push(stageToCheck);
						}
					}
				}
			}
		}
		#end

		if (stages.length < 1) stages.push('stage');

		var stageDropDown = new FlxUIDropDownMenu(170, gfVersionDropDown.y, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(character:String):Void {
			_song.stage = stages[Std.parseInt(character)];
		});

		stageDropDown.selectedLabel = _song.stage;
		blockPressWhileScrolling.push(stageDropDown);

		var check_disableNoteRGB:FlxUICheckBox = new FlxUICheckBox(10, gfVersionDropDown.y + 35, null, null, "Disable\nNote RGB", 100);
		check_disableNoteRGB.checked = (_song.disableNoteRGB == true);
		check_disableNoteRGB.callback = function():Void
		{
			_song.disableNoteRGB = check_disableNoteRGB.checked;
			updateGrid();
		}

		var skin = PlayState.SONG.arrowSkin;
		if (skin == null) skin = '';

		noteSkinInputText = new FlxUIInputText(10, stageDropDown.y + 85, 150, skin, 8);
		blockPressWhileTypingOn.push(noteSkinInputText);
	
		noteSplashesInputText = new FlxUIInputText(10, noteSkinInputText.y + 40, 150, _song.splashSkin, 8);
		blockPressWhileTypingOn.push(noteSplashesInputText);

		var reloadNotesButton:FlxButton = new FlxButton(200, noteSplashesInputText.y, 'Change Notes', function():Void
		{
			_song.arrowSkin = noteSkinInputText.text;
			updateGrid();
		});

		tab_group_assets.add(new FlxText(noteSkinInputText.x, noteSkinInputText.y - 20, 0, "Notes's Texture"));
		tab_group_assets.add(noteSkinInputText);
		tab_group_assets.add(new FlxText(noteSplashesInputText.x, noteSplashesInputText.y - 20, 0, "Note Splashes's Texture"));
		tab_group_assets.add(noteSplashesInputText);

		tab_group_assets.add(check_disableNoteRGB);
		tab_group_assets.add(reloadNotesButton);

		tab_group_assets.add(new FlxText(gfVersionDropDown.x, gfVersionDropDown.y - 20, 200, 'Girlfriend:'));
		tab_group_assets.add(gfVersionDropDown);
		tab_group_assets.add(new FlxText(stageDropDown.x, stageDropDown.y - 20, 200, 'Stage:'));
		tab_group_assets.add(stageDropDown);
		tab_group_assets.add(new FlxText(player1DropDown.x, player1DropDown.y - 20, 200, 'Player 1 (Boyfriend):'));
		tab_group_assets.add(player1DropDown);
		tab_group_assets.add(new FlxText(player2DropDown.x, player2DropDown.y - 20, 200, 'Player 2 (Opponent):'));
		tab_group_assets.add(player2DropDown);

		UI_box.addGroup(tab_group_assets);
	}

	var noteSkinInputText:FlxUIInputText;
	var noteSplashesInputText:FlxUIInputText;

	var check_mute_inst:FlxUICheckBox = null;
	var check_vortex:FlxUICheckBox = null;
	var playSoundBf:FlxUICheckBox = null;
	var playSoundDad:FlxUICheckBox = null;

	var UI_songIDTitle:FlxUIInputText;
	var UI_songNameTitle:FlxUIInputText;

	function addSongUI():Void
	{
		UI_songIDTitle = new FlxUIInputText(10, 10, 70, Paths.formatToSongPath(_song.songID), 8);
		blockPressWhileTypingOn.push(UI_songIDTitle);

		UI_songNameTitle = new FlxUIInputText(10, UI_songIDTitle.y + 20, 70, _song.songName, 8);
		blockPressWhileTypingOn.push(UI_songNameTitle);

		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 75, 0.1, 1, 1.0, 5000.0, 1);
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockPressWhileTypingOnStepper.push(stepperBPM);

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 100, 0.05, 1, 0.1, 10, 2);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockPressWhileTypingOnStepper.push(stepperSpeed);

		var saveButton:FlxButton = new FlxButton(200, 8, "Save JSON", saveLevel);

		var reloadSongJson:FlxButton = new FlxButton(200, saveButton.y + 30, "Reload JSON", function():Void
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function():Void {
				loadJson(_song.songID);
			}, null, ignoreWarnings));
		});

		var loadAutosaveBtn:FlxButton = new FlxButton(200, reloadSongJson.y + 30, 'Load Autosave', function():Void
		{
			var newSong:SwagSong = Song.parseJSONshit(FlxG.save.data.autosave);

			if (newSong != null)
			{
				PlayState.SONG = newSong;
				LoadingState.loadAndSwitchState(new ChartingState(), true);
			}
			else {
				Debug.logWarn('Cannot load autosave.');
			}
		});

		var saveEvents:FlxButton = new FlxButton(200, loadAutosaveBtn.y + 30, 'Save Events', saveEvents);

		var loadEventJson:FlxButton = new FlxButton(200, saveEvents.y + 30, 'Load Events', function():Void
		{
			var songName:String = _song.songID;
			var path:String = Paths.getJson('data/' + songName + '/events');

			if (Paths.fileExists(path, TEXT, true))
			{
				clearEvents();

				var events:SwagSong = Song.loadFromJson('events', songName);
				_song.events = events.events;

				changeSection(curSec);
			}
		});

		var clear_events:FlxButton = new FlxButton(200, loadEventJson.y + 30, 'Clear events', function():Void {
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', clearEvents, null,ignoreWarnings));
		});

		clear_events.color = FlxColor.RED;
		clear_events.label.color = FlxColor.WHITE;

		var clear_notes:FlxButton = new FlxButton(200, clear_events.y + 30, 'Clear notes', function():Void
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function():Void
			{
				for (sec in 0..._song.notes.length)
				{
					var count:Int = 0;
	
					while (count < _song.notes[sec].sectionNotes.length)
					{
						var note:Array<Dynamic> = _song.notes[sec].sectionNotes[count];
	
						if (note != null && note[1] > -1) {
							_song.notes[sec].sectionNotes.remove(note);
						}
						else {
							count++;
						}
					}
				}
	
				updateGrid();
			}, null, ignoreWarnings));
		});

		var reloadSong:FlxButton = new FlxButton(200, clear_notes.y + 30, "Reload Audio", function():Void
		{
			currentSongName = UI_songIDTitle.text;
			updateJsonData();
			loadSong();
			updateWaveform();
		});

		var diffArray:Array<String> = [];

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			var diff:String = '' + CoolUtil.difficultyStuff[i][1];
			diffArray.push(diff);
		}

		var difficultyDropDown = new FlxUIDropDownMenu(170, reloadSong.y + 60, FlxUIDropDownMenu.makeStrIdLabelArray(diffArray, true), function(diff:String):Void
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function():Void
			{
				PlayState.lastDifficulty = Std.parseInt(diff);
				loadJson(_song.songID);
			}, null, ignoreWarnings));
		});

		difficultyDropDown.selectedLabel = CoolUtil.difficultyStuff[PlayState.lastDifficulty][1];
		blockPressWhileScrolling.push(difficultyDropDown);

		var restart = new FlxButton(10, 140, "Reset Chart", function():Void
		{
			openSubState(new Prompt('This action will clear current progress.\n\nProceed?', function():Void
			{
				for (ii in 0..._song.notes.length) {
					_song.notes[ii].sectionNotes = [];
				}

				_song.events = [];

				_song.needsVoices = true;
				_song.player1 = 'bf';
				_song.player2 = 'dad';
				_song.gfVersion = 'gf';
				_song.stage = 'stage';
			}, null, ignoreWarnings));

			resetSection(true);
		});

		var check_voices = new FlxUICheckBox(10, restart.y + 45.3, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		check_voices.callback = function():Void {
			_song.needsVoices = check_voices.checked;
		};

		var tab_group_song:FlxUI = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";

		tab_group_song.add(new FlxText(UI_songIDTitle.width + 17.5, UI_songIDTitle.y, 0, 'Song\'s ID'));
		tab_group_song.add(new FlxText(UI_songNameTitle.width + 17.5, UI_songNameTitle.y, 0, 'Song\'s Name'));
		tab_group_song.add(UI_songIDTitle);
		tab_group_song.add(UI_songNameTitle);

		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(restart);
		tab_group_song.add(new FlxText(74, stepperBPM.y, 'Song\'s BPM'));
		tab_group_song.add(new FlxText(74, stepperSpeed.y, 'Song\'s Speed'));
		tab_group_song.add(new FlxText(difficultyDropDown.x, difficultyDropDown.y - 20, 'Difficulty:'));
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(saveEvents);
		tab_group_song.add(loadEventJson);
		tab_group_song.add(clear_events);
		tab_group_song.add(clear_notes);
		tab_group_song.add(reloadSong);
		tab_group_song.add(difficultyDropDown);
		tab_group_song.add(check_voices);

		UI_box.addGroup(tab_group_song);
		initSwagCamera().follow(camPos, LOCKON, 999);
	}

	var stepperBeats:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_gfSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_altAnim:FlxUICheckBox;

	var sectionToCopy:Int = 0;
	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section:FlxUI = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		check_mustHitSection = new FlxUICheckBox(10, 15, null, null, "Camera Points to P1?", 100);
		check_mustHitSection.name = 'check_mustHit';
		check_mustHitSection.checked = _song.notes[curSec].mustHitSection;

		check_gfSection = new FlxUICheckBox(10, check_mustHitSection.y + 22, null, null, "GF section", 100);
		check_gfSection.name = 'check_gf';
		check_gfSection.checked = _song.notes[curSec].gfSection;

		check_altAnim = new FlxUICheckBox(check_gfSection.x + 120, check_gfSection.y, null, null, "Alt Animation", 100);
		check_altAnim.checked = _song.notes[curSec].altAnim;

		stepperBeats = new FlxUINumericStepper(10, 100, 1, 4, 1, 6, 2);
		stepperBeats.value = getSectionBeats();
		stepperBeats.name = 'section_beats';
		blockPressWhileTypingOnStepper.push(stepperBeats);
		check_altAnim.name = 'check_altAnim';

		check_changeBPM = new FlxUICheckBox(10, stepperBeats.y + 30, null, null, 'Change BPM', 100);
		check_changeBPM.checked = _song.notes[curSec].changeBPM == true;
		check_changeBPM.name = 'check_changeBPM';

		stepperSectionBPM = new FlxUINumericStepper(10, check_changeBPM.y + 20, 1, Conductor.bpm, 0, 999, 1);
	
		if (check_changeBPM.checked) {
			stepperSectionBPM.value = _song.notes[curSec].bpm;
		}
		else {
			stepperSectionBPM.value = Conductor.bpm;
		}
	
		stepperSectionBPM.name = 'section_bpm';
		blockPressWhileTypingOnStepper.push(stepperSectionBPM);

		var check_eventsSec:FlxUICheckBox = null;
		var check_notesSec:FlxUICheckBox = null;

		var copyButton:FlxButton = new FlxButton(10, 190, "Copy Section", function():Void
		{
			notesCopied = [];
			sectionToCopy = curSec;
	
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				notesCopied.push(note);
			}

			var startThing:Float = sectionStartTime();
			var endThing:Float = sectionStartTime(1);
	
			for (event in _song.events)
			{
				var strumTime:Float = event[0];
		
				if (endThing > event[0] && event[0] >= startThing)
				{
					var copiedEventArray:Array<Dynamic> = [];
		
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
		
					notesCopied.push([strumTime, -1, copiedEventArray]);
				}
			}
		});

		var pasteButton:FlxButton = new FlxButton(copyButton.x + 100, copyButton.y, "Paste Section", function():Void
		{
			if (notesCopied == null || notesCopied.length < 1) {
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionBeats() * 4 * (curSec - sectionToCopy));

			for (note in notesCopied)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
		
				if (note[1] < 0)
				{
					if (check_eventsSec.checked)
					{
						var copiedEventArray:Array<Dynamic> = [];
				
						for (i in 0...note[2].length)
						{
							var eventToPush:Array<Dynamic> = note[2][i];
							copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
						}
				
						_song.events.push([newStrumTime, copiedEventArray]);
					}
				}
				else
				{
					if (check_notesSec.checked)
					{
						if (note[4] != null) {
							copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
						}
						else {
							copiedNote = [newStrumTime, note[1], note[2], note[3]];
						}

						_song.notes[curSec].sectionNotes.push(copiedNote);
					}
				}
			}
			updateGrid();
		});

		var clearSectionButton:FlxButton = new FlxButton(pasteButton.x + 100, pasteButton.y, "Clear", function():Void
		{
			if (check_notesSec.checked) {
				_song.notes[curSec].sectionNotes = [];
			}

			if (check_eventsSec.checked)
			{
				var i:Int = _song.events.length - 1;
				var startThing:Float = sectionStartTime();
				var endThing:Float = sectionStartTime(1);
		
				while (i > -1)
				{
					var event:Array<Dynamic> = _song.events[i];
		
					if (event != null && endThing > event[0] && event[0] >= startThing) {
						_song.events.remove(event);
					}
			
					--i;
				}
			}

			updateGrid();
			updateNoteUI();
		});

		clearSectionButton.color = FlxColor.RED;
		clearSectionButton.label.color = FlxColor.WHITE;
		
		check_notesSec = new FlxUICheckBox(10, clearSectionButton.y + 25, null, null, "Notes", 100);
		check_notesSec.checked = true;
		check_eventsSec = new FlxUICheckBox(check_notesSec.x + 100, check_notesSec.y, null, null, "Events", 100);
		check_eventsSec.checked = true;

		var swapSection:FlxButton = new FlxButton(10, check_notesSec.y + 40, "Swap section", function():Void
		{
			for (i in 0..._song.notes[curSec].sectionNotes.length)
			{
				var note:Array<Dynamic> = _song.notes[curSec].sectionNotes[i];
				note[1] = (note[1] + Note.pointers.length) % Math.floor(Note.pointers.length * 2);
				_song.notes[curSec].sectionNotes[i] = note;
			}
	
			updateGrid();
		});

		var stepperCopy:FlxUINumericStepper = null;

		var copyLastButton:FlxButton = new FlxButton(10, swapSection.y + 30, "Copy last section", function():Void
		{
			var value:Int = Std.int(stepperCopy.value);
			if (value == 0) return;

			var daSec = FlxMath.maxInt(curSec, value);

			for (note in _song.notes[daSec - value].sectionNotes)
			{
				var strum:Float = note[0] + Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);

				var copiedNote:Array<Dynamic> = [strum, note[1], note[2], note[3]];
				_song.notes[daSec].sectionNotes.push(copiedNote);
			}

			var startThing:Float = sectionStartTime(-value);
			var endThing:Float = sectionStartTime(-value + 1);

			for (event in _song.events)
			{
				var strumTime:Float = event[0];
	
				if (endThing > event[0] && event[0] >= startThing)
				{
					strumTime += Conductor.stepCrochet * (getSectionBeats(daSec) * 4 * value);
					var copiedEventArray:Array<Dynamic> = [];
		
					for (i in 0...event[1].length)
					{
						var eventToPush:Array<Dynamic> = event[1][i];
						copiedEventArray.push([eventToPush[0], eventToPush[1], eventToPush[2]]);
					}
			
					_song.events.push([strumTime, copiedEventArray]);
				}
			}

			updateGrid();
		});

		copyLastButton.setGraphicSize(80, 30);
		copyLastButton.updateHitbox();

		stepperCopy = new FlxUINumericStepper(copyLastButton.x + 100, copyLastButton.y, 1, 1, -999, 999, 0);
		blockPressWhileTypingOnStepper.push(stepperCopy);

		var duetButton:FlxButton = new FlxButton(10, copyLastButton.y + 45, "Duet Notes", function():Void
		{
			var duetNotes:Array<Array<Dynamic>> = [];

			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1];

				if (boob > 3) {
					boob -= 4;
				}
				else {
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes) {
				_song.notes[curSec].sectionNotes.push(i);
			}

			updateGrid();
		});

		var mirrorButton:FlxButton = new FlxButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function():Void
		{
			var duetNotes:Array<Array<Dynamic>> = [];

			for (note in _song.notes[curSec].sectionNotes)
			{
				var boob = note[1] % Note.pointers.length;
				boob = 3 - boob;
				if (note[1] > 3) boob += Note.pointers.length;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
			}

			updateGrid();
		});

		tab_group_section.add(new FlxText(stepperBeats.x, stepperBeats.y - 20, 0, 'Beats per Section:'));
		tab_group_section.add(new FlxText(74, stepperSectionBPM.y, 'Section\'s BPM'));
		tab_group_section.add(new FlxText(174, stepperCopy.y, 'sections back'));
		tab_group_section.add(stepperBeats);
		tab_group_section.add(stepperSectionBPM);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_gfSection);
		tab_group_section.add(check_altAnim);
		tab_group_section.add(check_changeBPM);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(check_notesSec);
		tab_group_section.add(check_eventsSec);
		tab_group_section.add(swapSection);
		tab_group_section.add(stepperCopy);
		tab_group_section.add(copyLastButton);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;
	var noteTypeDropDown:FlxUIDropDownMenu;
	var strumTimeInputText:FlxUIInputText;
	var currentType:Int = 0;

	function addNoteUI():Void
	{
		var tab_group_note:FlxUI = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 64);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockPressWhileTypingOnStepper.push(stepperSusLength);

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		tab_group_note.add(strumTimeInputText);
		blockPressWhileTypingOn.push(strumTimeInputText);

		var key:Int = 0;

		while (key < Note.defaultNoteTypes.length)
		{
			curNoteTypes.push(Note.defaultNoteTypes[key]);
			key++;
		}

		#if sys
		var defaultDirectories:Array<String> = [Paths.getLibraryPath()];

		var libraryPath:String = Paths.getLibraryPath('', 'shared');
		defaultDirectories.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));

		if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared')
		{
			var libraryPath:String = Paths.getLibraryPath('', Paths.currentLevel);
			defaultDirectories.insert(0, libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));
		}

		var foldersToCheck:Array<String> = Paths.directoriesWithFile(defaultDirectories, 'custom_notetypes/');

		for (folder in foldersToCheck)
		{
			for (file in FileSystem.readDirectory(folder))
			{
				var fileName:String = file.toLowerCase().trim();
				var wordLen:Int = 4; // length of word ".lua" and ".txt";

				if ((#if LUA_ALLOWED fileName.endsWith('.lua') || #end
					#if HSCRIPT_ALLOWED (fileName.endsWith('.hx') && (wordLen = 3) == 3) || #end
					fileName.endsWith('.txt')) && fileName != 'readme.txt')
				{
					var fileToCheck:String = file.substr(0, file.length - wordLen);

					if (!curNoteTypes.contains(fileToCheck))
					{
						curNoteTypes.push(fileToCheck);
						key++;
					}
				}
			}
		}
		#end

		var displayNameList:Array<String> = curNoteTypes.copy();

		for (i in 1...displayNameList.length) {
			displayNameList[i] = i + '. ' + displayNameList[i];
		}

		noteTypeDropDown = new FlxUIDropDownMenu(10, 105, FlxUIDropDownMenu.makeStrIdLabelArray(displayNameList, true), function(character:String):Void
		{
			currentType = Std.parseInt(character);

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				curSelectedNote[3] = curNoteTypes[currentType];
				updateGrid();
			}
		});

		blockPressWhileScrolling.push(noteTypeDropDown);

		tab_group_note.add(new FlxText(74, 10, 0, 'Note Sustain Length'));
		tab_group_note.add(new FlxText(10, 45, 0, 'Strum Time (in miliseconds):'));
		tab_group_note.add(new FlxText(10, 85, 0, 'Note Type:'));

		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(noteTypeDropDown);

		UI_box.addGroup(tab_group_note);
	}

	var eventDropDown:FlxUIDropDownMenu;

	var descText:FlxText;
	var selectedEventText:FlxText;

	function addEventsUI():Void
	{
		var tab_group_event:FlxUI = new FlxUI(null, UI_box);
		tab_group_event.name = 'Events';

		#if LUA_ALLOWED
		var directories:Array<String> = [];

		#if MODS_ALLOWED
		directories.push(Paths.mods('custom_events/'));
		directories.push(Paths.mods(Paths.currentModDirectory + '/custom_events/'));

		for (mod in Paths.globalMods) {
			directories.push(Paths.mods(mod + '/custom_events/'));
		}
		#end

		if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared')
		{
			var libraryPath:String = Paths.getLibraryPath('custom_events/', Paths.currentLevel);
			directories.push(libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));
		}

		var libraryPath:String = Paths.getLibraryPath('custom_events/', 'shared');
		directories.push(libraryPath.substring(libraryPath.indexOf(':') + 1, libraryPath.length));

		directories.push(Paths.getPreloadPath('custom_events/'));

		for (i in 0...directories.length)
		{
			var directory:String = directories[i];

			if (FileSystem.exists(directory))
			{
				for (file in FileSystem.readDirectory(directory))
				{
					var path:String = Path.join([directory, file]);

					if (!FileSystem.isDirectory(path) && file != 'readme.txt' && file.endsWith('.txt'))
					{
						var fileToCheck:String = file.substr(0, file.length - 4);

						if (!eventStuff.contains(fileToCheck)) {
							eventStuff.push([fileToCheck, File.getContent(path)]);
						}
					}
				}
			}
		}
		#end

		descText = new FlxText(20, 200, 0, eventStuff[0][0]);

		var leEvents:Array<String> = [];

		for (i in 0...eventStuff.length) {
			leEvents.push(eventStuff[i][0]);
		}

		var text:FlxText = new FlxText(20, 30, 0, "Event:");
		tab_group_event.add(text);

		eventDropDown = new FlxUIDropDownMenu(20, 50, FlxUIDropDownMenu.makeStrIdLabelArray(leEvents, true), function(pressed:String):Void
		{
			var selectedEvent:Int = Std.parseInt(pressed);
			descText.text = eventStuff[selectedEvent][1];

			if (curSelectedNote != null && eventStuff != null)
			{
				if (curSelectedNote != null && curSelectedNote[2] == null) {
					curSelectedNote[1][curEventSelected][0] = eventStuff[selectedEvent][0];
				}

				updateGrid();
			}
		});

		blockPressWhileScrolling.push(eventDropDown);

		var text:FlxText = new FlxText(20, 90, 0, "Value 1:");
		tab_group_event.add(text);

		value1InputText = new FlxUIInputText(20, 110, 100, "");
		blockPressWhileTypingOn.push(value1InputText);

		var text:FlxText = new FlxText(20, 130, 0, "Value 2:");
		tab_group_event.add(text);

		value2InputText = new FlxUIInputText(20, 150, 100, "");
		blockPressWhileTypingOn.push(value2InputText);

		var removeButton:FlxButton = new FlxButton(eventDropDown.x + eventDropDown.width + 10, eventDropDown.y, '-', function():Void
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				if (curSelectedNote[1].length < 2)
				{
					_song.events.remove(curSelectedNote);
					curSelectedNote = null;
				}
				else {
					curSelectedNote[1].remove(curSelectedNote[1][curEventSelected]);
				}

				var eventsGroup:Array<Dynamic>;
				--curEventSelected;
				if (curEventSelected < 0)
					curEventSelected = 0;
				else if (curSelectedNote != null && curEventSelected >= (eventsGroup = curSelectedNote[1]).length)
					curEventSelected = eventsGroup.length - 1;

				changeEventSelected();
				updateGrid();
			}
		});

		removeButton.setGraphicSize(Std.int(removeButton.height), Std.int(removeButton.height));
		removeButton.updateHitbox();
		removeButton.color = FlxColor.RED;
		removeButton.label.color = FlxColor.WHITE;
		removeButton.label.size = 12;

		setAllLabelsOffset(removeButton, -30, 0);

		tab_group_event.add(removeButton);

		var addButton:FlxButton = new FlxButton(removeButton.x + removeButton.width + 10, removeButton.y, '+', function():Void
		{
			if (curSelectedNote != null && curSelectedNote[2] == null) //Is event note
			{
				var eventsGroup:Array<Dynamic> = curSelectedNote[1];
				eventsGroup.push(['', '', '']);

				changeEventSelected(1);
				updateGrid();
			}
		});

		addButton.setGraphicSize(Std.int(removeButton.width), Std.int(removeButton.height));
		addButton.updateHitbox();
		addButton.color = FlxColor.GREEN;
		addButton.label.color = FlxColor.WHITE;
		addButton.label.size = 12;

		setAllLabelsOffset(addButton, -30, 0);

		tab_group_event.add(addButton);

		var moveLeftButton:FlxButton = new FlxButton(addButton.x + addButton.width + 20, addButton.y, '<', function():Void 	{
			changeEventSelected(-1);
		});
		moveLeftButton.setGraphicSize(Std.int(addButton.width), Std.int(addButton.height));
		moveLeftButton.updateHitbox();
		moveLeftButton.label.size = 12;

		setAllLabelsOffset(moveLeftButton, -30, 0);

		tab_group_event.add(moveLeftButton);

		var moveRightButton:FlxButton = new FlxButton(moveLeftButton.x + moveLeftButton.width + 10, moveLeftButton.y, '>', function():Void {
			changeEventSelected(1);
		});
		moveRightButton.setGraphicSize(Std.int(moveLeftButton.width), Std.int(moveLeftButton.height));
		moveRightButton.updateHitbox();
		moveRightButton.label.size = 12;

		setAllLabelsOffset(moveRightButton, -30, 0);

		tab_group_event.add(moveRightButton);

		selectedEventText = new FlxText(addButton.x - 100, addButton.y + addButton.height + 6, (moveRightButton.x - addButton.x) + 186, 'Selected Event: None');
		selectedEventText.alignment = CENTER;
		tab_group_event.add(selectedEventText);

		tab_group_event.add(descText);
		tab_group_event.add(value1InputText);
		tab_group_event.add(value2InputText);
		tab_group_event.add(eventDropDown);

		UI_box.addGroup(tab_group_event);
	}

	function changeEventSelected(change:Int = 0):Void
	{
		if (curSelectedNote != null && curSelectedNote[2] == null) //Is event note
		{
			curEventSelected += change;

			if (curEventSelected < 0)
				curEventSelected = Std.int(curSelectedNote[1].length) - 1;
			else if (curEventSelected >= curSelectedNote[1].length)
				curEventSelected = 0;

			selectedEventText.text = 'Selected Event: ' + (curEventSelected + 1) + ' / ' + curSelectedNote[1].length;
		}
		else
		{
			curEventSelected = 0;
			selectedEventText.text = 'Selected Event: None';
		}

		updateNoteUI();
	}
	
	function setAllLabelsOffset(button:Dynamic, x:Float, y:Float)
	{
		var labelOffsets:Array<FlxPoint> = button.labelOffsets;

		for (point in labelOffsets) {
			point.set(x, y);
		}
	}

	var check_warnings:FlxUICheckBox = null;

	var metronome:FlxUICheckBox;
	var mouseScrollingQuant:FlxUICheckBox;
	var metronomeStepper:FlxUINumericStepper;
	var metronomeOffsetStepper:FlxUINumericStepper;
	var disableAutoScrolling:FlxUICheckBox;
	var check_mute_vocals:FlxUICheckBox;
	var check_mute_vocals_opponent:FlxUICheckBox = null;

	#if desktop
	var waveformUseInstrumental:FlxUICheckBox;
	var waveformUseVoices:FlxUICheckBox;
	var waveformUseOppVoices:FlxUICheckBox = null;
	#end

	var instVolume:FlxUINumericStepper;
	var voicesVolume:FlxUINumericStepper;
	var voicesOppVolume:FlxUINumericStepper;

	#if FLX_PITCH
	var sliderRate:FlxUISlider;
	#end

	function addChartingUI():Void
	{
		var tab_group_chart:FlxUI = new FlxUI(null, UI_box);
		tab_group_chart.name = 'Charting';

		#if desktop
		if (FlxG.save.data.chart_waveformInst == null) FlxG.save.data.chart_waveformInst = false;
		if (FlxG.save.data.chart_waveformVoices == null) FlxG.save.data.chart_waveformVoices = false;
		if (FlxG.save.data.chart_waveformOppVoices == null) FlxG.save.data.chart_waveformOppVoices = false;

		waveformUseInstrumental = new FlxUICheckBox(10, 90, null, null, "Waveform for Instrumental", 100);
		waveformUseInstrumental.checked = FlxG.save.data.chart_waveformInst;
		waveformUseInstrumental.callback = function():Void
		{
			waveformUseVoices.checked = false;
			waveformUseOppVoices.checked = false;

			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformInst = waveformUseInstrumental.checked;

			updateWaveform();
		}

		waveformUseVoices = new FlxUICheckBox(waveformUseInstrumental.x + 120, waveformUseInstrumental.y, null, null, "Waveform for Voices\n(Main Vocals)", 100);
		waveformUseVoices.checked = FlxG.save.data.chart_waveformVoices && !waveformUseInstrumental.checked;
		waveformUseVoices.callback = function():Void
		{
			waveformUseInstrumental.checked = false;
			waveformUseOppVoices.checked = false;

			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformOppVoices = false;
			FlxG.save.data.chart_waveformVoices = waveformUseVoices.checked;

			updateWaveform();
		}

		waveformUseOppVoices = new FlxUICheckBox(waveformUseInstrumental.x + 200, waveformUseInstrumental.y, null, null, "Waveform\n(Opp. Vocals)", 85);
		waveformUseOppVoices.checked = FlxG.save.data.chart_waveformOppVoices && !waveformUseVoices.checked;
		waveformUseOppVoices.callback = function()
		{
			waveformUseInstrumental.checked = false;
			waveformUseVoices.checked = false;

			FlxG.save.data.chart_waveformInst = false;
			FlxG.save.data.chart_waveformVoices = false;
			FlxG.save.data.chart_waveformOppVoices = waveformUseOppVoices.checked;

			updateWaveform();
		}
		#end

		check_mute_inst = new FlxUICheckBox(10, 310, null, null, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.callback = function():Void
		{
			var vol:Float = instVolume.value;
			if (check_mute_inst.checked) vol = 0;

			FlxG.sound.music.volume = vol;
		}

		mouseScrollingQuant = new FlxUICheckBox(10, 200, null, null, "Mouse Scrolling Quantization", 100);
		if (FlxG.save.data.mouseScrollingQuant == null) FlxG.save.data.mouseScrollingQuant = false;
		mouseScrollingQuant.checked = FlxG.save.data.mouseScrollingQuant;

		mouseScrollingQuant.callback = function():Void
		{
			FlxG.save.data.mouseScrollingQuant = mouseScrollingQuant.checked;
			mouseQuant = FlxG.save.data.mouseScrollingQuant;
		}

		check_vortex = new FlxUICheckBox(10, 160, null, null, "Vortex Editor (BETA)", 100);

		if (FlxG.save.data.chart_vortex == null) FlxG.save.data.chart_vortex = false;
		check_vortex.checked = FlxG.save.data.chart_vortex;

		check_vortex.callback = function():Void
		{
			FlxG.save.data.chart_vortex = check_vortex.checked;
			vortex = FlxG.save.data.chart_vortex;
			reloadGridLayer();
		}

		check_warnings = new FlxUICheckBox(10, 120, null, null, "Ignore Progress Warnings", 100);

		if (FlxG.save.data.ignoreWarnings == null) FlxG.save.data.ignoreWarnings = false;
		check_warnings.checked = FlxG.save.data.ignoreWarnings;

		check_warnings.callback = function():Void
		{
			FlxG.save.data.ignoreWarnings = check_warnings.checked;
			ignoreWarnings = FlxG.save.data.ignoreWarnings;
		}

		check_mute_vocals = new FlxUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, null, null, "Mute Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.callback = function():Void
		{
			var vol:Float = voicesVolume.value;
			if (check_mute_vocals.checked) vol = 0;

			if (vocals != null) vocals.volume = vol;
		}

		check_mute_vocals_opponent = new FlxUICheckBox(check_mute_vocals.x + 120, check_mute_vocals.y, null, null, "Mute Opp. Vocals (in editor)", 100);
		check_mute_vocals_opponent.checked = false;
		check_mute_vocals_opponent.callback = function()
		{
			var vol:Float = voicesOppVolume.value;
			if (check_mute_vocals_opponent.checked) vol = 0;

			if (opponentVocals != null && hasOpponentVocals) opponentVocals.volume = vol;
		};

		playSoundBf = new FlxUICheckBox(check_mute_inst.x, check_mute_vocals.y + 30, null, null, 'Play Sound (Boyfriend notes)', 100, function():Void {
			FlxG.save.data.chart_playSoundBf = playSoundBf.checked;
		});

		if (FlxG.save.data.chart_playSoundBf == null) FlxG.save.data.chart_playSoundBf = false;
		playSoundBf.checked = FlxG.save.data.chart_playSoundBf;

		playSoundDad = new FlxUICheckBox(check_mute_inst.x + 120, playSoundBf.y, null, null, 'Play Sound (Opponent notes)', 100, function():Void {
			FlxG.save.data.chart_playSoundDad = playSoundDad.checked;
		});

		if (FlxG.save.data.chart_playSoundDad == null) FlxG.save.data.chart_playSoundDad = false;
		playSoundDad.checked = FlxG.save.data.chart_playSoundDad;

		metronome = new FlxUICheckBox(10, 15, null, null, "Metronome Enabled", 100, function():Void {
			FlxG.save.data.chart_metronome = metronome.checked;
		});

		if (FlxG.save.data.chart_metronome == null) FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		metronomeStepper = new FlxUINumericStepper(15, 55, 5, _song.bpm, 1, 1500, 1);
		metronomeOffsetStepper = new FlxUINumericStepper(metronomeStepper.x + 100, metronomeStepper.y, 25, 0, 0, 1000, 1);
		blockPressWhileTypingOnStepper.push(metronomeStepper);
		blockPressWhileTypingOnStepper.push(metronomeOffsetStepper);

		disableAutoScrolling = new FlxUICheckBox(metronome.x + 120, metronome.y, null, null, "Disable Autoscroll (Not Recommended)", 120, function():Void {
			FlxG.save.data.chart_noAutoScroll = disableAutoScrolling.checked;
		});

		if (FlxG.save.data.chart_noAutoScroll == null) FlxG.save.data.chart_noAutoScroll = false;
		disableAutoScrolling.checked = FlxG.save.data.chart_noAutoScroll;

		instVolume = new FlxUINumericStepper(metronomeStepper.x, 270, 0.1, 1, 0, 1, 1);
		instVolume.value = FlxG.sound.music.volume;
		instVolume.name = 'inst_volume';
		blockPressWhileTypingOnStepper.push(instVolume);

		voicesVolume = new FlxUINumericStepper(instVolume.x + 100, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesVolume.value = vocals.volume;
		voicesVolume.name = 'voices_volume';
		blockPressWhileTypingOnStepper.push(voicesVolume);

		voicesOppVolume = new FlxUINumericStepper(instVolume.x + 200, instVolume.y, 0.1, 1, 0, 1, 1);
		voicesOppVolume.value = vocals.volume;
		voicesOppVolume.name = 'voices_opp_volume';
		blockPressWhileTypingOnStepper.push(voicesOppVolume);

		#if FLX_PITCH
		sliderRate = new FlxUISlider(this, 'playbackSpeed', 120, 120, 0.5, 3, 150, 15, 5, FlxColor.WHITE, FlxColor.BLACK);
		sliderRate.nameLabel.text = 'Playback Rate';
		tab_group_chart.add(sliderRate);
		#end

		tab_group_chart.add(new FlxText(metronomeStepper.x, metronomeStepper.y - 15, 0, 'BPM:'));
		tab_group_chart.add(new FlxText(metronomeOffsetStepper.x, metronomeOffsetStepper.y - 15, 0, 'Offset (ms):'));
		tab_group_chart.add(new FlxText(instVolume.x, instVolume.y - 15, 0, 'Inst Volume'));
		tab_group_chart.add(new FlxText(voicesVolume.x, voicesVolume.y - 15, 0, 'Main Vocals'));
		tab_group_chart.add(new FlxText(voicesOppVolume.x, voicesOppVolume.y - 15, 0, 'Opp. Vocals'));
		tab_group_chart.add(metronome);
		tab_group_chart.add(disableAutoScrolling);
		tab_group_chart.add(metronomeStepper);
		tab_group_chart.add(metronomeOffsetStepper);

		#if desktop
		tab_group_chart.add(waveformUseInstrumental);
		tab_group_chart.add(waveformUseVoices);
		tab_group_chart.add(waveformUseOppVoices);
		#end

		tab_group_chart.add(instVolume);
		tab_group_chart.add(voicesVolume);
		tab_group_chart.add(voicesOppVolume);
		tab_group_chart.add(check_mute_inst);
		tab_group_chart.add(check_mute_vocals);
		tab_group_chart.add(check_mute_vocals_opponent);
		tab_group_chart.add(check_vortex);
		tab_group_chart.add(mouseScrollingQuant);
		tab_group_chart.add(check_warnings);
		tab_group_chart.add(playSoundBf);
		tab_group_chart.add(playSoundDad);

		UI_box.addGroup(tab_group_chart);
	}

	function loadSong():Void
	{
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
		}

		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}

		if (opponentVocals != null && hasOpponentVocals)
		{
			opponentVocals.stop();
			opponentVocals.destroy();
		}

		vocals = new FlxSound();

		if (_song.needsVoices)
		{
			var postfix:String = ((characterData.vocalsP1 != null && characterData.vocalsP1.length > 0) ? characterData.vocalsP1 : 'Player');

			if (Paths.fileExists(Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], postfix, true), SOUND))
			{
				var file:Sound = Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], postfix);
				vocals.loadEmbedded(file);
			}
			else if (Paths.fileExists(Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], null, true), SOUND))
			{
				var file:Sound = Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2]);
				vocals.loadEmbedded(file);
			}
		}

		FlxG.sound.list.add(vocals);

		opponentVocals = new FlxSound();

		if (_song.needsVoices)
		{
			var postfix:String = ((characterData.vocalsP2 != null && characterData.vocalsP2.length > 0) ? characterData.vocalsP2 : 'Opponent');

			if (Paths.fileExists(Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], postfix, true), SOUND))
			{
				var file:Sound = Paths.getVoices(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], postfix);
				opponentVocals.loadEmbedded(file);
				hasOpponentVocals = true;
			}
		}

		FlxG.sound.list.add(opponentVocals);

		generateSong();

		FlxG.sound.music.pause();
		Conductor.songPosition = sectionStartTime();

		FlxG.sound.music.time = Conductor.songPosition;

		var curTime:Float = 0;

		if (_song.notes.length <= 1) //First load ever
		{
			Debug.logInfo('first load ever!!');

			while (curTime < FlxG.sound.music.length)
			{
				addSection();
				curTime += (60 / _song.bpm) * 4000;
			}
		}
	}

	var playtesting:Bool = false;
	var playtestingTime:Float = 0;
	var playtestingOnComplete:Void->Void = null;

	override function closeSubState():Void
	{
		if (playtesting)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = playtestingTime;
			FlxG.sound.music.onComplete = playtestingOnComplete;

			if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
			if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

			if (vocals != null)
			{
				vocals.pause();
				vocals.time = playtestingTime;

				if (voicesVolume != null) vocals.volume = voicesVolume.value;
				if (check_mute_vocals != null && check_mute_vocals.checked) vocals.volume = 0;
			}

			if (opponentVocals != null && hasOpponentVocals)
			{
				opponentVocals.pause();
				opponentVocals.time = playtestingTime;

				if (voicesOppVolume != null) opponentVocals.volume = voicesOppVolume.value;
				if (check_mute_vocals_opponent != null && check_mute_vocals_opponent.checked) opponentVocals.volume = 0;
			}

			#if DISCORD_ALLOWED
			DiscordClient.changePresence("Chart Editor", _song.songName); // Updating Discord Rich Presence
			#end
		}

		super.closeSubState();
	}

	function generateSong():Void
	{
		FlxG.sound.playMusic(Paths.getInst(currentSongName, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2]), 0.6);
		FlxG.sound.music.autoDestroy = false;

		if (instVolume != null) FlxG.sound.music.volume = instVolume.value;
		if (check_mute_inst != null && check_mute_inst.checked) FlxG.sound.music.volume = 0;

		FlxG.sound.music.onComplete = function():Void
		{
			FlxG.sound.music.pause();
			Conductor.songPosition = 0;

			if (vocals != null)
			{
				vocals.pause();
				vocals.time = 0;
			}

			if (opponentVocals != null && hasOpponentVocals)
			{
				opponentVocals.pause();
				opponentVocals.time = 0;
			}

			changeSection();

			curSec = 0;

			updateGrid();
			updateSectionUI();

			if (vocals != null) vocals.play();
			if (opponentVocals != null && hasOpponentVocals) opponentVocals.play();
		}
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label:String = check.getLabel().text;

			switch (label)
			{
				case 'Camera Points to P1?':
				{
					_song.notes[curSec].mustHitSection = check.checked;

					updateGrid();
					updateHeads();
				}
				case 'GF section':
				{
					_song.notes[curSec].gfSection = check.checked;

					updateGrid();
					updateHeads();
				}
				case 'Change BPM':
				{
					_song.notes[curSec].changeBPM = check.checked;
					Debug.logInfo('changed bpm shit');
				}
				case 'Alt Animation': _song.notes[curSec].altAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname:String = nums.name;

			switch (wname)
			{
				case 'section_beats':
				{
					_song.notes[curSec].sectionBeats = nums.value;
					reloadGridLayer();
				}
				case 'song_speed': _song.speed = nums.value;
				case 'song_bpm':
				{
					_song.bpm = nums.value;

					Conductor.mapBPMChanges(_song);
					Conductor.bpm = nums.value;

					stepperSusLength.stepSize = Math.ceil(Conductor.stepCrochet / 2);

					updateGrid();
				}
				case 'note_susLength':
				{
					if (nums.value <= 0) {
						nums.value = 0;
					}

					if (curSelectedNote != null && curSelectedNote[2] != null)
					{
						curSelectedNote[2] = nums.value;
						updateGrid();
					}
				}
				case 'section_bpm':
				{
					if (nums.value <= 0.1) {
						nums.value = 0.1;
					}

					_song.notes[curSec].bpm = Std.int(nums.value);
					updateGrid();
				}
				case 'inst_volume':
				{
					FlxG.sound.music.volume = nums.value;
					if (check_mute_inst.checked) FlxG.sound.music.volume = 0;
				}
				case 'voices_volume':
				{
					vocals.volume = nums.value;
					if (check_mute_vocals.checked) vocals.volume = 0;
				}
				case 'voices_opp_volume':
				{
					if (hasOpponentVocals)
					{
						opponentVocals.volume = nums.value;
						if (check_mute_vocals_opponent.checked) opponentVocals.volume = 0;
					}
				}
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == UI_songIDTitle)
			{
				_song.songID = Paths.formatToSongPath(UI_songIDTitle.text);
				UI_songIDTitle.text = _song.songID;
			}
			else if (sender == UI_songNameTitle) {
				_song.songName = UI_songNameTitle.text;
			}
			else if (sender == noteSplashesInputText) {
				_song.splashSkin = noteSplashesInputText.text;
			}
			else if (sender == noteSkinInputText) {
				_song.arrowSkin = noteSkinInputText.text;
			}
			else if (curSelectedNote != null)
			{
				if (sender == value1InputText)
				{
					if (curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][1] = value1InputText.text;
						updateGrid();
					}
				}
				else if (sender == value2InputText)
				{
					if (curSelectedNote[1][curEventSelected] != null)
					{
						curSelectedNote[1][curEventSelected][2] = value2InputText.text;
						updateGrid();
					}
				}
				else if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value)) value = 0;

					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}
		else if (id == FlxUISlider.CHANGE_EVENT && (sender is FlxUISlider))
		{
			switch (sender) {
				case 'playbackSpeed': playbackSpeed = #if FLX_PITCH Std.int(sliderRate.value) #else 1.0 #end;
			}
		}
	}

	function sectionStartTime(add:Int = 0):Float
	{
		var daBPM:Float = _song.bpm;
		var daPos:Float = 0;

		for (i in 0...curSec + add)
		{
			if (_song.notes[i] != null)
			{
				if (_song.notes[i].changeBPM == true) {
					daBPM = _song.notes[i].bpm;
				}

				daPos += getSectionBeats(i) * (1000 * 60 / daBPM);
			}
		}

		return daPos;
	}

	var lastConductorPos:Float;
	var colorSine:Float = 0;

	override function update(elapsed:Float):Void
	{
		curStep = recalculateSteps();

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;

			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;

		strumLineUpdateY();
	
		for (i in 0...8) {
			strumLineNotes.members[i].y = strumLine.y;
		}

		camPos.y = strumLine.y;

		if (!disableAutoScrolling.checked)
		{
			if (Math.ceil(strumLine.y) >= gridBG.height)
			{
				if (_song.notes[curSec + 1] == null) {
					addSection();
				}

				changeSection(curSec + 1, false);
			}
			else if (strumLine.y < -10) {
				changeSection(curSec - 1, false);
			}
		}

		FlxG.watch.addQuick('daSec', curSec);
		FlxG.watch.addQuick('daBeat', curBeat);
		FlxG.watch.addQuick('daStep', curStep);

		if (FlxG.mouse.x > gridBG.x
			&& FlxG.mouse.x < gridBG.x + gridBG.width
			&& FlxG.mouse.y > gridBG.y
			&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom])
		{
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;

			if (FlxG.keys.pressed.SHIFT) dummyArrow.y = FlxG.mouse.y; else
			{
				var gridmult:Float = GRID_SIZE / (quantization / 16);
				dummyArrow.y = Math.floor(FlxG.mouse.y / gridmult) * gridmult;
			}
		}
		else {
			dummyArrow.visible = false;
		}

		if (FlxG.mouse.justPressed)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEachAlive(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL) {
							selectNote(note);
						}
						else if (FlxG.keys.pressed.ALT)
						{
							selectNote(note);
							curSelectedNote[3] = curNoteTypes[currentType];
							updateGrid();
						}
						else {
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if (FlxG.mouse.x > gridBG.x
					&& FlxG.mouse.x < gridBG.x + gridBG.width
					&& FlxG.mouse.y > gridBG.y
					&& FlxG.mouse.y < gridBG.y + (GRID_SIZE * getSectionBeats() * 4) * zoomList[curZoom]) {
					addNote();
				}
			}
		}

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);

				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;

				if (leText.hasFocus)
				{
					ClientPrefs.toggleVolumeKeys(false);

					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			ClientPrefs.toggleVolumeKeys(true);
	
			for (dropDownMenu in blockPressWhileScrolling)
			{
				if (dropDownMenu.dropPanel.visible)
				{
					blockInput = true;
					break;
				}
			}
		}

		if (!blockInput)
		{
			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.music.pause();

				if (vocals != null) vocals.pause();
				if (hasOpponentVocals && opponentVocals != null) opponentVocals.pause();

				autosaveSong();

				playtesting = true;
				playtestingTime = Conductor.songPosition;
				playtestingOnComplete = FlxG.sound.music.onComplete;

				openSubState(new EditorPlayState(playbackSpeed));
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				autosaveSong();

				lastSection = curSec;

				PlayState.SONG = _song;

				FlxG.sound.music.stop();
				if (vocals != null) vocals.stop();
				if (hasOpponentVocals && opponentVocals != null) opponentVocals.stop();

				StageData.loadDirectory(_song);
				LoadingState.loadAndSwitchState(new PlayState(), true);
			}

			if (curSelectedNote != null && curSelectedNote[1] > -1)
			{
				if (FlxG.keys.justPressed.E) {
					changeNoteSustain(Conductor.stepCrochet);
				}

				if (FlxG.keys.justPressed.Q) {
					changeNoteSustain(-Conductor.stepCrochet);
				}
			}

			#if desktop
			if (FlxG.keys.justPressed.BACKSPACE)
			{
				autosaveSong();

				FlxG.sound.music.volume = 0;
				if (vocals != null) vocals.volume = 0;
				if (hasOpponentVocals && opponentVocals != null) opponentVocals.volume = 0;

				PlayState.chartingMode = false;

				FlxG.switchState(new MasterEditorMenu());

				return;
			}
			#end

			if (FlxG.keys.justPressed.Z && curZoom > 0 && !FlxG.keys.justPressed.CONTROL)
			{
				--curZoom;
				updateZoom();
			}

			if (FlxG.keys.justPressed.X && curZoom < zoomList.length - 1)
			{
				curZoom++;
				updateZoom();
			}

			if (FlxG.keys.justPressed.TAB)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					UI_box.selected_tab -= 1;

					if (UI_box.selected_tab < 0) {
						UI_box.selected_tab = 2;
					}
				}
				else
				{
					UI_box.selected_tab += 1;

					if (UI_box.selected_tab >= 3) {
						UI_box.selected_tab = 0;
					}
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (FlxG.sound.music.playing)
				{
					FlxG.sound.music.pause();
					if (vocals != null) vocals.pause();
					if (hasOpponentVocals && opponentVocals != null) vocals.pause();
				}
				else
				{
					if (vocals != null)
					{
						vocals.play();
						vocals.pause();

						vocals.time = FlxG.sound.music.time;
						vocals.play();
					}

					if (hasOpponentVocals && opponentVocals != null)
					{
						opponentVocals.play();
						opponentVocals.pause();

						opponentVocals.time = FlxG.sound.music.time;
						opponentVocals.play();
					}

					FlxG.sound.music.play();
				}
			}

			if (!FlxG.keys.pressed.ALT && FlxG.keys.justPressed.R)
			{
				if (FlxG.keys.pressed.SHIFT)
					resetSection(true);
				else
					resetSection();
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.music.pause();
	
				if (!mouseQuant) {
					FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.8);
				}
				else
				{
					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;

					if (FlxG.mouse.wheel > 0)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}

				if (hasOpponentVocals && opponentVocals != null)
				{
					opponentVocals.pause();
					opponentVocals.time = FlxG.sound.music.time;
				}
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
			{
				FlxG.sound.music.pause();

				var holdingShift:Float = 1;

				if (FlxG.keys.pressed.CONTROL) {
					holdingShift = 0.25;
				}
				else if (FlxG.keys.pressed.SHIFT) {
					holdingShift = 4;
				}

				var daTime:Float = 700 * elapsed * holdingShift;

				if (FlxG.keys.pressed.W) {
					FlxG.sound.music.time -= daTime;
				}
				else {
					FlxG.sound.music.time += daTime;
				}

				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}

				if (hasOpponentVocals && opponentVocals != null)
				{
					opponentVocals.pause();
					opponentVocals.time = FlxG.sound.music.time;
				}
			}

			if (!vortex)
			{
				var pressingUp:Bool = FlxG.keys.justPressed.UP;

				if (pressingUp || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();

					if (vocals != null) vocals.pause();
					if (hasOpponentVocals && opponentVocals != null) opponentVocals.pause();

					updateCurStep();

					var beat:Float = curDecBeat;
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
			
					if (pressingUp)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase; 
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						FlxG.sound.music.time = Conductor.beatToSeconds(fuck);
					}
				}
			}

			var style:Int = FlxG.keys.pressed.SHIFT ? 3 : currentType;
			var conductorTime:Float = Conductor.songPosition;

			if (FlxG.keys.justPressed.LEFT)
			{
				curQuant--;
				if (curQuant < 0) curQuant = quantizations.length - 1;

				quantization = quantizations[curQuant];
				updateText();
			}

			if (FlxG.keys.justPressed.RIGHT)
			{
				curQuant++;
				if (curQuant > quantizations.length - 1) curQuant = 0;

				quantization = quantizations[curQuant];
				updateText();
			}
	
			quant.playAnim('q', true, false, curQuant);
			
			if (vortex)
			{
				var controlArray:Array<Bool> =
				[
					FlxG.keys.justPressed.ONE,
					FlxG.keys.justPressed.TWO,
					FlxG.keys.justPressed.THREE,
					FlxG.keys.justPressed.FOUR,
					FlxG.keys.justPressed.FIVE,
					FlxG.keys.justPressed.SIX,
					FlxG.keys.justPressed.SEVEN,
					FlxG.keys.justPressed.EIGHT
				];

				if (controlArray.contains(true))
				{
					for (i in 0...controlArray.length)
					{
						if (controlArray[i]) {
							doANoteThing(conductorTime, i, style);
						}
					}
				}

				var feces:Float = -1;
	
				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.music.pause();
					updateCurStep();

					var beat:Float = curDecBeat;
			
					var snap:Float = quantization / 4;
					var increase:Float = 1 / snap;
			
					if (FlxG.keys.pressed.UP)
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) - increase;
						feces = Conductor.beatToSeconds(fuck);
					}
					else
					{
						var fuck:Float = CoolUtil.quantize(beat, snap) + increase;
						feces = Conductor.beatToSeconds(fuck);
					}
				
					FlxTween.tween(FlxG.sound.music, {time: feces}, 0.1, {ease: FlxEase.circOut});
				
					if (vocals != null)
					{
						vocals.pause();
						vocals.time = FlxG.sound.music.time;
					}

					if (hasOpponentVocals && opponentVocals != null)
					{
						opponentVocals.pause();
						opponentVocals.time = FlxG.sound.music.time;
					}

					var dastrum:Int = curSelectedNote != null ? curSelectedNote[0] : 0;
					var secStart:Float = sectionStartTime();
					var datime:Float = (feces - secStart) - (dastrum - secStart);

					if (curSelectedNote != null)
					{
						var controlArray:Array<Bool> =
						[
							FlxG.keys.pressed.ONE,
							FlxG.keys.pressed.TWO,
							FlxG.keys.pressed.THREE,
							FlxG.keys.pressed.FOUR,
							FlxG.keys.pressed.FIVE,
							FlxG.keys.pressed.SIX,
							FlxG.keys.pressed.SEVEN,
							FlxG.keys.pressed.EIGHT
						];

						if (controlArray.contains(true))
						{
							for (i in 0...controlArray.length)
							{
								if (controlArray[i]) {
									if (curSelectedNote[1] == i) curSelectedNote[2] += datime - curSelectedNote[2] - Conductor.stepCrochet;
								}
							}
					
							updateGrid();
							updateNoteUI();
						}
					}
				}
			}

			var shiftThing:Int = FlxG.keys.pressed.SHIFT ? 4 : 1;

			if (FlxG.keys.justPressed.RIGHT && !vortex || FlxG.keys.justPressed.D) {
				changeSection(curSec + shiftThing);
			}

			if (FlxG.keys.justPressed.LEFT && !vortex || FlxG.keys.justPressed.A)
			{
				if (curSec <= 0) {
					changeSection(_song.notes.length - 1);
				}
				else {
					changeSection(curSec - shiftThing);
				}
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		strumLineNotes.visible = quant.visible = vortex;

		if (FlxG.sound.music.time < 0)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
		}
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
	
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;

		strumLineUpdateY();
		camPos.y = strumLine.y;

		for (i in 0...8)
		{
			strumLineNotes.members[i].y = strumLine.y;
			strumLineNotes.members[i].alpha = FlxG.sound.music.playing ? 1 : 0.35;
		}

		var holdingShift:Bool = FlxG.keys.pressed.SHIFT;
	
		var holdingLB:Bool = FlxG.keys.pressed.LBRACKET;
		var holdingRB:Bool = FlxG.keys.pressed.RBRACKET;
		var pressedLB:Bool = FlxG.keys.justPressed.LBRACKET;
		var pressedRB:Bool = FlxG.keys.justPressed.RBRACKET;

		#if FLX_PITCH
		if (!holdingShift && pressedLB || holdingShift && holdingLB) playbackSpeed -= 0.01;
		if (!holdingShift && pressedRB || holdingShift && holdingRB) playbackSpeed += 0.01;
	
		if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB)) playbackSpeed = 1;
		if (playbackSpeed <= 0.5) playbackSpeed = 0.5;
		if (playbackSpeed >= 3) playbackSpeed = 3;

		FlxG.sound.music.pitch = playbackSpeed;

		if (vocals != null) vocals.pitch = playbackSpeed;
		if (hasOpponentVocals && opponentVocals != null) opponentVocals.pitch = playbackSpeed;
		#end

		var playedSound:Array<Bool> = [false, false, false, false]; // Prevents ouchy GF sex sounds

		curRenderedNotes.forEachAlive(function(note:Note):Void
		{
			note.alpha = 1;

			if (curSelectedNote != null)
			{
				var noteDataToCheck:Int = note.noteData;
				if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.pointers.length;

				if (curSelectedNote[0] == note.strumTime && ((curSelectedNote[2] == null && noteDataToCheck < 0) || (curSelectedNote[2] != null && curSelectedNote[1] == noteDataToCheck)))
				{
					colorSine += elapsed;

					var colorVal:Float = 0.7 + Math.sin(Math.PI * colorSine) * 0.3;
					note.color = FlxColor.fromRGBFloat(colorVal, colorVal, colorVal, 0.999); //Alpha can't be 100% or the color won't be updated for some reason, guess i will die
				}
			}

			if (note.strumTime <= Conductor.songPosition)
			{
				note.alpha = 0.4;

				if (note.strumTime > lastConductorPos && FlxG.sound.music.playing && note.noteData > -1)
				{
					var data:Int = note.noteData % Note.pointers.length;
					var noteDataToCheck:Int = note.noteData;

					if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.pointers.length;

					strumLineNotes.members[noteDataToCheck].playAnim('confirm', true);
					strumLineNotes.members[noteDataToCheck].resetAnim = ((note.sustainLength / 1000) + 0.15) / playbackSpeed;

					if (!playedSound[data])
					{
						if ((playSoundBf.checked && note.mustPress) || (playSoundDad.checked && !note.mustPress))
						{
							var soundToPlay:String = 'hitsound';

							if (_song.player1 == 'gf') { // Easter egg
								soundToPlay = 'GF_' + Std.string(data + 1);
							}
							
							if (soundToPlay != '') {
								FlxG.sound.play(Paths.getSound(soundToPlay)).pan = note.noteData < Note.pointers.length ? -0.3 : 0.3; // would be coolio
							}

							playedSound[data] = true;
						}

						data = note.noteData;

						if (note.mustPress != _song.notes[curSec].mustHitSection) {
							data += Note.pointers.length;
						}
					}
				}
			}
		});

		if (metronome.checked && lastConductorPos != Conductor.songPosition)
		{
			var metroInterval:Float = 60 / metronomeStepper.value;
			var metroStep:Int = Math.floor(((Conductor.songPosition + metronomeOffsetStepper.value) / metroInterval) / 1000);
			var lastMetroStep:Int = Math.floor(((lastConductorPos + metronomeOffsetStepper.value) / metroInterval) / 1000);

			if (metroStep != lastMetroStep) {
				FlxG.sound.play(Paths.getSound('Metronome_Tick'));
			}
		}

		lastConductorPos = Conductor.songPosition;
		updateText();

		super.update(elapsed);
	}

	function updateText():Void
	{
		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2)) +
			"\n\nSection: " + curSec +
			"\n\nBeat: " + Std.string(curDecBeat).substring(0,4) +
			"\nStep: " + curStep +
			"\n\nBeat Snap: " + quantization + "th";
	}

	function updateZoom():Void
	{
		var daZoom:Float = zoomList[curZoom];
		var zoomThing:String = '1 / ' + daZoom;
		if (daZoom < 1) zoomThing = Math.round(1 / daZoom) + ' / 1';

		zoomTxt.text = 'Zoom: ' + zoomThing;
		reloadGridLayer();
	}

	var lastSecBeats:Float = 0;
	var lastSecBeatsNext:Float = 0;

	function reloadGridLayer():Void
	{
		gridLayer.clear();
		gridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats() * 4 * zoomList[curZoom]));

		#if desktop
		if (FlxG.save.data.chart_waveformInst || FlxG.save.data.chart_waveformVoices) {
			updateWaveform();
		}
		#end

		var leHeight:Int = Std.int(gridBG.height);
		var foundNextSec:Bool = false;

		if (sectionStartTime(1) <= FlxG.sound.music.length)
		{
			nextGridBG = FlxGridOverlay.create(GRID_SIZE, GRID_SIZE, GRID_SIZE * 9, Std.int(GRID_SIZE * getSectionBeats(curSec + 1) * 4 * zoomList[curZoom]));

			leHeight = Std.int(gridBG.height + nextGridBG.height);
			foundNextSec = true;
		}
		else {
			nextGridBG = new FlxSprite().makeGraphic(1, 1, FlxColor.TRANSPARENT);
		}

		nextGridBG.y = gridBG.height;
		
		gridLayer.add(nextGridBG);
		gridLayer.add(gridBG);

		if (foundNextSec)
		{
			var gridBlack:Sprite = new Sprite(0, gridBG.height);
			gridBlack.makeGraphic(Std.int(GRID_SIZE * 9), Std.int(nextGridBG.height), FlxColor.BLACK);
			gridBlack.alpha = 0.4;
			gridLayer.add(gridBlack);
		}

		var gridBlackLine:Sprite = new Sprite(gridBG.x + gridBG.width - (GRID_SIZE * 4));
		gridBlackLine.makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		for (i in 1...4)
		{
			var beatsep1:FlxSprite = new FlxSprite(gridBG.x, (GRID_SIZE * (4 * curZoom)) * i).makeGraphic(Std.int(gridBG.width), 1, 0x44FF0000);

			if (vortex) {
				gridLayer.add(beatsep1);
			}
		}

		var gridBlackLine:Sprite = new Sprite(gridBG.x + GRID_SIZE);
		gridBlackLine.makeGraphic(2, leHeight, FlxColor.BLACK);
		gridLayer.add(gridBlackLine);

		updateGrid();

		lastSecBeats = getSectionBeats();

		if (sectionStartTime(1) > FlxG.sound.music.length) {
			lastSecBeatsNext = 0;
		}
		else {
			getSectionBeats(curSec + 1);
		}
	}

	function strumLineUpdateY():Void
	{
		strumLine.y = getYfromStrum((Conductor.songPosition - sectionStartTime()) / zoomList[curZoom] % (Conductor.stepCrochet * 16)) / (getSectionBeats() / 4);
	}

	var waveformPrinted:Bool = true;
	var wavData:Array<Array<Array<Float>>> = [[[0], [0]], [[0], [0]]];

	function updateWaveform():Void
	{
		#if desktop
		if (waveformPrinted)
		{
			waveformSprite.makeGraphic(Std.int(GRID_SIZE * 8), Std.int(gridBG.height), 0x00FFFFFF);
			waveformSprite.pixels.fillRect(new Rectangle(0, 0, gridBG.width, gridBG.height), 0x00FFFFFF);
		}

		waveformPrinted = false;

		if (!FlxG.save.data.chart_waveformInst && !FlxG.save.data.chart_waveformVoices) {
			return;
		}

		wavData[0][0] = [];
		wavData[0][1] = [];
		wavData[1][0] = [];
		wavData[1][1] = [];

		var steps:Int = Math.round(getSectionBeats() * 4);
		var st:Float = sectionStartTime();
		var et:Float = st + (Conductor.stepCrochet * steps);

		var sound:FlxSound = FlxG.sound.music;

		if (FlxG.save.data.chart_waveformVoices)
			sound = vocals;
		else if (FlxG.save.data.chart_waveformOppVoices && hasOpponentVocals)
			sound = opponentVocals;

		@:privateAccess
		if (sound != null && sound._sound.__buffer != null) {
			var bytes:Bytes = sound._sound.__buffer.data.toBytes();
			wavData = waveformData(
				sound._sound.__buffer,
				bytes,
				st,
				et,
				1,
				wavData,
				Std.int(gridBG.height)
			);
		}

		var gSize:Int = Std.int(GRID_SIZE * 8);
		var hSize:Int = Std.int(gSize / 2);

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var size:Float = 1;

		var leftLength:Int = (wavData[0][0].length > wavData[0][1].length ? wavData[0][0].length : wavData[0][1].length);

		var rightLength:Int = (wavData[1][0].length > wavData[1][1].length ? wavData[1][0].length : wavData[1][1].length);
		var length:Int = leftLength > rightLength ? leftLength : rightLength;

		var index:Int;

		for (i in 0...length)
		{
			index = i;

			lmin = CoolUtil.boundTo(((index < wavData[0][0].length && index >= 0) ? wavData[0][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			lmax = CoolUtil.boundTo(((index < wavData[0][1].length && index >= 0) ? wavData[0][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			rmin = CoolUtil.boundTo(((index < wavData[1][0].length && index >= 0) ? wavData[1][0][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;
			rmax = CoolUtil.boundTo(((index < wavData[1][1].length && index >= 0) ? wavData[1][1][index] : 0) * (gSize / 1.12), -hSize, hSize) / 2;

			waveformSprite.pixels.fillRect(new Rectangle(hSize - (lmin + rmin), i * size, (lmin + rmin) + (lmax + rmax), size), FlxColor.BLUE);
		}

		waveformPrinted = true;
		#end
	}

	function waveformData(buffer:AudioBuffer, bytes:Bytes, time:Float, endTime:Float, multiply:Float = 1, ?array:Array<Array<Array<Float>>>, ?steps:Float):Array<Array<Array<Float>>>
	{
		#if (lime_cffi && !macro)
		if (buffer == null || buffer.data == null) return [[[0], [0]], [[0], [0]]];

		var khz:Float = (buffer.sampleRate / 1000);
		var channels:Int = buffer.channels;

		var index:Int = Std.int(time * khz);

		var samples:Float = ((endTime - time) * khz);

		if (steps == null) steps = 1280;

		var samplesPerRow:Float = samples / steps;
		var samplesPerRowI:Int = Std.int(samplesPerRow);

		var gotIndex:Int = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;

		var simpleSample:Bool = true;//samples > 17200;
		var v1:Bool = false;

		if (array == null) array = [[[0], [0]], [[0], [0]]];

		while (index < (bytes.length - 1))
		{
			if (index >= 0)
			{
				var byte:Int = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample:Float = (byte / 65535);

				if (sample > 0) {
					if (sample > lmax) lmax = sample;
				}
				else if (sample < 0) {
					if (sample < lmin) lmin = sample;
				}

				if (channels >= 2)
				{
					byte = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					sample = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					}
					else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}

			v1 = samplesPerRowI > 0 ? (index % samplesPerRowI == 0) : false;

			while (simpleSample ? v1 : rows >= samplesPerRow)
			{
				v1 = false;
				rows -= samplesPerRow;

				gotIndex++;

				var lRMin:Float = Math.abs(lmin) * multiply;
				var lRMax:Float = lmax * multiply;

				var rRMin:Float = Math.abs(rmin) * multiply;
				var rRMax:Float = rmax * multiply;

				if (gotIndex > array[0][0].length)
					array[0][0].push(lRMin);
				else
					array[0][0][gotIndex - 1] = array[0][0][gotIndex - 1] + lRMin;

				if (gotIndex > array[0][1].length)
					array[0][1].push(lRMax);
				else
					array[0][1][gotIndex - 1] = array[0][1][gotIndex - 1] + lRMax;

				if (channels >= 2)
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(rRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + rRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(rRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + rRMax;
				}
				else
				{
					if (gotIndex > array[1][0].length)
						array[1][0].push(lRMin);
					else
						array[1][0][gotIndex - 1] = array[1][0][gotIndex - 1] + lRMin;

					if (gotIndex > array[1][1].length)
						array[1][1].push(lRMax);
					else
						array[1][1][gotIndex - 1] = array[1][1][gotIndex - 1] + lRMax;
				}

				lmin = 0;
				lmax = 0;

				rmin = 0;
				rmax = 0;
			}

			index++;
			rows++;

			if (gotIndex > steps) break;
		}

		return array;
		#else
		return [[[0], [0]], [[0], [0]]];
		#end
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
			}
		}

		updateNoteUI();
		updateGrid();
	}

	function recalculateSteps():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		};

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (FlxG.sound.music.time > Conductor.bpmChangeMap[i].songTime) {
				lastChange = Conductor.bpmChangeMap[i];
			}
		}

		curStep = lastChange.stepTime + Math.floor((FlxG.sound.music.time - lastChange.songTime) / Conductor.stepCrochet);
		updateBeat();

		return curStep;
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		updateGrid();

		FlxG.sound.music.pause();
		FlxG.sound.music.time = sectionStartTime();

		if (songBeginning)
		{
			FlxG.sound.music.time = 0;
			curSec = 0;
		}

		if (vocals != null)
		{
			vocals.pause();
			vocals.time = FlxG.sound.music.time;
		}

		updateCurStep();

		updateGrid();
		updateSectionUI();

		updateWaveform();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSec = sec;
	
			if (updateMusic)
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.time = sectionStartTime();
		
				if (vocals != null)
				{
					vocals.pause();
					vocals.time = FlxG.sound.music.time;
				}
		
				updateCurStep();
			}

			var blah1:Float = getSectionBeats();
			var blah2:Float = getSectionBeats(curSec + 1);

			if (sectionStartTime(1) > FlxG.sound.music.length) blah2 = 0;
	
			if (blah1 != lastSecBeats || blah2 != lastSecBeatsNext) {
				reloadGridLayer();
			}
			else {
				updateGrid();
			}
	
			updateSectionUI();
		}
		else {
			changeSection();
		}

		Conductor.songPosition = FlxG.sound.music.time;
		updateWaveform();
	}

	function updateSectionUI():Void
	{
		var sec:SwagSection = _song.notes[curSec];

		stepperBeats.value = getSectionBeats();

		check_mustHitSection.checked = sec.mustHitSection;
		check_gfSection.checked = sec.gfSection;
		check_altAnim.checked = sec.altAnim;
		check_changeBPM.checked = sec.changeBPM;
		stepperSectionBPM.value = sec.bpm;

		updateHeads();
	}

	var characterData = {
		iconP1: null,
		iconP2: null,
		vocalsP1: null,
		vocalsP2: null
	};

	function updateJsonData():Void
	{
		for (i in 1...3)
		{
			var data:CharacterFile = Character.getCharacterFile(Reflect.field(_song, 'player$i'));

			Reflect.setField(characterData, 'iconP$i', Character.characterExists(Reflect.field(_song, 'player$i')) ? data.healthicon : 'face');
			Reflect.setField(characterData, 'vocalsP$i', (data != null && data.vocals_file != null && data.vocals_file.length > 0) ? data.vocals_file : '');
		}
	}

	function updateHeads():Void
	{
		if (_song.notes[curSec].mustHitSection)
		{
			leftIcon.changeIcon(characterData.iconP1);
			rightIcon.changeIcon(characterData.iconP2);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		}
		else
		{
			leftIcon.changeIcon(characterData.iconP2);
			rightIcon.changeIcon(characterData.iconP1);
			if (_song.notes[curSec].gfSection) leftIcon.changeIcon('gf');
		}
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				stepperSusLength.value = curSelectedNote[2];

				if (curSelectedNote[3] != null)
				{
					currentType = curNoteTypes.indexOf(curSelectedNote[3]);

					if (currentType <= 0) {
						noteTypeDropDown.selectedLabel = '';
					}
					else {
						noteTypeDropDown.selectedLabel = currentType + '. ' + curSelectedNote[3];
					}
				}
			}
			else
			{
				eventDropDown.selectedLabel = curSelectedNote[1][curEventSelected][0];

				var selected:Int = Std.parseInt(eventDropDown.selectedId);

				if (selected > 0 && selected < eventStuff.length) {
					descText.text = eventStuff[selected][1];
				}

				value1InputText.text = curSelectedNote[1][curEventSelected][1];
				value2InputText.text = curSelectedNote[1][curEventSelected][2];
			}

			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid():Void
	{
		updateHeads();

		curRenderedNotes.forEachAlive((spr:Note) -> spr.destroy());
		curRenderedNotes.clear();

		curRenderedSustains.forEachAlive((spr:FlxSprite) -> spr.destroy());
		curRenderedSustains.clear();

		curRenderedNoteType.forEachAlive((spr:FlxText) -> spr.destroy());
		curRenderedNoteType.clear();

		nextRenderedNotes.forEachAlive((spr:Note) -> spr.destroy());
		nextRenderedNotes.clear();

		nextRenderedSustains.forEachAlive((spr:FlxSprite) -> spr.destroy());
		nextRenderedSustains.clear();

		if (_song.notes[curSec].changeBPM == true && _song.notes[curSec].bpm > 0) {
			Conductor.bpm = _song.notes[curSec].bpm;
		}
		else
		{
			var daBPM:Float = _song.bpm;
	
			for (i in 0...curSec)
			{
				if (_song.notes[i].changeBPM == true) {
					daBPM = _song.notes[i].bpm;
				}
			}
	
			Conductor.bpm = daBPM;
		}

		var beats:Float = getSectionBeats();

		for (i in _song.notes[curSec].sectionNotes)
		{
			var note:Note = setupNoteData(i, false);
			curRenderedNotes.add(note);

			if (note.sustainLength > 0) {
				curRenderedSustains.add(setupSusNote(note, beats));
			}

			if (i[3] != null && note.noteType != null && note.noteType.length > 0)
			{
				var typeInt:Int = curNoteTypes.indexOf(i[3]);
				var theType:String = '' + typeInt;
				if (typeInt < 0) theType = '?';

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 100, theType, 24);
				daText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				daText.xAdd = -32;
				daText.yAdd = 6;
				daText.borderSize = 1;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		var startThing:Float = sectionStartTime();
		var endThing:Float = sectionStartTime(1);

		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, false);
				curRenderedNotes.add(note);

				var text:String = 'Event: ' + note.eventName + ' (' + Math.floor(note.strumTime) + ' ms)' + '\nValue 1: ' + note.eventVal1 + '\nValue 2: ' + note.eventVal2;
				if (note.eventLength > 1) text = note.eventLength + ' Events:\n' + note.eventName;

				var daText:AttachedFlxText = new AttachedFlxText(0, 0, 400, text, 12);
				daText.setFormat(Paths.getFont('vcr.ttf'), 12, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
				daText.xAdd = -410;
				daText.borderSize = 1;
				if (note.eventLength > 1) daText.yAdd += 8;
				curRenderedNoteType.add(daText);
				daText.sprTracker = note;
			}
		}

		var beats:Float = getSectionBeats(1);

		if (curSec < _song.notes.length - 1)
		{
			for (i in _song.notes[curSec + 1].sectionNotes)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);

				if (note.sustainLength > 0) {
					nextRenderedSustains.add(setupSusNote(note, beats));
				}
			}
		}

		var startThing:Float = sectionStartTime(1);
		var endThing:Float = sectionStartTime(2);

		for (i in _song.events)
		{
			if (endThing > i[0] && i[0] >= startThing)
			{
				var note:Note = setupNoteData(i, true);
				note.alpha = 0.6;
				nextRenderedNotes.add(note);
			}
		}
	}

	function setupNoteData(i:Array<Dynamic>, isNextSection:Bool):Note
	{
		var daNoteInfo:Int = i[1];
		var daStrumTime:Float = i[0];

		var daSus:Dynamic = i[2];

		var note:Note = new Note(daStrumTime, daNoteInfo % Note.pointers.length, null, null, true);

		if (daSus != null) // Common note
		{
			if (!Std.isOfType(i[3], String)) { // Convert old note type to new note type format
				i[3] = curNoteTypes[i[3]];
			}

			if (i.length > 3 && (i[3] == null || i[3].length < 1)) {
				i.remove(i[3]);
			}

			note.sustainLength = daSus;

			note.mustPress = _song.notes[curSec + (isNextSection ? 1 : 0)].mustHitSection;
			if (i[1] > 3) note.mustPress = !note.mustPress;

			note.texture = null;
			note.noteType = i[3];
		}
		else // Event note
		{
			if (Paths.fileExists('images/eventArrow.png', IMAGE)) {
				note.loadGraphic(Paths.getImage('eventArrow'));
			}
			else {
				note.loadGraphic(Paths.getImage('ui/eventArrow'));
			}
			
			note.rgbShader.enabled = false;
			note.eventName = getEventName(i[1]);
			note.eventLength = i[1].length;

			if (i[1].length < 2)
			{
				note.eventVal1 = i[1][0][1];
				note.eventVal2 = i[1][0][2];
			}

			note.noteData = -1;
			daNoteInfo = -1;
		}

		note.setGraphicSize(GRID_SIZE, GRID_SIZE);
		note.updateHitbox();
		note.x = Math.floor(daNoteInfo * GRID_SIZE) + GRID_SIZE;

		if (isNextSection && _song.notes[curSec].mustHitSection != _song.notes[curSec + 1].mustHitSection)
		{
			if (daNoteInfo > Note.pointers.length - 1) {
				note.x -= GRID_SIZE * Note.pointers.length;
			}
			else if (daSus != null) {
				note.x += GRID_SIZE * Note.pointers.length;
			}
		}

		var beats:Float = getSectionBeats(isNextSection ? 1 : 0);
		note.y = getYfromStrumNotes(daStrumTime - sectionStartTime(), beats);

		if (note.y < -150) note.y = -150;
		return note;
	}

	function getEventName(names:Array<Dynamic>):String
	{
		var retStr:String = '';
		var addedOne:Bool = false;

		for (i in 0...names.length)
		{
			if (addedOne) retStr += ', ';

			retStr += names[i][0];
			addedOne = true;
		}

		return retStr;
	}

	function setupSusNote(note:Note, beats:Float):Sprite
	{
		var height:Int = Math.floor(FlxMath.remapToRange(note.sustainLength, 0, Conductor.stepCrochet * 16, 0, GRID_SIZE * 16 * zoomList[curZoom]) + (GRID_SIZE * zoomList[curZoom]) - GRID_SIZE / 2);
		var minHeight:Int = Std.int((GRID_SIZE * zoomList[curZoom] / 2) + GRID_SIZE / 2);

		if (height < minHeight) height = minHeight;
		if (height < 1) height = 1; //Prevents error of invalid height

		var spr:Sprite = new Sprite(note.x + (GRID_SIZE * 0.5) - 4, note.y + GRID_SIZE / 2);
		spr.makeGraphic(8, height);
		return spr;
	}

	private function addSection(sectionBeats:Float = 4):Void
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			gfSection: false,
			altAnim: false
		};

		_song.notes.push(sec);
	}

	private function newSection(sectionBeats:Float = 4, mustHitSection:Bool = true, altAnim:Bool = false, gfSection:Bool = false):SwagSection
	{
		var sec:SwagSection = {
			sectionBeats: sectionBeats,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			gfSection: gfSection,
			altAnim: altAnim
		};

		return sec;
	}

	function selectNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.pointers.length;

		if (noteDataToCheck > -1)
		{
			if (note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.pointers.length;

			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i != curSelectedNote && i.length > 2 && i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					curSelectedNote = i;
					break;
				}
			}
		}
		else
		{
			for (i in _song.events)
			{
				if (i != curSelectedNote && i[0] == note.strumTime)
				{
					curSelectedNote = i;
					curEventSelected = Std.int(curSelectedNote[1].length) - 1;

					break;
				}
			}
		}

		changeEventSelected();

		updateGrid();
		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		var noteDataToCheck:Int = note.noteData;
		if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSec].mustHitSection) noteDataToCheck += Note.pointers.length;

		if (note.noteData > -1) // Normal Notes
		{
			for (i in _song.notes[curSec].sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == noteDataToCheck)
				{
					if (i == curSelectedNote) curSelectedNote = null;

					_song.notes[curSec].sectionNotes.remove(i);
					break;
				}
			}
		}
		else // Events
		{
			for (i in _song.events)
			{
				if (i[0] == note.strumTime)
				{
					if (i == curSelectedNote)
					{
						curSelectedNote = null;
						changeEventSelected();
					}

					_song.events.remove(i);
					break;
				}
			}
		}

		updateGrid();
	}

	public function doANoteThing(cs, d, style)
	{
		var delnote = false;

		if (strumLineNotes.members[d].overlaps(curRenderedNotes))
		{
			curRenderedNotes.forEachAlive(function(note:Note):Void
			{
				if (note.overlapsPoint(FlxPoint.get(strumLineNotes.members[d].x + 1, strumLine.y + 1)) && note.noteData == d % Note.pointers.length)
				{
					if (!delnote) deleteNote(note);
					delnote = true;
				}
			});
		}
		
		if (!delnote) {
			addNote(cs, d, style);
		}
	}

	function clearSection():Void
	{
		_song.notes[curSec].sectionNotes = [];
		updateGrid();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length) {
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function addNote(strum:Null<Float> = null, data:Null<Int> = null, type:Null<Int> = null):Void
	{
		var noteStrum:Float = getStrumTime(dummyArrow.y * (getSectionBeats() / 4), false) + sectionStartTime();
		var noteData:Int = Math.floor((FlxG.mouse.x - GRID_SIZE) / GRID_SIZE);
		var noteSus:Int = 0;
		var daType:Int = currentType;

		if (strum != null) noteStrum = strum;
		if (data != null) noteData = data;
		if (type != null) daType = type;

		if (noteData > -1)
		{
			_song.notes[curSec].sectionNotes.push([noteStrum, noteData, noteSus, curNoteTypes[daType]]);
			curSelectedNote = _song.notes[curSec].sectionNotes[_song.notes[curSec].sectionNotes.length - 1];
		}
		else
		{
			var event = eventStuff[Std.parseInt(eventDropDown.selectedId)][0];
			var text1 = value1InputText.text;
			var text2 = value2InputText.text;
	
			_song.events.push([noteStrum, [[event, text1, text2]]]);
	
			curSelectedNote = _song.events[_song.events.length - 1];
			curEventSelected = 0;
		}

		changeEventSelected();

		if (FlxG.keys.pressed.CONTROL && noteData > -1) {
			_song.notes[curSec].sectionNotes.push([noteStrum, (noteData + Note.pointers.length) % Math.floor(Note.pointers.length * 2), noteSus, curNoteTypes[daType]]);
		}

		strumTimeInputText.text = '' + curSelectedNote[0];

		updateGrid();
		updateNoteUI();
	}

	function getStrumTime(yPos:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = !doZoomCalc ? 1 : zoomList[curZoom];
		return FlxMath.remapToRange(yPos, gridBG.y, gridBG.y + gridBG.height * leZoom, 0, 16 * Conductor.stepCrochet);
	}

	function getYfromStrum(strumTime:Float, doZoomCalc:Bool = true):Float
	{
		var leZoom:Float = (!doZoomCalc ? 1 : zoomList[curZoom]);
		return FlxMath.remapToRange(strumTime, 0, 16 * Conductor.stepCrochet, gridBG.y, gridBG.y + gridBG.height * leZoom);
	}
	
	function getYfromStrumNotes(strumTime:Float, beats:Float):Float
	{
		var value:Float = strumTime / (beats * 4 * Conductor.stepCrochet);
		return GRID_SIZE * beats * 4 * zoomList[curZoom] * value + gridBG.y;
	}

	function getNotes():Array<Dynamic>
	{
		return [for (i in _song.notes) i.sectionNotes];
	}

	function loadJson(song:String):Void
	{
		var songPath:String = Paths.formatToSongPath(song);
		var songFile:String = songPath + CoolUtil.difficultyStuff[PlayState.lastDifficulty][2];

		if (Paths.fileExists('data/' + songPath + '/' + songFile + '.json', TEXT))
		{
			PlayState.SONG = Song.loadFromJson(songFile, songPath);
			LoadingState.loadAndSwitchState(new ChartingState(), true);
		}
		else if (Paths.fileExists('data/' + songPath + '/' + songPath + '.json', TEXT))
		{
			PlayState.SONG = Song.loadFromJson(songPath, songPath);
			LoadingState.loadAndSwitchState(new ChartingState(), true);
		}
		else {
			Debug.logWarn('File not found!');
		}
	}

	function loadAutosave():Void
	{
		PlayState.SONG = Song.parseJSONshit(FlxG.save.data.autosave);

		StageData.loadDirectory(_song);
		LoadingState.loadAndSwitchState(new ChartingState(), true);
	}

	function autosaveSong():Void
	{
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});

		FlxG.save.flush();
	}

	function clearEvents():Void
	{
		_song.events = [];
		updateGrid();
	}

	private function saveLevel():Void
	{
		if (_song.events != null && _song.events.length > 0) _song.events.sort(sortByTime);

		var json:Dynamic = {
			"song": _song
		};

		var data:String = Json.stringify(json, '\t');

		if (data != null && data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			var songFile:String = CoolUtil.formatSong(_song.songID, PlayState.lastDifficulty);
			_file.save(data.trim(), songFile + '.json');
		}
	}

	function sortByTime(obj1:Array<Dynamic>, obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1[0], obj2[0]);
	}

	private function saveEvents():Void
	{
		if (_song.events != null && _song.events.length > 0) _song.events.sort(sortByTime);

		var eventsSong:Dynamic = {
			events: _song.events
		};

		var json:Dynamic = {
			"song": eventsSong
		}

		var data:String = Json.stringify(json, "\t");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), 'events.json');
		}
	}

	function onSaveComplete(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;

		Debug.logInfo("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;

		Debug.logError("Problem saving Level data");
	}

	function getSectionBeats(?section:Null<Int> = null):Null<Float>
	{
		if (section == null) section = curSec;

		if (_song.notes[section] != null && _song.notes[section].sectionBeats > 0) {
			return _song.notes[section].sectionBeats;
		}

		return 4;
	}
}

class AttachedFlxText extends FlxText
{
	public var sprTracker:FlxSprite;

	public var xAdd:Float = 0;
	public var yAdd:Float = 0;

	public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true):Void {
		super(X, Y, FieldWidth, Text, Size, EmbeddedFont);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);

			angle = sprTracker.angle;
			alpha = sprTracker.alpha;
		}
	}
}