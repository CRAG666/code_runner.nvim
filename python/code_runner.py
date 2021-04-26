#! /usr/bin/python3
"""Code Runner Like VsCode
Usage:
    crlvc <file>
"""

import sys
from pathlib import Path
from json import loads
from subprocess import check_call, CalledProcessError


config_path = Path(__file__).parent.absolute() / 'code_runner.json'
with open(config_path, 'r') as myfile:
    config=myfile.read()
commands = loads(config)


def run_code(file):
    filePath = Path(file)
    fileName = filePath.name
    fileNameWithoutExt = filePath.stem
    file_extension = fileName.replace(fileNameWithoutExt,'')
    dir = filePath.parent.absolute()
    command_for_file = commands.get(
        file_extension[1:],
        "echo '{fileName} did not run. {file_extension} extension is not supported, if you want to support the extension modify code_runner.json'")
    command = eval(f'f"""{command_for_file}"""')
    try:
        check_call(command, shell=True)
    except CalledProcessError:
        print('Extension not supported')
    except OSError:
        print('Executable not found')
    finally:
        print(f"Press Enter to exit!")


if __name__ == '__main__':
    run_code(sys.argv[1])
