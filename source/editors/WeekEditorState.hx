package editors;

import haxe.Json;

#if sys
import sys.io.File;
#end

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import WeekData;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import lime.system.Clipboard;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUITabMenu;
import flixel.animation.FlxAnimation;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.interfaces.IFlxUIWidget;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class WeekEditorState extends MusicBeatState
{
	public static var weekFileName:String = 'week1';

	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null):Void
	{
		super();

		this.weekFile = WeekData.createWeekFile();

		if (weekFile != null) {
			this.weekFile = weekFile;
		}
		else {
			weekFileName = 'week1';
		}

		WeekData.onLoadJson(this.weekFile, weekFileName);
	}

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	var bgSprite:Sprite;
	var lock:AttachedSprite;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var txtWeekTitle:FlxText;
	var weekThing:MenuItem;
	var missingFileText:FlxText;
	var txtTracklist:FlxText;

	override function create():Void
	{
		if (FlxG.sound.music != null && (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'), 0);
		}

		persistentUpdate = true;

		var path:String = 'storymenu/campaign_menu_UI_assets';
		if (Paths.fileExists('images/campaign_menu_UI_assets.png', IMAGE)) path = 'campaign_menu_UI_assets';

		var blackBarThingie:Sprite = new Sprite();
		blackBarThingie.makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10);
		txtWeekTitle.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		add(txtWeekTitle);

		var bgYellow:Sprite = new Sprite(0, 56);
		bgYellow.makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		add(bgYellow);

		bgSprite = new Sprite(0, 56);
		add(bgSprite);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		add(grpWeekCharacters);

		weekThing = new MenuItem(0, bgYellow.y + 396, weekFile.itemFile);
		weekThing.screenCenter(X);
		weekThing.snapToPosition();
		weekThing.inEditor = true;
		add(weekThing);

		lock = new AttachedSprite(path, 'lock');
		lock.xAdd = weekThing.width + 10;
		lock.sprTracker = weekThing;
		add(lock);

		missingFileText = new FlxText(0, 0, FlxG.width, '');
		missingFileText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText); 

		var charArray:Array<String> = weekFile.weekCharacters;

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		var tracksSprite:Sprite = new Sprite(FlxG.width * 0.07, bgYellow.y + 425);

		var path2:String = 'storymenu/Menu_Tracks';
		if (Paths.fileExists('images/Menu_Tracks.png', IMAGE)) path2 = 'Menu_Tracks';

		tracksSprite.loadGraphic(Paths.getImage(path2));
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60);
		txtTracklist.setFormat(Paths.getFont('vcr.ttf'), 32, 0xFFe55777, CENTER);
		add(txtTracklist);

		addEditorBox();
		reloadAllShit();

		super.create();
	}

	var UI_box:FlxUITabMenu;

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Week', label: 'Week'},
			{name: 'Other', label: 'Other'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 375);
		UI_box.x = FlxG.width - UI_box.width;
		UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();

		addWeekUI();
		addOtherUI();
		
		UI_box.selected_tab_id = 'Week';
		add(UI_box);

		var loadWeekButton:FlxButton = new FlxButton(0, 650, "Load Week", loadWeek);
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var freeplayButton:FlxButton = new FlxButton(0, 650, "Freeplay", function():Void {
			FlxG.switchState(new WeekEditorFreeplayState(weekFile));
		});
		freeplayButton.screenCenter(X);
		add(freeplayButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 650, "Save Week", function():Void {
			saveWeek(weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	var songIdsInputText:FlxUIInputText;
	var songNamesInputText:FlxUIInputText;

	var backgroundInputText:FlxUIInputText;
	var displayNameInputText:FlxUIInputText;
	var weekIDInputText:FlxUIInputText;
	var weekNameInputText:FlxUIInputText;
	var itemFileInputText:FlxUIInputText;

	var opponentInputText:FlxUIInputText;
	var boyfriendInputText:FlxUIInputText;
	var girlfriendInputText:FlxUIInputText;

	var hideCheckbox:FlxUICheckBox;

	function addWeekUI():Void
	{
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Week";

		songIdsInputText = new FlxUIInputText(10, 30, 200, '', 8);
		blockPressWhileTypingOn.push(songIdsInputText);

		songNamesInputText = new FlxUIInputText(10, songIdsInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(songNamesInputText);

		opponentInputText = new FlxUIInputText(10, songNamesInputText.y + 40, 70, '', 8);
		blockPressWhileTypingOn.push(opponentInputText);

		boyfriendInputText = new FlxUIInputText(opponentInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(boyfriendInputText);

		girlfriendInputText = new FlxUIInputText(boyfriendInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(girlfriendInputText);

		backgroundInputText = new FlxUIInputText(10, opponentInputText.y + 40, 120, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);
		
		displayNameInputText = new FlxUIInputText(10, backgroundInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);

		weekIDInputText = new FlxUIInputText(10, displayNameInputText.y + 40, 80, '', 8);
		blockPressWhileTypingOn.push(weekIDInputText);

		weekNameInputText = new FlxUIInputText(10, weekIDInputText.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(weekNameInputText);

		itemFileInputText = new FlxUIInputText(10, weekNameInputText.y + 45, 80, '', 8);
		blockPressWhileTypingOn.push(itemFileInputText);

		hideCheckbox = new FlxUICheckBox(itemFileInputText.x + itemFileInputText.width + 10, itemFileInputText.y, null, null, "Hide Week from\nStory Mode?", 100);
		hideCheckbox.callback = function():Void {
			weekFile.hideStoryMode = hideCheckbox.checked;
		}

		tab_group.add(new FlxText(songIdsInputText.x, songIdsInputText.y - 18, 0, 'Songs IDs:'));
		tab_group.add(new FlxText(songNamesInputText.x, songNamesInputText.y - 18, 0, 'Songs Names:'));
		tab_group.add(new FlxText(opponentInputText.x, opponentInputText.y - 18, 0, 'Characters:'));
		tab_group.add(new FlxText(backgroundInputText.x, backgroundInputText.y - 18, 0, 'Background Asset:'));
		tab_group.add(new FlxText(displayNameInputText.x, displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(weekIDInputText.x, weekIDInputText.y - 18, 0, 'Week ID:'));
		tab_group.add(new FlxText(weekNameInputText.x, weekNameInputText.y - 18, 0, 'Week Name:'));
		tab_group.add(new FlxText(itemFileInputText.x, itemFileInputText.y - 18, 0, 'Item file name:'));

		tab_group.add(songIdsInputText);
		tab_group.add(songNamesInputText);
		tab_group.add(opponentInputText);
		tab_group.add(boyfriendInputText);
		tab_group.add(girlfriendInputText);
		tab_group.add(backgroundInputText);
		tab_group.add(displayNameInputText);
		tab_group.add(weekIDInputText);
		tab_group.add(weekNameInputText);
		tab_group.add(itemFileInputText);
		tab_group.add(hideCheckbox);

		UI_box.addGroup(tab_group);
	}

	var weekBeforeInputText:FlxUIInputText;
	var defaultDifficultyInputText:FlxUIInputText;
	var difficultiesIDsInputText:FlxUIInputText;
	var difficultiesNamesInputText:FlxUIInputText;
	var difficultiesSuffixesInputText:FlxUIInputText;
	var lockedCheckbox:FlxUICheckBox;
	var hiddenUntilUnlockCheckbox:FlxUICheckBox;

	var itemColorStepperR:FlxUINumericStepper;
	var itemColorStepperG:FlxUINumericStepper;
	var itemColorStepperB:FlxUINumericStepper;

	function addOtherUI():Void
	{
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Other";

		lockedCheckbox = new FlxUICheckBox(10, 15, null, null, "Week starts Locked", 100);
		lockedCheckbox.callback = function():Void
		{
			weekFile.startUnlocked = !lockedCheckbox.checked;
			lock.visible = lockedCheckbox.checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);
		}

		hiddenUntilUnlockCheckbox = new FlxUICheckBox(10, lockedCheckbox.y + 25, null, null, "Hidden until Unlocked", 110);
		hiddenUntilUnlockCheckbox.callback = function():Void {
			weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
		}
		hiddenUntilUnlockCheckbox.alpha = 0.4;

		weekBeforeInputText = new FlxUIInputText(10, hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);
		blockPressWhileTypingOn.push(weekBeforeInputText);

		defaultDifficultyInputText = new FlxUIInputText(10, weekBeforeInputText.y + 40, 70, '', 8);
		blockPressWhileTypingOn.push(defaultDifficultyInputText);

		difficultiesIDsInputText = new FlxUIInputText(10, defaultDifficultyInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesIDsInputText);

		difficultiesNamesInputText = new FlxUIInputText(10, difficultiesIDsInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesNamesInputText);

		difficultiesSuffixesInputText = new FlxUIInputText(10, difficultiesNamesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesSuffixesInputText);

		itemColorStepperR = new FlxUINumericStepper(10, difficultiesSuffixesInputText.y + 65, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(itemColorStepperR);

		itemColorStepperG = new FlxUINumericStepper(80, difficultiesSuffixesInputText.y + 65, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(itemColorStepperG);

		itemColorStepperB = new FlxUINumericStepper(150, difficultiesSuffixesInputText.y + 65, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(itemColorStepperB);

		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(defaultDifficultyInputText.x, defaultDifficultyInputText.y - 20, 0, 'Default Difficulty ID:'));
		tab_group.add(new FlxText(difficultiesIDsInputText.x, difficultiesIDsInputText.y - 20, 0, 'Difficulties IDs:'));
		tab_group.add(new FlxText(difficultiesNamesInputText.x, difficultiesNamesInputText.y - 20, 0, 'Difficulties Names:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y - 20, 0, 'Difficulties Suffixes:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));
		tab_group.add(new FlxText(10, itemColorStepperR.y - 18, 0, 'Selected item flashing color R/G/B:'));

		tab_group.add(weekBeforeInputText);
		tab_group.add(defaultDifficultyInputText);
		tab_group.add(difficultiesIDsInputText);
		tab_group.add(difficultiesNamesInputText);
		tab_group.add(difficultiesSuffixesInputText);
		tab_group.add(itemColorStepperR);
		tab_group.add(itemColorStepperG);
		tab_group.add(itemColorStepperB);
		tab_group.add(hiddenUntilUnlockCheckbox);
		tab_group.add(lockedCheckbox);

		UI_box.addGroup(tab_group);
	}

	function reloadAllShit():Void
	{
		var songs:Array<WeekSong> = weekFile.songs;

		songIdsInputText.text = [for (i in songs) i.songID].join(', ');
		songNamesInputText.text = [for (i in songs) i.songName].join(', ');

		itemFileInputText.text = weekFile.itemFile;
		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekIDInputText.text = weekFile.weekID;
		weekNameInputText.text = weekFile.weekName;

		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];

		itemColorStepperR.value = weekFile.itemColor[0];
		itemColorStepperG.value = weekFile.itemColor[1];
		itemColorStepperB.value = weekFile.itemColor[2];

		hideCheckbox.checked = weekFile.hideStoryMode;
		weekBeforeInputText.text = weekFile.weekBefore;

		defaultDifficultyInputText.text = '';

		if (weekFile.defaultDifficulty != null && weekFile.defaultDifficulty.length > 0) {
			defaultDifficultyInputText.text = weekFile.defaultDifficulty;
		}

		difficultiesIDsInputText.text = '';
		difficultiesNamesInputText.text = '';
		difficultiesSuffixesInputText.text = '';

		if (weekFile.difficulties != null && weekFile.difficulties.length > 0)
		{
			var diffsIDs:Array<String> = [];
			var diffsNames:Array<String> = [];
			var diffsSuffixes:Array<String> = [];

			for (i in 0...weekFile.difficulties.length)
			{
				var diff:Array<String> = weekFile.difficulties[i];

				diffsIDs.push(diff[0]);
				diffsNames.push(diff[1]);
				diffsSuffixes.push(diff[2]);
			}

			difficultiesIDsInputText.text = diffsIDs.join(', ');
			difficultiesNamesInputText.text = diffsNames.join(', ');
			difficultiesSuffixesInputText.text = diffsSuffixes.join(', ');
		}

		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;
		
		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText():Void
	{
		var leName:String = weekFile.storyName;

		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var weekArray:Array<String> = weekFile.weekCharacters;

		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);
		}

		txtTracklist.text = [for (i in weekFile.songs) i.songName].join('\n').toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
	}

	function reloadBG():Void
	{
		bgSprite.visible = true;

		var assetName:String = weekFile.weekBackground;
		var isMissing:Bool = true;

		if (assetName != null && assetName.trim().length > 0)
		{
			if (Paths.fileExists('images/menubackgrounds/menu_' + assetName + '.png', IMAGE))
			{
				bgSprite.loadGraphic(Paths.getImage('menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
			else if (Paths.fileExists('images/storymenu/menubackgrounds/menu_' + assetName + '.png', IMAGE))
			{
				bgSprite.loadGraphic(Paths.getImage('storymenu/menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if (isMissing) {
			bgSprite.visible = false;
		}
	}

	var lastItemPath:String = null;

	function reloadWeekThing():Void
	{
		weekThing.visible = true;
		missingFileText.visible = false;

		var assetName:String = itemFileInputText.text.trim();
		var isMissing:Bool = true;

		if (lastItemPath != assetName)
		{
			if (assetName != null && assetName.length > 0)
			{
				if (Paths.fileExists('images/storymenu/' + assetName + '.png', IMAGE))
				{
					weekThing.loadGraphic(Paths.getImage('storymenu/' + assetName));
					isMissing = false;
				}
				else if (Paths.fileExists('images/menuitems/' + assetName + '.png', IMAGE))
				{
					weekThing.loadGraphic(Paths.getImage('menuitems/' + assetName));
					isMissing = false;
				}
				else if (Paths.fileExists('images/storymenu/menuitems/' + assetName + '.png', IMAGE))
				{
					weekThing.loadGraphic(Paths.getImage('storymenu/menuitems/' + assetName));
					isMissing = false;
				}
			}

			if (isMissing)
			{
				weekThing.visible = false;

				missingFileText.visible = true;
				missingFileText.text = 'MISSING FILE: images/storymenu/menuitems/' + assetName + '.png';
			}

			weekThing.screenCenter(X);
		}

		weekThing.color = FlxColor.fromRGB(Math.round(itemColorStepperR.value), Math.round(itemColorStepperG.value), Math.round(itemColorStepperB.value));

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Week Editor", "Editting: " + weekFile.weekName); // Updating Discord Rich Presence
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == weekIDInputText)
			{
				weekFile.weekID = weekIDInputText.text.trim();
				weekFileName = weekIDInputText.text.trim();
			}
			else if (sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText)
			{
				weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekFile.weekCharacters[2] = girlfriendInputText.text.trim();

				updateText();
			}
			else if (sender == backgroundInputText)
			{
				weekFile.weekBackground = backgroundInputText.text.trim();
				reloadBG();
			}
			else if (sender == itemFileInputText)
			{
				weekFile.itemFile = itemFileInputText.text.trim();
				reloadWeekThing();
			}
			else if (sender == displayNameInputText)
			{
				weekFile.storyName = displayNameInputText.text.trim();
				updateText();
			}
			else if (sender == weekNameInputText) {
				weekFile.weekName = weekNameInputText.text.trim();
			}
			else if (sender == songIdsInputText)
			{
				var splittedText:Array<String> = [for (i in songIdsInputText.text.trim().split(',')) Paths.formatToSongPath(i.trim())];

				while (splittedText.length < weekFile.songs.length) {
					weekFile.songs.pop();
				}

				for (i in 0...splittedText.length)
				{
					var name:String = CoolUtil.formatToName(splittedText[i]);

					if (i >= weekFile.songs.length)
					{
						weekFile.songs.push({
							songID: splittedText[i],
							songName: name,
							icon: 'dad',
							color: [146, 113, 253]
						});
					}
					else
					{
						weekFile.songs[i].songID = splittedText[i];

						if (weekFile.songs[i].songName == null || weekFile.songs[i].songName.length < 1) {
							weekFile.songs[i].songName = name;
						}

						if (weekFile.songs[i].icon == null || weekFile.songs[i].icon.length < 1) {
							weekFile.songs[i].icon = 'dad';
						}

						if (weekFile.songs[i].color == null || weekFile.songs[i].color.length < 1) {
							weekFile.songs[i].color = [146, 113, 253];
						}
					}
				}

				songIdsInputText.text = splittedText.join(', ');
			}
			else if (sender == songNamesInputText)
			{
				var splittedText:Array<String> = [for (i in songNamesInputText.text.trim().split(',')) i.trim()];

				for (i in 0...splittedText.length)
				{
					if (weekFile.songs[i] != null) {
						weekFile.songs[i].songName = splittedText[i];
					}
				}

				updateText();
			}
			else if (sender == weekBeforeInputText) {
				weekFile.weekBefore = weekBeforeInputText.text.trim();
			}
			else if (sender == defaultDifficultyInputText) {
				weekFile.defaultDifficulty = defaultDifficultyInputText.text.trim();
			}
			else if (sender == difficultiesIDsInputText)
			{
				if (difficultiesIDsInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesIDsInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (weekFile.difficulties[i] == null || weekFile.difficulties[i].length < 1) {
								weekFile.difficulties[i] = [];
							}

							weekFile.difficulties[i][0] = splittedText[i];
						}
					}
				}

				for (i in 0...weekFile.difficulties.length)
				{
					if ((weekFile.difficulties[i][0] == null || weekFile.difficulties[i][0].length < 1) &&
						(weekFile.difficulties[i][1] == null || weekFile.difficulties[i][1].length < 1) &&
						(weekFile.difficulties[i][2] == null || weekFile.difficulties[i][2].length < 1)) {
						weekFile.difficulties.remove(weekFile.difficulties[i]);
					}
				}
			}
			else if (sender == difficultiesNamesInputText)
			{
				if (difficultiesNamesInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesNamesInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (weekFile.difficulties[i] == null || weekFile.difficulties[i].length < 1) {
								weekFile.difficulties[i] = [];
							}

							weekFile.difficulties[i][1] = splittedText[i];
						}
					}
				}

				for (i in 0...weekFile.difficulties.length)
				{
					if ((weekFile.difficulties[i][0] == null || weekFile.difficulties[i][0].length < 1) &&
						(weekFile.difficulties[i][1] == null || weekFile.difficulties[i][1].length < 1) &&
						(weekFile.difficulties[i][2] == null || weekFile.difficulties[i][2].length < 1)) {
						weekFile.difficulties.remove(weekFile.difficulties[i]);
					}
				}
			}
			else if (sender == difficultiesSuffixesInputText)
			{
				if (difficultiesSuffixesInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesSuffixesInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (weekFile.difficulties[i] == null || weekFile.difficulties[i].length < 1) {
								weekFile.difficulties[i] = [];
							}

							weekFile.difficulties[i][2] = splittedText[i];
						}
					}
				}

				for (i in 0...weekFile.difficulties.length)
				{
					if ((weekFile.difficulties[i][0] == null || weekFile.difficulties[i][0].length < 1) &&
						(weekFile.difficulties[i][1] == null || weekFile.difficulties[i][1].length < 1) &&
						(weekFile.difficulties[i][2] == null || weekFile.difficulties[i][2].length < 1)) {
						weekFile.difficulties.remove(weekFile.difficulties[i]);
					}
				}
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == itemColorStepperR || sender == itemColorStepperG || sender == itemColorStepperB)
			{
				weekFile.itemColor[0] = Math.round(itemColorStepperR.value);
				weekFile.itemColor[1] = Math.round(itemColorStepperG.value);
				weekFile.itemColor[2] = Math.round(itemColorStepperB.value);

				reloadWeekThing();
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		if (loadedWeek != null)
		{
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
		}

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER) {
					inputText.hasFocus = false;
				}

				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				var leText:FlxUIInputText = @:privateAccess cast (stepper.text_field, FlxUIInputText);

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
			ClientPrefs.toggleVolumeKeys(true);

			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.music.volume = 0;
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

		missingFileText.y = weekThing.y + 36;
	}

	private static var _file:FileReference;

	public static function loadWeek():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');

		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}
	
	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;

	private static function onLoadComplete(_:Event):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;

		@:privateAccess
		if(_file.__path != null) fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);

			if (rawJson != null)
			{
				var cutName:String = _file.name.substr(0, _file.name.length - 5);
				loadedWeek = WeekData.onLoadJson(Json.parse(rawJson), cutName);

				if (loadedWeek.weekCharacters != null && loadedWeek.weekName != null && loadedWeek.weekID != null) // Make sure it's really a week
				{
					loadError = false;

					weekFileName = cutName;
					_file = null;

					return;
				}
			}
		}

		loadError = true;
		loadedWeek = null;

		_file = null;
		#else
		Debug.logError("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	private static function onLoadCancel(event:Event):Void
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
	private static function onLoadError(event:Event):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logError("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile):Void
	{
		var data:String = Json.stringify(weekFile, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), weekFileName + '.json');
		}
	}
	
	private static function onSaveComplete(event:Event):Void
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
	private static function onSaveCancel(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		Debug.logError("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatState
{
	var weekFile:WeekFile = null;

	private var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	private var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];
	private var blockPressWhileScrolling:Array<FlxUIDropDownMenu> = [];

	public function new(weekFile:WeekFile = null):Void
	{
		super();

		this.weekFile = WeekData.createWeekFile();
		if (weekFile != null) this.weekFile = weekFile;
	}

	var curSong:WeekSong;
	var bg:Sprite;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var curSelected:Int = -1;

	override function create():Void
	{
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
		bg.color = FlxColor.WHITE;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...weekFile.songs.length)
		{
			if (curSelected < 0) curSelected = i;
			var leSong:WeekSong = weekFile.songs[i];

			var songText:Alphabet = new Alphabet(90, 320, leSong.songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.setPosition(0, (70 * i) + 30);

			var icon:HealthIcon = new HealthIcon(leSong.icon);
			icon.sprTracker = songText;
			icon.ID = i;
			grpIcons.add(icon);
		}

		addEditorBox();
		changeSelection();

		super.create();
	}

	var UI_box:FlxUITabMenu;

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Difficulties', label: 'Difficulties'},
			{name: 'Freeplay', label: 'Freeplay'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(265, 270);
		UI_box.x = FlxG.width - UI_box.width - 100;
		UI_box.y = FlxG.height - UI_box.height - 50;
		UI_box.scrollFactor.set();

		addFreeplayUI();
		addDiffsUI();

		UI_box.selected_tab_id = 'Freeplay';
		add(UI_box);

		var blackBlack:Sprite = new Sprite(0, 670);
		blackBlack.makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:FlxButton = new FlxButton(0, 685, "Load Week", WeekEditorState.loadWeek);
		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var storyModeButton:FlxButton = new FlxButton(0, 685, "Story Mode", function():Void {
			FlxG.switchState(new WeekEditorState(weekFile));
		});
		storyModeButton.screenCenter(X);
		add(storyModeButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 685, "Save Week", function():Void {
			WeekEditorState.saveWeek(weekFile);
		});
		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	var bgColorStepperR:FlxUINumericStepper;
	var bgColorStepperG:FlxUINumericStepper;
	var bgColorStepperB:FlxUINumericStepper;

	var iconInputText:FlxUIInputText;

	function addFreeplayUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Freeplay";

		bgColorStepperR = new FlxUINumericStepper(10, 40, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperR);

		bgColorStepperG = new FlxUINumericStepper(80, 40, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperG);

		bgColorStepperB = new FlxUINumericStepper(150, 40, 20, 255, 0, 255, 0);
		blockPressWhileTypingOnStepper.push(bgColorStepperB);

		var copyColor:FlxButton = new FlxButton(10, bgColorStepperR.y + 25, "Copy Color", function():Void {
			Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue;
		});

		var pasteColor:FlxButton = new FlxButton(140, copyColor.y, "Paste Color", function():Void
		{
			if (Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');

				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);

					if (!Math.isNaN(toPush))
					{
						if (toPush > 255) {
							toPush = 255;
						}
						else if (toPush < 0) {
							toPush *= -1;
						}

						leColor.push(toPush);
					}
				}

				if (leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];

					updateBG();
				}
			}
		});

		iconInputText = new FlxUIInputText(10, bgColorStepperR.y + 70, 100, '', 8);
		blockPressWhileTypingOn.push(iconInputText);

		var hideFreeplayCheckbox:FlxUICheckBox = new FlxUICheckBox(10, iconInputText.y + 30, null, null, "Hide Week from Freeplay?", 100);
		hideFreeplayCheckbox.checked = weekFile.hideFreeplay;
		hideFreeplayCheckbox.callback = function():Void {
			weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
		}
		
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));

		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);

		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(iconInputText);
		tab_group.add(hideFreeplayCheckbox);

		UI_box.addGroup(tab_group);
	}

	var defaultDifficultyInputText:FlxUIInputText;
	var difficultiesIDsInputText:FlxUIInputText;
	var difficultiesNamesInputText:FlxUIInputText;
	var difficultiesSuffixesInputText:FlxUIInputText;

	var lastDiffs:Array<Array<String>> = [];

	function addDiffsUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Difficulties";

		defaultDifficultyInputText = new FlxUIInputText(10, 25, 70, '', 8);
		blockPressWhileTypingOn.push(defaultDifficultyInputText);

		difficultiesIDsInputText = new FlxUIInputText(10, defaultDifficultyInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesIDsInputText);

		difficultiesNamesInputText = new FlxUIInputText(10, difficultiesIDsInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesNamesInputText);

		difficultiesSuffixesInputText = new FlxUIInputText(10, difficultiesNamesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesSuffixesInputText);

		var copyDiffs:FlxButton = new FlxButton(30, difficultiesSuffixesInputText.y + 30, "Copy Diffs", function():Void {
			lastDiffs = curSong.difficulties.copy();
		});

		var pasteDiffs:FlxButton = new FlxButton(140, copyDiffs.y, "Paste Diffs", function():Void
		{
			if (lastDiffs != null && lastDiffs.length > 0) {
				curSong.difficulties = lastDiffs.copy();
			}

			loadCurSongShit();
		});

		tab_group.add(defaultDifficultyInputText);
		tab_group.add(difficultiesIDsInputText);
		tab_group.add(difficultiesNamesInputText);
		tab_group.add(difficultiesSuffixesInputText);
		tab_group.add(copyDiffs);
		tab_group.add(pasteDiffs);
		tab_group.add(new FlxText(defaultDifficultyInputText.x, defaultDifficultyInputText.y - 20, 0, 'Default Difficulty ID:'));
		tab_group.add(new FlxText(difficultiesIDsInputText.x, difficultiesIDsInputText.y - 20, 0, 'Difficulties IDs:'));
		tab_group.add(new FlxText(difficultiesNamesInputText.x, difficultiesNamesInputText.y - 20, 0, 'Difficulties Names:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y - 20, 0, 'Difficulties Suffixes:'));
		tab_group.add(new FlxText(difficultiesIDsInputText.x, pasteDiffs.y + 30, 0, 'Default difficulties without quotes are Week\'s\nDifficulties. If the week\'s difficulty is specified\nwithout quotes, "Easy, Normal, Hard" will be used.'));

		UI_box.addGroup(tab_group);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == defaultDifficultyInputText) {
				curSong.defaultDifficulty = defaultDifficultyInputText.text.trim();
			}
			else if (sender == difficultiesIDsInputText)
			{
				if (difficultiesIDsInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesIDsInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (curSong.difficulties[i] == null || curSong.difficulties[i].length < 1) {
								curSong.difficulties[i] = [];
							}

							curSong.difficulties[i][0] = splittedText[i];
						}
					}
				}

				for (i in 0...curSong.difficulties.length)
				{
					if ((curSong.difficulties[i][0] == null || curSong.difficulties[i][0].length < 1) &&
						(curSong.difficulties[i][1] == null || curSong.difficulties[i][1].length < 1) &&
						(curSong.difficulties[i][2] == null || curSong.difficulties[i][2].length < 1)) {
						curSong.difficulties.remove(curSong.difficulties[i]);
					}
				}
			}
			else if (sender == difficultiesNamesInputText)
			{
				if (difficultiesNamesInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesNamesInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (curSong.difficulties[i] == null || curSong.difficulties[i].length < 1) {
								curSong.difficulties[i] = [];
							}

							curSong.difficulties[i][1] = splittedText[i];
						}
					}
				}
	
				for (i in 0...curSong.difficulties.length)
				{
					if ((curSong.difficulties[i][0] == null || curSong.difficulties[i][0].length < 1) &&
						(curSong.difficulties[i][1] == null || curSong.difficulties[i][1].length < 1) &&
						(curSong.difficulties[i][2] == null || curSong.difficulties[i][2].length < 1)) {
						curSong.difficulties.remove(curSong.difficulties[i]);
					}
				}
			}
			else if (sender == difficultiesSuffixesInputText)
			{
				if (difficultiesSuffixesInputText.text.length > 0)
				{
					var splittedText:Array<String> = [for (i in difficultiesSuffixesInputText.text.trim().split(',')) i.trim()];

					if (splittedText.length > 0)
					{
						for (i in 0...splittedText.length)
						{
							if (curSong.difficulties[i] == null || curSong.difficulties[i].length < 1) {
								curSong.difficulties[i] = [];
							}

							curSong.difficulties[i][2] = splittedText[i];
						}
					}
				}

				for (i in 0...curSong.difficulties.length)
				{
					if ((curSong.difficulties[i][0] == null || curSong.difficulties[i][0].length < 1) &&
						(curSong.difficulties[i][1] == null || curSong.difficulties[i][1].length < 1) &&
						(curSong.difficulties[i][2] == null || curSong.difficulties[i][2].length < 1)) {
						curSong.difficulties.remove(curSong.difficulties[i]);
					}
				}
			}
			else if (sender == iconInputText)
			{
				curSong.icon = iconInputText.text;
				grpIcons.members[curSelected].changeIcon(iconInputText.text);
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB) {
				updateBG();
			}
		}
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		if (WeekEditorState.loadedWeek != null)
		{
			super.update(elapsed);

			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));

			WeekEditorState.loadedWeek = null;
			return;
		}

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				ClientPrefs.toggleVolumeKeys(false);
				blockInput = true;

				if (FlxG.keys.justPressed.ENTER) {
					inputText.hasFocus = false;
				}

				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				var leText:FlxUIInputText = @:privateAccess cast (stepper.text_field, FlxUIInputText);

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
			ClientPrefs.toggleVolumeKeys(true);

			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.sound.music.volume = 0;
				FlxG.switchState(new MasterEditorMenu());
			}

			if (weekFile.songs.length > 1)
			{
				var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;
	
				if (controls.UI_DOWN_P)
				{
					changeSelection(shiftMult);
					holdTime = 0;
				}
	
				if (controls.UI_UP_P)
				{
					changeSelection(-shiftMult);
					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					}
				}
	
				if (FlxG.mouse.wheel != 0) {
					changeSelection(-1 * FlxG.mouse.wheel);
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

		super.update(elapsed);
	}

	function updateBG():Void
	{
		curSong.color[0] = Math.round(bgColorStepperR.value);
		curSong.color[1] = Math.round(bgColorStepperG.value);
		curSong.color[2] = Math.round(bgColorStepperB.value);

		bg.color = FlxColor.fromRGB(curSong.color[0], curSong.color[1], curSong.color[2]);
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, weekFile.songs.length - 1);
		curSong = weekFile.songs[curSelected];

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		for (icon in grpIcons)
		{
			icon.alpha = 0.6;

			if (icon.ID == curSelected) {
				icon.alpha = 1;
			}
		}

		loadCurSongShit();
		updateBG();

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}

	function loadCurSongShit():Void
	{
		iconInputText.text = curSong.icon;

		bgColorStepperR.value = Math.round(curSong.color[0]);
		bgColorStepperG.value = Math.round(curSong.color[1]);
		bgColorStepperB.value = Math.round(curSong.color[2]);

		defaultDifficultyInputText.text = '';

		if (curSong.defaultDifficulty != null && curSong.defaultDifficulty.length > 0) {
			defaultDifficultyInputText.text = curSong.defaultDifficulty;
		}

		difficultiesIDsInputText.text = '';
		difficultiesNamesInputText.text = '';
		difficultiesSuffixesInputText.text = '';

		if (curSong.difficulties != null && curSong.difficulties.length > 0)
		{
			var diffsIDs:Array<String> = [];
			var diffsNames:Array<String> = [];
			var diffsSuffixes:Array<String> = [];

			for (i in 0...curSong.difficulties.length)
			{
				var diff:Array<String> = curSong.difficulties[i];

				diffsIDs.push(diff[0]);
				diffsNames.push(diff[1]);
				diffsSuffixes.push(diff[2]);
			}

			difficultiesIDsInputText.text = diffsIDs.join(', ');
			difficultiesNamesInputText.text = diffsNames.join(', ');
			difficultiesSuffixesInputText.text = diffsSuffixes.join(', ');
		}
	}
}