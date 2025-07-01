# cw-script-collection
A small collection of scripts for the Cube World Alpha release. Intended to be used with CheatEngine.
![cw-script-collection-readme](https://github.com/user-attachments/assets/2260851c-8841-432f-b686-66f1d7817c40)
## LUA
### entityCollector
This is the backbone of most LUA scripts in this repository.
Functionality:
  - sets a breakpoint at the stamina instruction to grab the base address of all entities the game has currently loaded
  - offsets are then applied to the base addresses to create headers + addresses inside of the cheat table with information about each entity
  - fully functional for other players, but npc entities aren't being properly formatted yet
How To Use:
  - 

### gearAnimator
Animates your currently worn gear. (Left Weapon, Right Weapon, Chest, and Shoulders)
Functionality:
  - applies offsets to the local player's base address to access currently worn gear
  - the script overwrites worn gear with custom animations at given intervals
How To Use:
  - 

## ASM
