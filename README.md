# Friday Night Funkin' - Alsuh Engine

Alsuh Engine based on Psych Engine versions 0.6.3 and 0.7.3. Engine and his code and content is available under the [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0).

## Installation:
1. You must have [Haxe version 4.3.4 or greater](https://haxe.org/download/).
2. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
3. Install [Visual Studio Community 2022](https://visualstudio.microsoft.com/vs/community/).
4. While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
- MSVC v143 - VS 2022 C++ ARM Build Tools
- MSVC v143 - VS 2022 C++ x64/x86 Build Tools
- Windows SDK 10.0.20348.0
- Windows SDK 10.0.22621.0
5. Open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`
after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for this engine.

### Supported platforms:
- Windows (windows)
- Linux (linux)
- MacOS (macos, mac)
- HTML5 (html5)

To build the game, run `haxelib run openfl test <target>`.

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Alsuh Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Credits:
### Alsuh Engine By
* Null the Great - Programmer

### Psych Engine Team
* Shadow Mario - Programmer
* RiverOaken - Artist

### Psych Engine Contributors
* bbpanzu - Ex-Programmer
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - LUA JIT Fork and some Lua reworks