#!/bin/python3

import json

# pip3 install gmusicapi
from gmusicapi import Mobileclient
from gmusicapi import Musicmanager

DEF_DEV_ID = '87a51970a028da288f1c4138b9b0f55ae8466de0bb3b6e30045b0bde57f5eb35'
DEF_MAC_AD = '4C:CC:6A:0C:BC:09'
DEF_OUT_DR = '/home/jim/Music'


def  download_all(outdir: str = DEF_OUT_DR, device_id: str = DEF_DEV_ID, mac_addr: str = DEF_MAC_AD):
    
    mc = Mobileclient()
    mm = Musicmanager()
    
    mc.oauth_login(DEF_DEV_ID)
    mm.login(uploader_id=DEF_MAC_AD)

    songs = mc.get_all_songs()
    print(f'Downloading {len(songs)}')
    for song in songs:
        filename, audio = mm.download_song(song['id'])
        print(f'Downloading {song["id"]} : {filename}', flush=True)
        with open(f'{outdir}/{filename}', 'wb') as fh:
            fh.write(audio)
        with open(f'{outdir}/{filename}.meta', 'w') as fh:
            json.dump(song, fh, indent=2, sort_keys=True)

def do_login():

    mc = Mobileclient()
    mc.perform_oauth()


if __name__ == '__main__':
    download_all()
