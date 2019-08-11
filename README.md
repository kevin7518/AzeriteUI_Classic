[ ![Become a Patreon](http://azeriteui.com/img/social-media-buttons-patreon-small.jpg) ](https://www.patreon.com/AzeriteUI) 

This is a Classic port of our custom user interface originally made for World of Warcraft: Battle For Azeroth! Designed by Daniel "Blakmane" Troko & coded by Lars "Goldpaw" Norberg. 

It's a work in progress as we never was in the Classic beta. I'll update it as much as I can during the pre-launch, and continue work the instant Classic goes live. And I've opened up for [issue reports](https://github.com/AzeriteTeam/AzeriteUI_Classic/issues) now! 

## **Classic Progress Report:**  

### **Stuff that works:**  
* Player-, pet-, target- and tot unit frames
* Minimap, clock, latency, XP
* The main actionbar should work. Stances and forms need testing.
* AzeriteUI `/bind` hover keybinding system
* Game menu (Esc) is styled and awesome!
* Blizzard micro menu 
* AzeriteUI options menu 

### **Stuff not there yet:**  
* **Group frames**  
  * They're there, but had bugs I haven't had time to sort out, so I disabled them for the time being. I'll get them sorted with the help of my guild in and friends I'm joining Classic with. Have no fear! Before Classic launches I will make sure the Blizzard compact frames are available, though. We need group frames of _some_ sort, if nothing else! 
* **Reputation tracking bar**  
  * Not an actual API in classic to track this, so I have to rewrite this the "old" way. I'm sure I can dig through some of my old UIs to simplify this part, so it's coming! Not giving this a high priority, though, since Reputation grinds in Classic won't really be that big of a thing before endgame. So I got a little time.  
* **Nameplate castbars**  
  * Same as above. There simply isn't any cast related events firing for nameplate units, nor can we query nameplate casts with the standard API calls. So I'll have to do this the "old" way too, but writing a combat log event listener that will attempt to figure out what is being cast, and faking the castbars that way. It'll be about as accurate as the addons giving nameplate castbars in vanilla was. Meaning we can probably figure out the casts, but we can't figure out the spell rank, so we'll just have to assume highest rank and longest cast time, which might mean the tmers sometimes will go on for too long. So this feature _will be optional!_

## **Pledge to our work:**  
* Patreon: [www.patreon.com/AzeriteUI](https://www.patreon.com/azeriteui)  
* PayPal: [www.paypal.me/AzeriteUI](https://www.paypal.me/azeriteui)  
* Liberapay: [liberapay.com/AzeriteTeam/donate](https://liberapay.com/AzeriteTeam/donate)

## **Follow Azerite Team:**  
* Discord: [discord.gg/MUSfWXd](https://discord.gg/MUSfWXd)  
* Twitter: [@AzeriteUI](https://twitter.com/azeriteui)  
* Instagram: [@AzeriteUI](https://instagram.com/azeriteui/)  
* Facebook: [@AzeriteUI](https://www.facebook.com/azeriteui/)  
* YouTube: [@AzeriteUI](https://www.youtube.com/azeriteui)  
* Reddit: [@AzeriteUI](https://www.reddit.com/r/azeriteui/)  
