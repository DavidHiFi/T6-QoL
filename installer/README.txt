QUALITY OF LIFE
Black Ops II Zombies  ·  Plutonium T6


 INSTALL
 ─────────────────────────────────────────────────────────────

   Windows      Double-click   Windows Install.bat

   Linux        No installer script - Wine/Proton/Lutris/Bottles users
                install by hand. See "Install by hand" in the README
                on GitHub, or just: make a folder called "zm_qol" in
                storage\t6\mods\ inside your Plutonium prefix,
                then copy the five mod.* files from "Mod Files"
                into it.

   Then pick what you want from the menu. That is the whole thing.


 BEFORE YOU START
 ─────────────────────────────────────────────────────────────

   ·  Install Plutonium and run it once, so its folders exist.

   ·  Close Plutonium while you install, or files cannot be replaced.

   ·  Windows 10 and 11 are ready as they are. The menu is drawn by
      PowerShell 5.1, which those already include - there is nothing
      for you to download. On older Windows, install Windows
      Management Framework 5.1 first.


 GOOD TO KNOW
 ─────────────────────────────────────────────────────────────

   ·  You never need to open anything in the "Mod Files" folder.
      Windows Install.bat does all of it for you.

   ·  START MENU SHORTCUTS are an option in the menu. Pick it and
      you get two entries you can reach by pressing the Windows
      key and typing:

          Quality Of Life Mod         opens this installer
          Plutonium ReShade Watcher   opens the ReShade helper

      They are yours alone - no administrator rights - and the
      uninstall list takes them off again.

      They point AT THIS FOLDER, so keep the unzipped download
      somewhere you are happy to leave it. If you do move it,
      run that option once more from the new place and the
      shortcuts are rewritten.

   ·  No game file is ever touched. Mod files are written inside
      Plutonium's own folder; optional shortcuts use your Start menu.
      Anything that would overwrite
      files of yours offers to back them up first.

   ·  BACKUPS. The menu has a "Back up / restore my own files"
      screen. Your textures, your sounds, your controller icons,
      your ReShade setup and the mod folder can each be backed up
      and put back on their own, whenever you like. They are
      kept as plain folders in

          storage\t6\backups\

      so you can copy them out by hand too. Nothing in there is
      ever deleted by an install or an update - only by you.

   ·  CONTROLLER ICONS are an option of their own, and you pick
      one of three: PlayStation 5, Nintendo Switch or Xbox One.
      The HD texture pack no longer ships any controller art, so
      the base install leaves the game's own button prompts alone
      and your pick is the only thing that changes them. Picking
      a different pack swaps it over cleanly, extra files and all.

   ·  RESHADE ships version 6.7.3 and the FULL shader collection
      rather than only the shaders one preset happens to use, so
      you can switch effects on in the overlay without hunting
      files down first.

      Five presets are installed. It opens on Cinematic Colour
      Grading, which is the one tuned for Black Ops II.

      Black Ops, MW3 and World at War are DirectX 9 games and
      Black Ops II is DirectX 11, so BO1.ini, MW3.ini and WAW.ini
      are the same look with the one effect DirectX 9 cannot run
      taken out. Every effect left in them is confirmed to work
      there. BO2.ini is an older DirectX 11 preset kept as an
      alternative.

      ON BLACK OPS, MW3 OR WORLD AT WAR, SWITCH PRESET ONCE.
      Plutonium runs all four games through the same program
      folder, so they share one ReShade and one settings file -
      it cannot tell which game you are starting, and it always
      opens on the Black Ops II preset. Press Ctrl+Shift+PgDn
      until you reach your game's preset; ReShade remembers it
      until you switch again. End opens the overlay.

      ReShade is NOT part of "EVERYTHING - the whole package" -
      it is its own row, because it needs one more thing:

   ·  PLAY BO2 WITH RESHADE.BAT, inside the "Mod Files" folder.
      Plutonium deletes any file in its own bin folder it does
      not recognise every time it starts, and that includes
      ReShade. Installing it gets it working right away, but a
      later Plutonium launch will clear it again on its own.

      Double-click this file INSTEAD OF opening Plutonium
      directly, and leave the window it opens running for as
      long as you're playing - it watches for Plutonium and
      puts ReShade straight back the moment it sees Plutonium
      clear it out. Closing that window does not uninstall
      anything; it just stops watching.

      Easier: add the START MENU SHORTCUTS above and open
      "Plutonium ReShade Watcher" from the Start menu instead.
      The installer's own menu can start it too - "Start
      ReShade watchdog only", under PLAY.

   ·  Everything can be removed again from the same menu, one
      piece at a time.


 ─────────────────────────────────────────────────────────────
 github.com/DavidHiFi/T6-QoL
