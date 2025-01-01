package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.group.FlxGroup;
import flixel.effects.FlxFlicker;

using StringTools;

class OptionsMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	private var options:Array<String> = ['Preferences', 'Controls', 'Note Colors', 'Adjust Delay and Combo', 'Exit'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	public static var onPlayState:Bool = false;

	function openSelectedSubstate(label:String):Void
	{
		switch (label)
		{
			case 'Preferences': openSubState(new PreferencesSubState());
			case 'Note Colors': openSubState(new NotesSubState());
			case 'Controls': openSubState(new ControlsSubState());
			case 'Adjust Delay and Combo':
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;

				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new NoteOffsetState());

				return;
			}
			case 'Exit':
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new MainMenuState());

				return;
			}
			default:
			{
				flickering = false;
				return;
			}
		}

		grpOptions.visible = false;
		selectorLeft.visible = false;
		selectorRight.visible = false;
	}

	override function create():Void
	{
		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)
			{
				if (!onPlayState) {
					FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
				}
				else if (ClientPrefs.pauseMusic != 'None') {
					FlxG.sound.playMusic(Paths.getMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic)));
				}
			}
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu");
		#end

		var bg:Sprite = new Sprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

		super.create();
	}

	override function closeSubState():Void
	{
		super.closeSubState();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu");
		#end

		flickering = false;

		grpOptions.visible = true;
		selectorLeft.visible = true;
		selectorRight.visible = true;
	}

	var flickering:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK_P)
		{
			ClientPrefs.savePrefs();
			FlxG.sound.play(Paths.getSound('cancelMenu'));

			if (onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState(), true);

				FlxG.sound.music.volume = 0;
			}
			else FlxG.switchState(new MainMenuState());
		}

		if (!flickering)
		{
			if (options.length > 1)
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

				if (FlxG.mouse.wheel != 0) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(grpOptions.members[curSelected])))
			{
				if (ClientPrefs.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(selectorLeft, 1, 0.06, true);
					FlxFlicker.flicker(selectorRight, 1, 0.06, true);
	
					FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
						openSelectedSubstate(options[curSelected]);
					});
	
					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else {
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
	}

	override function destroy():Void
	{
		ClientPrefs.loadPrefs();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);

		for (item in grpOptions.members)
		{
			item.alpha = 0.6;

			if (item.ID == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}
}