#! /usr/bin/python3
"""Code Runner Like VsCode
Usage:
    crlvc <file>
"""

import sys
from pathlib import Path
from json import dump, loads
from subprocess import check_call, CalledProcessError


def load_filetypes():
    config_path = Path(__file__).parent.absolute() / 'code_runner.json'
    if not config_path.exists():
        supported_filetypes = {
            "java": "cd {dir} && javac {fileName} && java {fileNameWithoutExt}",
            "c": "cd {dir} && gcc {fileName} -o {fileNameWithoutExt} && {dir}{fileNameWithoutExt}",
            "cpp": "cd {dir} && g++ {fileName} -o {fileNameWithoutExt} && {dir}{fileNameWithoutExt}",
            "py": "python -u {file}",
            "ts": "deno run {file}",
            "rs": "cd {dir} && rustc {fileName} && {dir}{fileNameWithoutExt}"
        }
        with open(config_path, 'w') as json_file:
            dump(supported_filetypes, json_file)
    with open(config_path, 'r') as myfile:
        config = myfile.read()
    return loads(config)


def run_code(file):
    filePath = Path(file)
    fileName = filePath.name
    fileNameWithoutExt = filePath.stem
    file_extension = fileName.replace(fileNameWithoutExt,'')
    dir = filePath.parent.absolute()
    commands = load_filetypes()
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
