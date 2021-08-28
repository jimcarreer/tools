# Discord Channel Message Dumper

Can dump channel history including direct message channels.  Uses the
[docker.py][1] package for interactions with discord APIs.  This tool is geared
towards unix like environments, but should work on Windows if you have python
installed.

## Usage

You must have python 3.8+ installed, it is recommended that you use a [python
virtual environment][2].  The script

1. Install script requirements:


    $ pip install -r requirements.txt

2. Create a root directory for the archiver to do its work, put your
   `setings.json` in this directory.

    
    $ mkdir discord_archives
    $ cp settings.json ./discord_archives/

3. Run the script:
    

    $ python3 archive.py ./discord_archives/

## Settings

You will need your discord user token. For more information on how to obtain
one follow [these instructions][3].

To find the unique channel IDs for direct messages or regular channels follow
[these instructions][4].

The settings file has the following format:

    {
        "token": "<your discord user token>",
        "dms": {
            "<channel archive name>": <channel unique id>,
            ...
        }
    }

An example:

    {
        "token": "mfa.AAAAAAAAAAABBBBBBBBBBBBCCCCCCCCCCCCDDDDDDDDDDDDDEEEEEEEEEEEEFFFFFFFFFFFGGGGGGGGGGGGG"
        "dms": {
            "john_smith": 799999999999999991,
            "jessica_lee": 799999999999999992
        }
    }

**Important**: Never share or otherwise expose your token to anyone, it
basically allows full access to all of Discord as your user to anyone who has
it.

[1]: https://github.com/Rapptz/discord.py
[2]: https://docs.python.org/3/tutorial/venv.html
[3]: https://github.com/Tyrrrz/DiscordChatExporter/wiki/Obtaining-Token-and-Channel-IDs#how-to-get-a-user-token
