# AzeriteUI_Classic Change Log
All notable changes to this project will be documented in this file. Be aware that the [Unreleased] features might not all be part of the next update, nor will all of them even be available in the latest development version. Instead they are provided to give the users somewhat of a preview of what's to come. 

The format is based on [Keep a Changelog](http://keepachangelog.com/) 
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.15-RC] 2019-08-11
### Changed
- The quest watcher is now visible again. We might write a prettier one later, this old one is kind of boring. 
- Improved the size and anchoring of the bag slot buttons beneath the backpack. 

## [1.0.14-RC] 2019-08-11
### Changed
- The durability frame is now placed more wisely. 

## [1.0.13-Alpha] 2019-08-11
### Changed
- Removed the "_Classic" suffix from the UI name in options menu. It doesn't need a different display name, because it's not a different UI, just for a different client. 
- Replaced the blip icon used to indicate what I thought was just resource nodes with a yellow circle with a black dot, as it apparently also is the texture used for identifying questgivers you can turn in finished quests too. Big purple star just didn't seem right there. 

## [1.0.12-Alpha] 2019-08-11
### Added
- Added minimap blip icons for 1.13.2! 
- Added styling to the up, down and to bottom chat window buttons. 

### Changed
- The GameTooltip now follows the same scaling as our own tooltips, regardless of the actual uiScale. 

## [1.0.11-Alpha] 2019-08-10
### Changed
- Disabled the coloring of the orb glass overlay, as this looked strange when dead or empty. None of those things seem to happen in retail. They do here, however. So now I noticed. 
- Disabled castbars on nameplates, as these can't be tracked through regular events in Classic. Any nameplate units would be treated as no unit given at all, which again would default to assuming the player as the unit, resulting in mobs often getting OUR casts on their castbars. We will be adding a combatlog tracking system for this later, which relies on unitGUIDs. 

### Fixed
- Fixed a bug when right-clicking the Minimap.

## [1.0.10-Alpha] 2019-08-10
### Added
- Hunters now get a mana orb too! 

## [1.0.9-Alpha] 2019-08-09
### Changed
- Removed all API calls related to internal minimap quest area rings and blobs.
- Removed a lot of unneeded client checks, as we're not checking for any retail versions anymore. 

## [1.0.8-Alpha] 2019-08-09
### Changed
- Removed more vehicle, override and possess stuff from the unitframe library. 

## [1.0.7-Alpha] 2019-08-09
### Changed
- Removed more petbattle and vehicle stuff from actionbutton library. 

## [1.0.6-Alpha] 2019-08-09
### Changed
- Disabled Raid, Party and Boss frames. Will re-enable Raid and Party when I get it properly tested after the launch. Did Boss frames exist? 

## [1.0.5-Alpha] 2019-08-09
### Fixed
- Fixed Rogue combo points. Cannot test Druids as they get them at level 20, and level cap here in the pre-launch is 15.

## [1.0.5-Alpha] 2019-08-09
### Fixed
- Fixed micro menu.
- Fixed option menu.
- Fixed aura updates on unit changes. 

## [1.0.3-Alpha] 2019-08-09
### Fixed
- Fixed typos in bindings module.
- Fixed API for castbars. 

## [1.0.2-Alpha] 2019-08-09
### Fixed
- Changed `SaveBindings` > `AttemptToAttemptToSaveBindings`, fixing the `/bind` hover keybind mode!

## [1.0.1-Alpha] 2019-08-09
- Public Alpha. 
- Initial commit.
