import csv
import logging
import os.path
import sys
import re
import time
from dataclasses import dataclass
from os import PathLike
from typing import List, Union

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build

SCOPES = [
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/spreadsheets.readonly'
]

log = logging.getLogger()
fmt = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
hnd = logging.StreamHandler(sys.stdout)
hnd.setFormatter(fmt)
log.setLevel(logging.DEBUG)
log.addHandler(hnd)


def cache_creds(token_path: Union[PathLike, str], creds: Credentials):
    token_path = os.path.abspath(token_path)
    with open(token_path, 'w') as fh:
        fh.write(creds.to_json())


def get_creds(scopes: List[str], token_path: Union[PathLike, str]) -> Credentials:
    creds = None
    token_path = os.path.abspath(token_path)
    if os.path.exists(token_path):
        creds = Credentials.from_authorized_user_file(token_path, scopes)
    if creds and creds.valid:
        log.debug('Returning cached credentials')
        return creds
    if creds and creds.expired and creds.refresh_token:
        log.debug('Refreshing cached credentials')
        creds.refresh(Request())
        cache_creds(token_path, creds)
        return creds
    log.debug('Pulling credentials via InstalledAppFlow')
    flow = InstalledAppFlow.from_client_secrets_file('creds.json', scopes)
    creds = flow.run_local_server(port=0)
    cache_creds(token_path, creds)
    return creds


class BudgetPuller:

    SEARCH_Q = (
        "'0BxLkrbZKNONhfnBGZXdqMUZwSjB5WTV5Y1ZNN3JsME8xTVZ5NXBYSzQwbmFJVmVrUVRiYlk' in parents and"
        "mimeType = 'application/vnd.google-apps.spreadsheet' and"
        "name contains 'Budget 20' and"
        "name != 'Budget 2022'"
    )
    TITLE_REX = re.compile(r'^Budget (?P<year>20\d+)$')
    CSV_NAME_LOOKUP = {
        'jan': '01-JAN',
        'feb': '02-FEB',
        'mar': '03-MAR',
        'march': '03-MAR',
        'apr': '04-APR',
        'april': '04-APR',
        'arpil': '04-APR',
        'may': '05-MAY',
        'june': '06-JUN',
        'jun': '06-JUN',
        'july': '07-JUL',
        'jul': '07-JUL',
        'aug': '08-AUG',
        'august': '08-AUG',
        'sep': '09-SEP',
        'sept': '09-SEP',
        'oct': '10-OCT',
        'nov': '11-NOV',
        'dec': '12-DEC'
    }

    @dataclass
    class BudgetFile:
        year: str
        name: str
        id: str

    @dataclass
    class WorkSheet:
        csv_name: str
        gid: int
        fid: str
        name: str
        year: str

    def __init__(self, creds: Credentials, save_dir: Union[PathLike, str]):
        self.log = logging.getLogger('budget-puller')
        self.creds = creds
        self.save_to = os.path.expanduser(save_dir)
        self.save_to = os.path.abspath(self.save_to).rstrip('/')
        self.drive_svc = build('drive', 'v3', credentials=creds)
        self.sheet_svc = build('sheets', 'v4', credentials=creds)

    def _iter_files(self) -> List[BudgetFile]:
        files = self.drive_svc.files().list(pageSize=25, q=self.SEARCH_Q, fields='files(id, name)')
        files = files.execute()
        files = files.get('files', []) if files else []
        for file in files:
            if not (year := self.TITLE_REX.match(file['name'])):
                self.log.warning(f'Skipping {file["name"]} : no year was extracted.')
                continue
            self.log.debug(f'Found {file["name"]}, handling')
            file['year'] = year.group('year')
            yield BudgetPuller.BudgetFile(**file)

    def _csv_name(self, month: str) -> str:
        if month.lower() not in self.CSV_NAME_LOOKUP:
            raise RuntimeError(f'Cannot map sheet month to uniform standard: {month}')
        return self.CSV_NAME_LOOKUP[month.lower()]

    def _iter_sheets(self, file: BudgetFile) -> List[WorkSheet]:
        sp_sheet = self.sheet_svc.spreadsheets().get(spreadsheetId=file.id).execute()
        for sheet in sp_sheet.get('sheets', []):
            props = sheet.get('properties', {})
            month = props.get('title', 'Blank')
            gid = props.get('sheetId')
            if month == 'Blank':
                continue
            # Weird bug, feels like they botched a data migration or something, every
            # sheet after 2017, has an 'April' sheet that doesn't show up in the web
            # app, that is a copy of the work sheet by the same name in that year
            if month == 'April' and file.year != '2017':
                continue
            yield BudgetPuller.WorkSheet(
                csv_name=f'{self._csv_name(month)}.csv',
                gid=gid,
                fid=file.id,
                name=month,
                year=file.year
            )

    def _download(self, sheet: WorkSheet):
        self.log.debug(f'Handling download for {sheet.csv_name}')
        values = self.sheet_svc.spreadsheets().values().get(spreadsheetId=sheet.fid, range=sheet.name)
        values = values.execute().get('values')
        os.makedirs(f'{self.save_to}/{sheet.year}', exist_ok=True)
        with open(f'{self.save_to}/{sheet.year}/{sheet.csv_name}', 'w') as f:
            writer = csv.writer(f)
            writer.writerows(values)

    def pull(self):
        for file in self._iter_files():
            for sheet in self._iter_sheets(file):
                #print(f'{sheet.year}/{sheet.csv_name}')
                self._download(sheet)
                time.sleep(10)


def main():
    creds = get_creds(SCOPES, 'token.json')
    puller = BudgetPuller(creds, './testdl/')
    puller.pull()


if __name__ == '__main__':
    main()
