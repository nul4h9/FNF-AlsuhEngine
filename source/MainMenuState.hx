package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if ACHIEVEMENTS_ALLOWED
import Achievements;
#end

import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;

using StringTools;

class MainMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var menuItems:FlxTypedGroup<Sprite>;

	var magenta:Sprite;
	var camFollow:FlxObject;

	public static var alsuhEngineVersion:String = '0.1.2h';

	override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Menus"); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music != null && (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0)) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		initSwagCamera();

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		var bg:Sprite = new Sprite(-80);

		var path:String = 'bg/menuBG';
		if (Paths.fileExists('images/menuBG.png', IMAGE)) path = 'menuBG';

		bg.loadGraphic(Paths.getImage(path));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new Sprite(-80);

		var path:String = 'bg/menuDesat';
		if (Paths.fileExists('images/menuDesat.png', IMAGE)) path = 'menuDesat';

		magenta.loadGraphic(Paths.getImage(path));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<Sprite>();
		add(menuItems);

		final offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
		final scroll:Float = (optionShit.length - 4) * 0.135;

		for (i in 0...optionShit.length)
		{
			if (curSelected < 0) curSelected = i;

			var menuItem:Sprite = new Sprite(0, (i * 140) + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.playAnim('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);

			menuItem.scrollFactor.set(0, (optionShit.length < 6 ? 0 : scroll));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, 9);

		#if ALSUH_WATERMARKS
		if (ClientPrefs.watermarks)
		{
			var nullVer:FlxText = new FlxText(12, FlxG.height - 44, 0, "Alsuh Engine v " + alsuhEngineVersion, 12);
			nullVer.scrollFactor.set();
			nullVer.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			add(nullVer);
		}
		#end

		var fnfVer:FlxText = new FlxText(12, FlxG.height - 24, 0, #if ALSUH_WATERMARKS (ClientPrefs.watermarks ? "Friday Night Funkin' " : '') + #end "v " + Application.current.meta.get('version'), 12);
		fnfVer.scrollFactor.set();
		fnfVer.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(fnfVer);

		changeSelection();

		super.create();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.load();

		var leDate:Date = Date.now();

		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			Achievements.unlock('friday_night_play');
		}
		#end

		FlxG.camera.focusOn(FlxPoint.get(camFollow.x, camFollow.y));
	}

	var holdTime:Float = 0;
	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if (FreeplayMenuState.vocals != null) FreeplayMenuState.vocals.volume += 0.5 * elapsed;
		}

		if (!selectedSomethin)
		{ 
			if (optionShit.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(-1);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(1);

					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}
	
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.BACK_P)
			{
				selectedSomethin = true;

				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new TitleState());
			}

			if (controls.ACCEPT_P || (FlxG.mouse.justPressed && FlxG.mouse.overlaps(menuItems.members[curSelected])))
			{
				if (ClientPrefs.flashingLights) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

				selectedSomethin = true;

				if (optionShit[curSelected] == 'donate')
				{
					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
						new FlxTimer().start(0.4, selectDonate);
					});
				}
				else
				{
					FlxFlicker.flicker(menuItems.members[curSelected], 1, 0.06, false, false, function(flk:FlxFlicker):Void
					{
						new FlxTimer().start(0.4, function(tmr:FlxTimer):Void {
							goToState(optionShit[curSelected]);
						});
					});

					for (i in 0...menuItems.members.length)
					{
						if (i == curSelected) continue;

						new FlxTimer().start(1, function(tmr:FlxTimer):Void
						{
							FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4,
							{
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween):Void {
									menuItems.members[i].destroy();
								}
							});
						});
					}
				}

				FlxG.sound.play(Paths.getSound('confirmMenu'));
			}

			#if desktop
			if (controls.DEBUG_1_P)
			{
				selectedSomethin = true;
				FlxG.switchState(new editors.MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function selectDonate(tmr:FlxTimer):Void
	{
		selectedSomethin = false;
		CoolUtil.browserLoad('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/');
	}

	function goToState(daChoice:String):Void
	{
		switch (daChoice)
		{
			case 'story_mode':
				FlxG.switchState(new StoryMenuState());
			case 'freeplay':
				FlxG.switchState(new FreeplayMenuState());
			#if MODS_ALLOWED
			case 'mods':
				FlxG.switchState(new ModsMenuState());
			#end
			#if ACHIEVEMENTS_ALLOWED
			case 'awards':
				FlxG.switchState(new AchievementsMenuState());
			#end
			case 'credits':
				FlxG.switchState(new CreditsMenuState());
			case 'options':
			{
				LoadingState.loadAndSwitchState(new options.OptionsMenuState(), false);
				options.OptionsMenuState.onPlayState = false;

				if (PlayState.SONG != null)
				{
					PlayState.SONG.arrowSkin = null;
					PlayState.SONG.splashSkin = null;
				}
			}
		}
	}

	function changeSelection(huh:Int = 0):Void
	{
		menuItems.members[curSelected].animation.play('idle');
		menuItems.members[curSelected].updateHitbox();
		menuItems.members[curSelected].screenCenter(X);

		curSelected = FlxMath.wrap(curSelected + huh, 0, optionShit.length - 1);

		menuItems.members[curSelected].animation.play('selected');
		menuItems.members[curSelected].centerOffsets();
		menuItems.members[curSelected].screenCenter(X);

		camFollow.setPosition(menuItems.members[curSelected].getGraphicMidpoint().x, menuItems.members[curSelected].getGraphicMidpoint().y - (menuItems.length > 4 ? menuItems.length * 8 : 0));
	}
}