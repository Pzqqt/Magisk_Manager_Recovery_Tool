try:
    import uos as os
except ImportError:
    import os
import re


MMRT_PATH = "/tmp/mmr"
WORK_PATH = "/magisk"
MODULE_BACKUP_PATH = "/sdcard/TWRP/magisk_module_backup"
MAGISK_DB = "/data/adb/magisk.db"

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
    SULOGS_DB = "/data/user_de/0/com.topjohnwu.magisk/databases/sulogs.db"
    SULOGS_LABEL_APPNAME = 'appName'
    SULOGS_LABEL_FROMUID = 'fromUid'

def _ls(p):
    """ List all files in the specified directory, excluding 'lost+found' """
    try:
        return [f for f in os.listdir(p) if f != "lost+found"]
    except OSError:  # No such directory
        return []

def ls_mount_path():
    """ List all Magisk modules (module id) """
    return _ls(WORK_PATH)

def ls_module_backup_path():
    """ List all backed up Magisk modules """
    return _ls(MODULE_BACKUP_PATH)

def get_package_name_by_uid(uid):
    """ Get package name by uid from packages.list file """
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
    """ Get human readable file size """
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
