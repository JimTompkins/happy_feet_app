# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added
- Added blues play mode with equalizer.  In blues mode, you choose a pattern,
like 12 bar blues and a key and then then it works like 1-tap mode.  It will play
a percussion groove with a walking bass line.
- Added an equalizer to the Groove screen.  It lets you adjust the voume level
for all 14 percussion sounds
- Added settings icon to app bar on 1-tap and Practice screens
- Added “Accelerometer status” to the Info screen

## [0.33.0] - 2023-02-26

- Changed audio engine to BASS library from un4seen Developments
- Stopped playing last bass note before starting the next one
- Made UI changes as per the review by Avocademy’s UI/UX Design course
- Added an option to play the individual sounds when selecting them, and made this the default behaviour
- Changed bass mode from specifying the key and then the 12 notes above that key, to allowing the choice of any bass note from E1 to D#3.
- Moved last hi-hat a half beat earlier in merengue in 1-tap mode
- Changed heel tapping mode to be the default
- Added introductory walk-through when the app is first opened
- Changed practice mode to use +/-10BPM as the criteria for a streak, up from +/-5BPM
- Greyed out the count-in counter when the count-in is done in 1-tap mode

## Types of changes
Document each revision with these categories of changes, shown by subheadings:
- Added for new features.
- Changed for changes in existing functionality.
- Deprecated for soon-to-be removed features.
- Removed for now removed features.
- Fixed for any bug fixes.
- Security in case of vulnerabilities.
