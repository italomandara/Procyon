<img width="80" height="80" alt="Logo-iOS-Default-1024x1024@1x" src="https://github.com/user-attachments/assets/0efef770-6c63-4f4c-93de-881f6cd68443" />

# Procyon

A Steam game launcher for macOS that can run both Windows and MacOS Games.
It's based on Crossover so you will need to download and install Crossover first

- Replaces CXPatcher, will patch your copy of crossover and add a nice interface to launch steam games
- You can configure the graphics backend and the vulcan backed along with advanced options for every game
- **It can run 32bit games much faster thanks to x87 via rosettaX87**
- You can run doom 2016 using moltenvk - experimental
- You can run UE4 games via dxvk using the ue4 hack (enabled by default)

This is still a work in progress, use at your own risk, I'll provide more instructions later but for starters, all you have to do is select a crossover app and a bottle and the rest will be auto-configured

![Screenshot 2026-03-19 at 22 50 46](https://github.com/user-attachments/assets/6ed53e07-5a66-4ada-90d6-f6134e7a275b)

- The library will list all of your owned games and installed games both on mac and on wine
- There are per-game launch options
-  You can see the options and the detail page by clicking on each thumbnail (see image below)
- The profile page is very rudimentary, I just started working on it

![Screenshot 2026-03-19 at 22 51 13](https://github.com/user-attachments/assets/ec5ef2ad-b15c-4971-8673-68c9eec83beb)

![Screenshot 2026-03-19 at 22 52 03](https://github.com/user-attachments/assets/a545beda-814c-4bb7-a042-4b85c0322f34)

I wrote a to do list here:
https://github.com/italomandara/Procyon/issues/1

Which is pretty much in line with the roadmap

# Instructions
Unfortunately there are still some steps that are needed to be done manually:

## step 1:
Choose  Procyon for crossover 26 (patched) -> Procyon.app.zip

Or Procyon for crossover preview (light patched) -> Procyon.Preview.app.zip

## step 2:
open The options panel,
From the button on top select your unpatched crossover app

## step 3:
after the app is patched you need a bottle with a steam installation so you need to close the option panel open the patched crossover app from procyon using the crossove button and install steam

## step 4:
open The procyonized steam from procyon,
login with your user using the standard steam interface, you'll also need to configure steam folders (you can also locate folders that are in some other bottles or external drives if you don't want to install the games again)

## step 5:
open The options panel again,
unselect and re-select the bottle from the dropdown, and procyoon should find your folders if you have steam for mac, it should be able to detect your mac steam folders too, you should see procyon analyzing your game libraries, wait until complete 


# Contributing:
Everyone is welcome to contribute but please follow some basic rules:
- No AI generated code: it is important that you read the codebase get a rough idea on how things are working (you can contact me on discord for clarifications) you can use AI but please no vibe coding.
- No untested features, if you plan to open a PR please make sure it works before.
- If you don't know how to code in swift and SwiftUI it's ok, you can still test and give some high level debbuging information (errors, and possible solutions)

### Thanks to:
- @Lifeisawful https://github.com/Lifeisawful for rosettax87
- @Gcenx https://github.com/Gcenx for wine patched components and dxvk-macos
- @nastys https://github.com/nastys for the UE4 Moltenvk hack
- https://www.codeweavers.com for Crossover
