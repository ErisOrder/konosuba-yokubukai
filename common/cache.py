from hashlib import md5
import json
import os


def get_md5(path):
    with open(path, 'rb') as binary:
        file_md5 = md5(binary.read()).hexdigest()
    return file_md5


class LoadableJson:
    filepath: str
    state: dict

    def __init__(self, path, default_state: dict):
        self.filepath = path
        self.state = default_state
        self.load()

    def load(self):
        if not os.path.exists(self.filepath):
            with open(self.filepath, "w", encoding='utf-8') as f:
                f.write(json.dumps(self.state))
        with open(self.filepath, "r", encoding='utf-8') as f:
            self.state = json.load(f)
        print(f"{self.filepath} loaded")

    def save(self):
        with open(self.filepath, "w", encoding='utf-8') as f:
            json.dump(self.state, f, ensure_ascii=False)
        print(f"{self.filepath} saved")


class HashStorage(LoadableJson):

    def __init__(self, storage_file):
        super().__init__(storage_file, {})

    def update_file(self, path):
        file_md5 = get_md5(path)
        self.state[path] = file_md5

    def check_changed(self, path):
        if not os.path.exists(path) or path not in self.state:
            return True
        else:
            file_md5 = get_md5(path)
            return file_md5 != self.state[path]