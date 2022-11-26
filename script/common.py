try:
    import uos as os
except ImportError:
    import os
import re
import _stat


MMRT_PATH = "/tmp/mmr"
WORK_PATH = "/magisk"
MODULE_BACKUP_PATH = "/sdcard/TWRP/magisk_module_backup"
MAGISK_DB = "/data/adb/magisk.db"

# https://github.com/micropython/micropython-lib/blob/0051a5ef50cdaf88975c2496ca32fd9b5f06050b/unix-ffi/os/os/__init__.py#L161
def os_path_walk(top, topdown=True):
    files = []
    dirs = []
    for fname, mode, _ in os.ilistdir(top):
        if _stat.S_ISDIR(mode):
            if fname != "." and fname != "..":
                dirs.append(fname)
        else:
            files.append(fname)
    if topdown:
        yield top, dirs, files
    for d in dirs:
        yield from os_path_walk(top + "/" + d, topdown)
    if not topdown:
        yield top, dirs, files

# https://github.com/micropython/micropython-lib/blob/0051a5ef50cdaf88975c2496ca32fd9b5f06050b/python-stdlib/os-path/os/path.py#L49
def os_path_exists(path):
    try:
        os.stat(path)
        return True
    except OSError:
        return False

def find_sulogs_db():
    sulogs_db_file = '/data/user_de/0/com.topjohnwu.magisk/databases/sulogs.db'
    if os_path_exists(sulogs_db_file):
        return sulogs_db_file
    for root, dirs, files in os_path_walk('/data/user_de/0'):
        for file in files:
            if file == "sulogs.db":
                return '/'.join([root, file])
    return ""

def file_getprop(f, p):
    with open(f, "r", encoding="utf-8") as _f:
        while l := _f.readline():
            if re_match := re.match(r'^%s=(.*)' % p, l.rstrip()):
                return re_match.group(1)
        return ""

MAGISK_VER = file_getprop("/data/adb/magisk/util_functions.sh", "MAGISK_VER")
MAGISK_VER_CODE = int(file_getprop("/data/adb/magisk/util_functions.sh", "MAGISK_VER_CODE"))

if MAGISK_VER_CODE < 20200:
    SULOGS_DB = MAGISK_DB
    SULOGS_LABEL_APPNAME = 'app_name'
    SULOGS_LABEL_FROMUID = 'from_uid'
else:
    SULOGS_DB = find_sulogs_db()
    SULOGS_LABEL_APPNAME = 'appName'
    SULOGS_LABEL_FROMUID = 'fromUid'

def _ls(p):
    """ 列出指定目录下的所有文件, 排除'lost+found' """
    try:
        return [f for f in os.listdir(p) if f != "lost+found"]
    except OSError:  # No such directory
        return []

def ls_mount_path():
    """ 列出所有Magisk模块(模块id) """
    return _ls(WORK_PATH)

def ls_module_backup_path():
    """ 列出所有已备份的Magisk模块 """
    return _ls(MODULE_BACKUP_PATH)

def get_package_name_by_uid(uid):
    """ 从packages.list文件中, 通过uid获取包名 """
    if not isinstance(uid, int):
        uid = str(uid)
        assert uid.isdigit(), "Argument 'uid' must be a number."
    with open("/data/system/packages.list", "r", encoding="utf-8") as f:
        while l := f.readline():
            # micropython's re module doesn't seem to support special character sets
            # if re_match := re.match(r'^([\d\w\.]+) %s ' % uid, l):
            if re_match := re.match(r'^([a-zA-Z0-9_\.]+) %s ' % uid, l):
                return re_match.group(1)
        return ""

def get_file_size(file_path):
    """ 获取人类可读的文件大小 """
    try:
        f_size = os.stat(file_path)[6]
    except OSError:  # No such file
        return "Unknown"
    if f_size < 1024:
        return "%s bytes" % (f_size, )
    if f_size < 1024 * 1024:
        return "%0.1f KB" % (f_size / 1024, )
    if f_size < 1024 * 1024 * 1024:
        return "%0.1f MB" % (f_size / 1024 / 1024, )
    return "%0.1f GB" % (f_size / 1024 / 1024 / 1024, )
