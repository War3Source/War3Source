# Contributing to War3Source #
When you're contributing to War3Source, there are a few rules you should follow. War3Source should be able to compile on both Windows and Linux and you need to make sure that any changes you make don't break compatibility with existing games that War3Source supports.

## How To Contribute ##
(Borrowed from [Jessecar96/SteamBot](https://github.com/Jessecar96/SteamBot/blob/master/CONTRIBUTING.md)

1. Fork The Repository ([War3Source/War3Source](https://github.com/War3Source/War3Source))
2. Branch It
    - this is because when you do the pull request for it, it includes commits you make after you make the pull request and before the pull request is accepted
3. Make Your Changes
4. Commit Your Changes
5. Do 3 and 4 as Needed
6. Push Your Changes Back to GitHub
7. Start a Pull Request on the Repository
    - make sure you explain what the pull request does

## Styleguide ##

### Indentation ###
Four (4) spaces as indent, no tabs.

### Brackets ###
* Brackets should be on the next line of a function definition or an if directive. 
* Brackets should always be on their own line.
 * Addendum: Else statements may follow after a closing bracket.

    if (Condition)
    {
        foobar();
    } else {
        barfoo();
    }
    
* No braceless if directives.

### Spaces ###
* No space after a opening bracket or before a closing bracket.
* Put a space after the comma when seperating parameters.
* Use spaces when assigning values to variables (a = 5)

### Naming conventions ###
* Enumeration should be prefixed by a descriptive common type name(like COLOR_RED, COLOR_GREEN)
* War3Source specific methods should have the prefix War3_<name>
* Give a descriptive name for callback handlers, for example:
 * Event_EventnameWithoutUnderscores
 * SQLCallback_DescriptiveName
 * MenuHandler_MenuName

### Comments ###
Comments should be relative to their position in the code.

Good:

    public void someFunc()
    {
        // good comment
        PrintToServer("Useless function");
    }
    
Bad:

    public void someFunc()
    {
        PrintToServer("Useless function");        //bad comment
    }
