package;

import flixel.FlxG;
import flixel.FlxObject;

class CustomSubState extends MusicBeatSubState
{
	public static var name:String = 'unnamed';
	public static var instance:CustomSubState;

	#if LUA_ALLOWED
	public static function implementForLua(funk:FunkinLua):Void
	{
		funk.set("openCustomSubstate", openCustomSubstate);
		funk.set("closeCustomSubstate", closeCustomSubstate);
		funk.set("insertToCustomSubstate", insertToCustomSubstate);
	}
	#end

	public static function openCustomSubstate(name:String, ?pauseGame:Bool = false):Void
	{
		if (pauseGame)
		{
			FlxG.camera.followLerp = 0;

			PlayState.instance.persistentUpdate = false;
			PlayState.instance.persistentDraw = true;
			PlayState.instance.paused = true;

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				PlayState.instance.vocals.pause();
			}
		}

		PlayState.instance.openSubState(new CustomSubState(name));

		#if HSCRIPT_ALLOWED
		PlayState.instance.setOnHScript('customSubstate', instance);
		PlayState.instance.setOnHScript('customSubstateName', name);
		#end
	}

	public static function closeCustomSubstate():Bool
	{
		if (instance != null)
		{
			PlayState.instance.closeSubState();
			return true;
		}

		return false;
	}

	public static function insertToCustomSubstate(tag:String, ?pos:Int = -1):Bool
	{
		if (instance != null)
		{
			var tagObject:FlxObject = cast (PlayState.getVar(tag), FlxObject);

			#if LUA_ALLOWED
			if (tagObject == null)
				tagObject = cast (PlayState.getVar(tag), FlxObject);
			#end

			if (tagObject != null)
			{
				if (pos < 0)
					instance.add(tagObject);
				else
					instance.insert(pos, tagObject);

				return true;
			}
		}

		return false;
	}

	override function create():Void
	{
		instance = this;

		PlayState.instance.callOnScripts('onCustomSubstateCreate', [name]);
		super.create();

		PlayState.instance.callOnScripts('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String):Void
	{
		CustomSubState.name = name;

		super();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float):Void
	{
		PlayState.instance.callOnScripts('onCustomSubstateUpdate', [name, elapsed]);
		super.update(elapsed);

		PlayState.instance.callOnScripts('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy()
	{
		PlayState.instance.callOnScripts('onCustomSubstateDestroy', [name]);
		name = 'unnamed';

		#if HSCRIPT_ALLOWED
		PlayState.instance.setOnHScript('customSubstate', null);
		PlayState.instance.setOnHScript('customSubstateName', name);
		#end

		instance = null;

		super.destroy();
	}
}