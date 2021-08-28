import json
import logging
import os
import sys
from datetime import datetime
from os import PathLike
from pathlib import Path
from typing import Union, AsyncGenerator, Optional

from discord import Client, TextChannel, Message


class ArchiveException(Exception):
    pass


class DiscordDMArchiver(Client):

    LAST_TS_FILE = '.last_msg_ts'
    ARCHIVE_FILE_NAME_FORMAT = '%Y-%m-%d.json'

    def __init__(self, *, archive_root: Union[str, PathLike], **options):
        super().__init__(**options)
        self._log = logging.getLogger('archiver')
        root = Path(archive_root).expanduser().absolute()
        if not os.path.exists(root.joinpath('settings.json')):
            raise ArchiveException(f'Missing settings.json in {root}')
        with open(root.joinpath('settings.json'), 'r') as fh:
            settings = json.load(fh)
        if 'token' not in settings:
            raise ArchiveException('No token property defined in settings')
        self._token = settings['token']
        self._to_archive = settings.get('dms', {})
        self._dm_root = root.joinpath('dms')
        os.makedirs(self._dm_root, mode=0o700, exist_ok=True)
        self._limit = settings.get('page_limit', 1000)
        self._empty_page_limit = settings.get('empty_page_limit', 3)
        self._file_handles = {}

    def _get_dm_path(self, alias: str, sub_dir: Optional[str] = None, file: Optional[str] = None) -> PathLike:
        path = self._dm_root.joinpath(alias)
        path = path.joinpath(sub_dir) if sub_dir else path
        path = path.joinpath(file) if file else path
        return path

    def _get_file_handle_for(self, alias: str, msg: Message):
        name = msg.created_at.strftime(self.ARCHIVE_FILE_NAME_FORMAT)
        cache_key = f'{alias}-{name}'
        if opened := self._file_handles.get(cache_key, False):
            self._log.debug(f'Returning open file handle for {cache_key}')
            return opened
        self._log.debug(f'Initializing new handle for {cache_key}')
        self._file_handles[cache_key] = open(self._get_dm_path(alias, name), 'ab+')
        return self._file_handles[cache_key]

    def _close_all_file_handles(self):
        self._log.info(f'Closing all open file handles ({len(self._file_handles)} to close)')
        for name, handle in self._file_handles.items():
            self._log.debug(f'Closing {name}')
            handle.close()
        self._log.info('Closed all open handles')

    async def _handle_message(self, alias: str, msg: Message):
        self._log.debug(
            f'For channel alias {alias}: '
            f'  handling message {msg.id} ({msg.author} {msg.created_at.isoformat()})'
        )
        fh = self._get_file_handle_for(alias, msg)
        data = {
            'id': msg.id,
            'user': {'name': msg.author.name, 'id': msg.author.id},
            'content': msg.clean_content,
            'created_at': msg.created_at.isoformat(),
            'edit_at': msg.edited_at.isoformat() if msg.edited_at else None,
            'attachments': [
                {'id': a.id, 'filename': a.filename}
                for a in msg.attachments
            ]
        }
        for a in msg.attachments:
            self._log.debug(f'Handling {a.filename} ({a.id})')
            ext = os.path.splitext(a.filename)[1]
            path = self._get_dm_path(alias, 'attachments', f'{a.id}{ext}')
            with open(path, 'wb') as afh:
                await a.save(afh)
        fh.write(json.dumps(data).encode() + b'\n')

    def _get_last_message_ts(self, alias: str) -> Optional[datetime]:
        self._log.debug(f'Looking for last message archived for {alias}')
        last = self._get_dm_path(alias, self.LAST_TS_FILE)
        if not os.path.exists(last):
            self._log.debug(f'Did not find {self.LAST_TS_FILE} in directory for {alias}')
            return None
        with open(last, 'r') as fh:
            last = datetime.fromisoformat(fh.readline().strip())
        self._log.debug(f'Found last timestamp for message archive {alias}: {last.isoformat()}')
        return last

    async def _archive_channel(self, cid: int, alias: str):
        self._log.info(f'Starting channel archive for {alias} ({cid})')
        os.makedirs(self._get_dm_path(alias), mode=0o700, exist_ok=True)
        os.makedirs(self._get_dm_path(alias, sub_dir='attachments'), mode=0o700, exist_ok=True)
        handled, msg, after = 0, None, self._get_last_message_ts(alias)
        async for msg in self._channel_walk(cid=cid, after=after):
            await self._handle_message(alias, msg)
            handled += 1
        if msg:
            self._log.debug(f'Last message timestamp: {msg.created_at.isoformat()}')
            with open(self._get_dm_path(alias, self.LAST_TS_FILE), 'w') as fh:
                fh.write(msg.created_at.isoformat())
        self._log.info(
            f'Done with archive for {alias} ({cid}), archived {handled} messages '
            f'between {"the beginning of time" if not after else str(after)} and now'
        )

    async def _channel_walk(self, cid: int, after: datetime = None) -> AsyncGenerator[Optional[Message], None]:
        channel: TextChannel = self.get_channel(cid)
        if not channel:
            raise ArchiveException(f'Bad channel id: {cid}, ensure that it is correct')
        self._log.info(
            f'Walking messages for {channel} ({cid}) from '
            f'{str(after) if after else "beginning of time"} onward'
        )
        empty_pages = 0
        while empty_pages < self._empty_page_limit:
            page = channel.history(limit=self._limit, oldest_first=True, after=after)
            yielded = False
            for msg in await page.flatten():
                yield msg
                yielded = True
                after = msg.created_at
            empty_pages += 1 if not yielded else 0
        self._log.info(f'Reached {self._empty_page_limit} empty pages for {channel} ({cid}), stopping iteration')

    async def on_ready(self):
        self._log.info(f'Ready to go as {self.user}')
        for alias, cid in self._to_archive.items():
            await self._archive_channel(cid=cid, alias=alias)
        self._close_all_file_handles()
        self._log.info('Completed all archive tasks')

    def run(self):
        super().run(self._token, bot=False)


def log_setup():
    root = logging.getLogger()
    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.DEBUG)
    handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
    root.addHandler(handler)
    logging.getLogger('discord').setLevel(logging.ERROR)
    logging.getLogger('discord.http').setLevel(logging.WARNING)
    logging.getLogger('archiver').setLevel(logging.INFO)
    # Uncomment this for more verbose output
    # logging.getLogger('archiver').setLevel(logging.DEBUG)


if __name__ == '__main__':
    log_setup()
    if len(sys.argv) != 2:
        print(f'Script takes exactly 1 argument: path to the archive root.', file=sys.stderr)
        exit(1)
    archiver = DiscordDMArchiver(archive_root=sys.argv[1])
    archiver.run()
