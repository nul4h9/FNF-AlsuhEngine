package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;

using StringTools;

class MasterEditorMenu extends MusicBeatState
{
	private var curSelected:Int = 0;
	private var curDirectory:Int = 0;

	private var editorsArray:Array<String> =
	[
		'Chart Editor',
		'Character Editor',
		'Week Editor',
		'Menu Character Editor',
		#if ACHIEVEMENTS_ALLOWED
		'Achievement Editor',
		#end
		'Dialogue Editor',
		'Dialogue Portrait Editor',
		'Note Splash Debug'
	];
	private var directories:Array<String> = [null];

	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var directoryTxt:FlxText;

	override function create():Void
	{
		FlxG.mouse.visible = !controls.controllerMode;
		FlxG.camera.bgColor = FlxColor.BLACK;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0) {
				FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
			}
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Editors Main Menu", null); // Updating Discord Rich Presence
		#end

		var bg:Sprite = new Sprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.scrollFactor.set();
		bg.color = 0xFF353535;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...editorsArray.length)
		{
			var text:Alphabet = new Alphabet(90, 320, editorsArray[i], true);
			text.isMenuItem = true;
			text.targetY = i - curSelected;
			text.setPosition(0, (70 * i) + 30);
			grpTexts.add(text);
		}

		#if MODS_ALLOWED
		var textBG:Sprite = new Sprite(0, FlxG.height - 42);
		textBG.makeGraphic(FlxG.width, 42, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		directoryTxt = new FlxText(textBG.x, textBG.y + 4, FlxG.width, '', 32);
		directoryTxt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		directoryTxt.scrollFactor.set();
		add(directoryTxt);
		
		for (folder in Paths.getModDirectories()) {
			directories.push(folder);
		}

		var found:Int = directories.indexOf(Paths.currentModDirectory);
		if (found > -1) curDirectory = found;

		changeDirectory();
		#end

		changeSelection();

		super.create();
	}

	var holdTime:Float = 0;
	var holdTimeMod:Float = 0;

	override function update(elapsed:Float):Void
	{
		if (controls.BACK_P || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		#if MODS_ALLOWED
		if (directories.length > 1)
		{
			if (controls.UI_LEFT_P)
			{
				changeDirectory(-1);
				holdTimeMod = 0;
			}

			if (controls.UI_RIGHT_P)
			{
				changeDirectory(1);
				holdTimeMod = 0;
			}

			if (controls.UI_LEFT || controls.UI_RIGHT)
			{
				var checkLastHold:Int = Math.floor((holdTimeMod - 0.5) * 10);
				holdTimeMod += elapsed;
				var checkNewHold:Int = Math.floor((holdTimeMod - 0.5) * 10);

				if (holdTimeMod > 0.5 && checkNewHold - checkLastHold > 0) {
					changeDirectory((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0 && FlxG.mouse.pressedMiddle) {
				changeDirectory(-1 * FlxG.mouse.wheel);
			}
		}
		#end

		if (editorsArray.length > 1)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-1);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(1);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0 && !FlxG.mouse.pressedMiddle) {
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpTexts.members[curSelected]))) {
			goToState(editorsArray[curSelected]);
		}

		super.update(elapsed);
	}

	function goToState(label:String):Void
	{
		switch (label)
		{
			case 'Week Editor': FlxG.switchState(new WeekEditorState());
			case 'Character Editor': LoadingState.loadAndSwitchState(new CharacterEditorState(Character.DEFAULT_CHARACTER, false));
			case 'Menu Character Editor': FlxG.switchState(new MenuCharacterEditorState());
			#if ACHIEVEMENTS_ALLOWED
			case 'Achievement Editor': FlxG.switchState(new AchievementEditorState());
			#end
			case 'Dialogue Editor': return LoadingState.loadAndSwitchState(new DialogueEditorState(), true);
			case 'Dialogue Portrait Editor': return LoadingState.loadAndSwitchState(new DialogueCharacterEditorState(), true);
			case 'Chart Editor':
			{
				if (PlayState.SONG == null)
				{
					PlayState.gameMode = 'default';
					PlayState.storyWeek = 1;
					PlayState.storyDifficulty = 1;
					PlayState.lastDifficulty = 1;
					PlayState.isStoryMode = false;
				}

				return LoadingState.loadAndSwitchState(new ChartingState(), true);
			}
			case 'Note Splash Debug': LoadingState.loadAndSwitchState(new NoteSplashDebugState());
		}

		FlxG.sound.music.volume = 0;
		FreeplayMenuState.destroyFreeplayVocals();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, editorsArray.length - 1);

		var bullShit:Int = 0;

		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}

	#if MODS_ALLOWED
	function changeDirectory(change:Int = 0):Void
	{
		curDirectory = FlxMath.wrap(curDirectory + change, 0, directories.length - 1);
	
		WeekData.setDirectoryFromWeek();

		if (directories[curDirectory] == null || directories[curDirectory].length < 1) {
			directoryTxt.text = '< No Mod Directory Loaded >';
		}
		else
		{
			Paths.currentModDirectory = directories[curDirectory];
			directoryTxt.text = '< Loaded Mod Directory: ' + Paths.currentModDirectory + ' >';
		}

		directoryTxt.text = directoryTxt.text.toUpperCase();
		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}
	#end
}