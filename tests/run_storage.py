import argparse
import os
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools'))
from lupa.luajit21 import LuaRuntime


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute("package.path = 'backend/?.lua;backend/?/init.lua;' .. package.path")
    return lua


class StorageTests(unittest.TestCase):
    pass


def register(name):
    def run(self):
        lua = runtime()
        specs = lua.execute((ROOT / 'tests/storage_spec.lua').read_text(encoding='utf-8'))
        specs[name]()
    setattr(StorageTests, 'test_' + name, run)


def validate_local():
    steam_exe = subprocess.check_output([
        'powershell', '-NoProfile', '-Command',
        '(Get-Process steam -ErrorAction Stop | Select-Object -First 1).Path',
    ], text=True).strip()
    steam_path = str(Path(steam_exe).parent)
    lua = runtime()

    def listing(path):
        with os.scandir(path) as entries:
            return lua.table_from([
                lua.table_from({'name': entry.name, 'is_file': entry.is_file()})
                for entry in entries
            ])

    def read(path):
        with open(path, 'rb') as source:
            return source.read(4 * 1024 * 1024 + 1).decode('utf-8-sig')

    filesystem = lua.table_from({'list': listing, 'is_directory': os.path.isdir})
    scan = lua.eval('require("storage.installations").scan')
    result = scan(steam_path, filesystem, read)
    games = list(result['games'].values())
    for game in games:
        assert os.path.isdir(game['installPath'])
        assert Path(game['installPath']).drive.upper() == game['drive']
    print(f"Local read-only scan: {len(games)} installed apps; "
          f"{len(set(game['drive'] for game in games))} drive(s); "
          f"{result['skippedLibraries']} inaccessible libraries; "
          f"{result['skippedManifests']} invalid manifests; "
          f"library metadata warning: {bool(result['metadataWarning'])}.")


if __name__ == '__main__':
    os.chdir(ROOT)
    parser = argparse.ArgumentParser()
    parser.add_argument('--local-steam', action='store_true')
    args = parser.parse_args()
    if args.local_steam:
        validate_local()
    else:
        specs = runtime().execute((ROOT / 'tests/storage_spec.lua').read_text(encoding='utf-8'))
        for name in sorted(specs.keys()):
            register(name)
        unittest.main(argv=[sys.argv[0]], verbosity=2)
