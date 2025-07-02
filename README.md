# cw-script-collection
A small collection of scripts for the Cube World Alpha release. Intended to be used with CheatEngine.
![cw-script-collection-readme](https://github.com/user-attachments/assets/2260851c-8841-432f-b686-66f1d7817c40)
## LUA
### **entityCollector**
This is the backbone of most LUA scripts in this repository.


Functionality:
  - sets a breakpoint at the stamina instruction to grab the base address of all entities the game has currently loaded
  - offsets are then applied to the base addresses to create headers + addresses inside of the cheat table with information about each entity
  - fully functional for player entities, but NPCs aren't being properly formatted yet


How To Use:
  - adding the script to the cheat table should be plug & play
> [!TIP]
> after adding the script right click it inside of your cheat table and assign it a hotkey and check "disable on key release"

### **gearAnimator**
Animates your currently worn gear. (Left Weapon, Right Weapon, Chest, and Shoulders)


Functionality:
  - applies offsets to the local player's base address to access currently worn gear
  - the script overwrites worn gear with custom animations at given intervals


How To Use:
  - you have to make changes to the script and create animations


    - HOW TO EDIT THE SCRIPT
      - there are three blocks at the top of the script that require user input
      - 1. folder path + file names
        - folder path has to end in a backslash
        - file names have to contain a valid animation file and cannot be empty
      - 2. gearAnimator_enabled
        - false = disabled | true = enabled
        - this is where you decide what pieces of equipment will be animated
      - 3. intervals
        - this is the frequency at which animations will play (in milliseconds)


    - HOW TO CREATE ANIMATION FILES
      - animation files have to be .txt files
      - each frame has to be exactly 277 bytes long
      - I recommend using the gearAnimator from this repo to get the correctly formatted 277 long byte arrays
        - alternatively, you can also use CheatEngine to browse your gear's memory region and copy the bytes from there
      - inside the text file, you want to separate each frame by creating a new line (no commas needed)
      - there are examples in the gearFiles folder to learn from
> [!TIP]
> after adding the script right click it inside of your cheat table and assign it a hotkey

> [!CAUTION]
> unequip any gear before animating it in-case your game crashes and do NOT swap gear while the script is active, as that will result in your gear being overwritten and therefore deleted

## ASM
