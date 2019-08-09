# Locale Guidelines

## Text Encoding
Your file must use **UTF-8** encoding. If you use something else like the Windows-1252 or ANSI, non-latin characters won't be recognized properly and your translation will in effect fail. So make sure your file is written and saved as UTF-8. There are options for this in all proper text editors. 


## General
When writing locales, make sure that what you replace is the text AFTER the equal sign, not before. So considering our default locale is the enUS English, the following is the correct way to write a locale in another language: 
```Lua
L["Toggle movable frames"] = "切换框架"
```
While this one here would be WRONG!! 
```Lua
L["切换框架"] = true
```
This is because the entry before the equal sign - known as the *key* - is what WoW recognizes the string value by, while what comes after - known as the *value* - is what it prints to the screen. And this it's the *value* you should edit. 

In our locales, a value of `true` simply means that the text printed to the screen is identical with whatever is in the *key*, which is why the fallback locale of the UI (enUS) uses this. Other locales need to insert the translated strings where the `true` value is. 

Also, if you don't translate all the strings in the locale file, the UI will use the enUS defaults  for the missing entries. 


## Escape Sequences
Make sure not to replace or change any escape sequences. Escape sequences are things things that start with a `|` or a `\` sign, 
usually followed by a letter or number. In WoW, these indicate colors, textures, and other things
that aren't text and not meant to be translated. 

An example of a string with many escape sequences is this:
```Lua
L["Click the button below or type |cff4488ff\"/install\"|r in the chat (without the quotes) followed by the Enter key to run the automatic chat window setup.|n|n"] = true
```
The `|n` means the text will start on a new line. The `|cff488ff` changes the color of the text, while the `|r` return it to normal. The `\"` means just a quote sign, but to be able to put it inside the string which is already enclosed by quotes without breaking the string, we escape by using the backslash. The `\"` in WoW can be compared to the `&quot;` in HTML. It gives us the symbol, without having the code interpreter treat it as a quote.
 

## Formatted Output
One more thing to watch out for is formatted output. Many strings are meant to be used multiple times, and have various other numbers and strings inserted into them at specific places. The places values are inserted starts with a `%` percentage sign, followed by a usually just letter, sometimes a few numbers. It is of importance that you do not change any of this, or the UI will encounter bugs from the malformed strings.

An example of formatted output is this:
```Lua
L["%s requires WoW patch %s(%d) or higher, and you only have %s(%d), bailing out!"] = true
```
In this string, `%s` indicates that another string or word should be inserted here, while `%d` indicates that an integer number value should be inserted. Floating points are indicated with `%f`, and sometimes values like `%.1f` which means *"show 1 digit after the decimal point"*. 

Also be aware that you can't change the order of the input values, or the code using the strings will encounter errors. So even if the order of the input values doesn't sound right in the language you're translating to, you simply have to find a way to change the text to make it work. 

## Further Reading

You can read more about WoW Lua escape sequences here:  
<http://wow.gamepedia.com/UI_escape_sequences>

More about Lua floating point conversions here:  
<http://www.gnu.org/software/libc/manual/html_node/Floating_002dPoint-Conversions.html#Floating_002dPoint-Conversions>

And more about Lua formatted output here:  
<http://www.gnu.org/software/libc/manual/html_node/Table-of-Output-Conversions.html#Table-of-Output-Conversions>
