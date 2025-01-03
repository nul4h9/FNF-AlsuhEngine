package editors;

import haxe.Json;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Achievements;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

class AchievementEditorState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	var award:Achievement = null;

	var icon:AttachedAchievement = null;
	var text:Alphabet = null;
	var bg:Sprite = null;

	private var descBox:Sprite = null;
	private var descText:FlxText = null;

	override function create():Void
	{
		if (award == null) {
			award = Achievements.dummy();
		}

		bg = new Sprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		text = new Alphabet(280, 270, award.name, false);
		add(text);

		icon = new AttachedAchievement(text.x - 105, text.y, award.save_tag);
		icon.sprTracker = text;
		add(icon);

		descBox = new Sprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		addEditorBox();
		reloadAllShit();

		super.create();

		FlxG.mouse.visible = !controls.controllerMode;
	}

	var UI_box:FlxUITabMenu = null;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Achievement', label: 'Achievement'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 375);
		UI_box.x = 1020;
		UI_box.y = 193;
		UI_box.scrollFactor.set();

		addAwardUI();

		UI_box.selected_tab_id = 'Achievement';
		add(UI_box);
	}

	var diffInputText:FlxUIInputText = null;
	var awardNameInputText:FlxUIInputText = null;
	var tagInputText:FlxUIInputText = null;
	var descInputText:FlxUIInputText = null;
	var luaFileInputText:FlxUIInputText = null;
	var hxFileInputText:FlxUIInputText = null;
	var weekInputText:FlxUIInputText = null;
	var indexStepper:FlxUINumericStepper = null;
	var bgColorStepperR:FlxUINumericStepper = null;
	var bgColorStepperG:FlxUINumericStepper = null;
	var bgColorStepperB:FlxUINumericStepper = null;
	var hiddenCheckbox:FlxUICheckBox = null;
	var songInputText:FlxUIInputText = null;
	var missesStepper:FlxUINumericStepper = null;
	var maxScoreStepper:FlxUINumericStepper = null;

	var loadButton:FlxButton = null;
	var saveButton:FlxButton = null;
	var resetButton:FlxButton = null;

	function addAwardUI():Void
	{
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Achievement";

		awardNameInputText = new FlxUIInputText(10, 25, 150, award.name, 8);
		blockPressWhileTypingOn.push(awardNameInputText);

		tagInputText = new FlxUIInputText(10, awardNameInputText.y + 40, 75, award.save_tag, 8);
		blockPressWhileTypingOn.push(tagInputText);

		descInputText = new FlxUIInputText(10, tagInputText.y + 40, 150, award.desc, 8);
		blockPressWhileTypingOn.push(descInputText);

		luaFileInputText = new FlxUIInputText(10, descInputText.y + 40, 70, award.lua_code, 8);
		blockPressWhileTypingOn.push(luaFileInputText);

		weekInputText = new FlxUIInputText(10, luaFileInputText.y + 40, 100, award.week_nomiss, 8);
		blockPressWhileTypingOn.push(weekInputText);

		indexStepper = new FlxUINumericStepper(weekInputText.x + weekInputText.width + 72, awardNameInputText.y, 1, award.index, -1);
		blockPressWhileTypingOnStepper.push(indexStepper);

		bgColorStepperR = new FlxUINumericStepper(10, weekInputText.y + 40, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperR);
		
		bgColorStepperG = new FlxUINumericStepper(bgColorStepperR.x + 86, bgColorStepperR.y, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperG);

		bgColorStepperB = new FlxUINumericStepper(bgColorStepperG.x + 86, bgColorStepperG.y, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperB);

		hiddenCheckbox = new FlxUICheckBox(10, bgColorStepperR.y + 35, null, null, 'Is Hidden?', 100, function():Void {
			award.hidden = hiddenCheckbox.checked == true;
		});

		songInputText = new FlxUIInputText(hiddenCheckbox.x + hiddenCheckbox.width + 25, hiddenCheckbox.y + 5, 84, award.song, 8);
		blockPressWhileTypingOn.push(songInputText);

		loadButton = new FlxButton(32, songInputText.y + 30, 'Load', loadAchievement);
		saveButton = new FlxButton(loadButton.x + loadButton.width + 20, loadButton.y, 'Save', saveAchievement);

		resetButton = new FlxButton(loadButton.x + loadButton.width - 30, loadButton.y + loadButton.height + 5, 'Reset', function():Void
		{
			award = Achievements.dummy();
			reloadAllShit();
		});

		diffInputText = new FlxUIInputText(songInputText.x, weekInputText.y, 75, award.diff, 8);

		missesStepper = new FlxUINumericStepper(tagInputText.x + tagInputText.width + 96, tagInputText.y + 15, 1, award.misses, -1);
		blockPressWhileTypingOnStepper.push(missesStepper);

		hxFileInputText = new FlxUIInputText(luaFileInputText.x + luaFileInputText.width + 10, luaFileInputText.y, 70, award.hx_code, 8);
		blockPressWhileTypingOn.push(hxFileInputText);

		maxScoreStepper = new FlxUINumericStepper(missesStepper.x, descInputText.y + 40, 0.01, award.maxScore, 0, 999, 2);
		blockPressWhileTypingOnStepper.push(maxScoreStepper);

		tab_group.add(awardNameInputText);
		tab_group.add(tagInputText);
		tab_group.add(descInputText);
		tab_group.add(maxScoreStepper);
		tab_group.add(luaFileInputText);
		tab_group.add(hxFileInputText);
		tab_group.add(weekInputText);
		tab_group.add(indexStepper);
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(hiddenCheckbox);
		tab_group.add(songInputText);
		tab_group.add(diffInputText);
		tab_group.add(missesStepper);

		tab_group.add(loadButton);
		tab_group.add(saveButton);
		tab_group.add(resetButton);

		tab_group.add(new FlxText(awardNameInputText.x, awardNameInputText.y - 18, 0, 'Achievement name:'));
		tab_group.add(new FlxText(tagInputText.x, tagInputText.y - 18, 0, 'Achievement save tag:'));
		tab_group.add(new FlxText(descInputText.x, descInputText.y - 18, 0, 'Achievement description:'));
		tab_group.add(new FlxText(luaFileInputText.x, luaFileInputText.y - 18, 0, 'Lua file:'));
		tab_group.add(new FlxText(hxFileInputText.x, hxFileInputText.y - 18, 0, 'HX file:'));
		tab_group.add(new FlxText(weekInputText.x, weekInputText.y - 18, 0, 'Week ID to unlock:'));
		tab_group.add(new FlxText(indexStepper.x, indexStepper.y - 18, 0, 'Index:'));
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(songInputText.x, songInputText.y - 18, 0, 'Song ID to unlock:'));
		tab_group.add(new FlxText(diffInputText.x - 25, diffInputText.y - 18, 0, 'Difficulty ID to unlock:'));
		tab_group.add(new FlxText(missesStepper.x - 10, missesStepper.y - 26, 0, 'Minimal Misses\n(-1 to disable):'));
		tab_group.add(new FlxText(maxScoreStepper.x - 10, maxScoreStepper.y - 26, 0, 'Max Score\n(0 to disable):'));

		UI_box.addGroup(tab_group);
	}

	function reloadAllShit():Void
	{
		awardNameInputText.text = award.name;
		tagInputText.text = award.save_tag;
		descInputText.text = award.desc;
		luaFileInputText.text = award.lua_code;
		hxFileInputText.text = award.hx_code;
		diffInputText.text = award.diff;
		weekInputText.text = award.week_nomiss;
		indexStepper.value = award.index;
		missesStepper.value = award.misses;
		maxScoreStepper.value = award.maxScore;
		bgColorStepperR.value = award.color[0];
		bgColorStepperG.value = award.color[1];
		bgColorStepperB.value = award.color[2];
		hiddenCheckbox.checked = award.hidden;
		songInputText.text = award.song;

		award.name = awardNameInputText.text.trim();
		text.text = award.name; // lol

		if (tagInputText.text == null) {
			tagInputText.text = '';
		}

		award.save_tag = tagInputText.text.trim();
		icon.changeAchievement(award.save_tag, true);

		award.desc = descInputText.text.trim();

		descText.text = award.desc;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		var visible:Bool = award.desc != null && award.desc.length > 0;

		descText.visible = visible;
		descBox.visible = visible;

		updateBG();
	}

	function updateBG():Void
	{
		bg.color = FlxColor.fromRGB(award.color[0], award.color[1], award.color[2]);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == awardNameInputText)
			{
				award.name = awardNameInputText.text.trim();
				text.text = award.name; // lol

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Achievement Editor", "Editting: " + award.name); // Updating Discord Rich Presence
				#end
			}
			else if (sender == tagInputText)
			{
				if (tagInputText.text == null) {
					tagInputText.text = '';
				}
		
				award.save_tag = tagInputText.text.trim();
				icon.changeAchievement(award.save_tag, true);
			}
			else if (sender == descInputText)
			{
				award.desc = descInputText.text.trim();

				descText.text = award.desc;
				descText.screenCenter(Y);
				descText.y += 270;
		
				descBox.setPosition(descText.x - 10, descText.y - 10);
				descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
				descBox.updateHitbox();

				var visible:Bool = award.desc != null && award.desc.length > 0;

				descText.visible = visible;
				descBox.visible = visible;
			}
			else if (sender == luaFileInputText) {
				award.lua_code = luaFileInputText.text.trim();
			}
			else if (sender == hxFileInputText) {
				award.hx_code = hxFileInputText.text.trim();
			}
			else if (sender == diffInputText) {
				award.diff = diffInputText.text.trim();
			}
			else if (sender == weekInputText) {
				award.week_nomiss = weekInputText.text.trim();
			}
			else if (sender == songInputText) {
				award.song = songInputText.text.trim();
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB)
			{
				award.color[0] = Math.round(bgColorStepperR.value);
				award.color[1] = Math.round(bgColorStepperG.value);
				award.color[2] = Math.round(bgColorStepperB.value);

				updateBG();
			}
			else if (sender == indexStepper) {
				award.index = Math.round(indexStepper.value);
			}
			else if (sender == missesStepper) {
				award.misses = Math.round(missesStepper.value);
			}
			else if (sender == missesStepper) {
				award.maxScore = maxScoreStepper.value;
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];

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

			ClientPrefs.toggleVolumeKeys(true);

			if (FlxG.keys.justPressed.ESCAPE) {
				FlxG.switchState(new MasterEditorMenu());
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

		super.update(elapsed);
	}

	var _file:FileReference = null;

	function loadAchievement():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');

		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null) fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);

			if (rawJson != null)
			{
				var loadedAchievement:Achievement = Achievements.getFile(fullPath);
				var cutName:String = _file.name.substr(0, _file.name.length - 5);

				try
				{
					Debug.logInfo("Successfully loaded file: " + cutName);
					award = loadedAchievement;

					reloadAllShit();
				}
				catch (e:Dynamic) {
					Debug.logError("Cannot load file " + cutName);
				}

				_file = null;
			}
		}

		_file = null;
		#else
		Debug.logError("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(event:Event):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logInfo("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(event:Event):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logError("Problem loading file");
	}

	function saveAchievement():Void
	{
		var data:String = Json.stringify(award, '\t');

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), 'achievements/' + award.save_tag + '.json');
		}
	}

	function onSaveComplete(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		Debug.logInfo("Successfully saved file.");
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

		Debug.logError("Problem saving file");
	}
	#end
}