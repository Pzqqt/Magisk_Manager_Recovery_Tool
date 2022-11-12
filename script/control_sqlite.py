try:
    import usys as sys
except ImportError:
    import sys

import usqlite

from common import MAGISK_VER_CODE, MAGISK_DB, SULOGS_DB, SULOGS_LABEL_APPNAME, SULOGS_LABEL_FROMUID


def _wrap_usqlite(db_file, sql, extra=()):
    """ 简单地包装usqlite模块, 简化使用 """
    con = usqlite.connect(db_file)
    try:
        with con.execute(sql, extra) as cur:
            return list(cur)
    finally:
        con.close()

################################################################
# 以下这些函数供其他py脚本调用
################################################################

def get_app_name(uid):
    """ 从保存su日志的数据库中, 通过uid获取对应app的名字(不是包名) """
    if not SULOGS_DB:
        return ""
    r = _wrap_usqlite(
        SULOGS_DB,
        "SELECT %s FROM logs WHERE %s=? LIMIT 1" % (SULOGS_LABEL_APPNAME, SULOGS_LABEL_FROMUID),
        (uid,)
    )
    if not r:
        return ""
    return r[0][0]

def get_saved_package_name_uid_policy():
    """ 获取已保存的root授权, 返回(包名, uid, policy)
    注: policy: 1: 已拒绝root权限, 2: 已授予root权限
    """
    return _wrap_usqlite(MAGISK_DB, "SELECT package_name, uid, policy FROM policies ORDER BY uid")

def get_saved_uid_policy():
    """ 获取已保存的root授权, 返回(uid, policy)
    注: 自Magisk 24305之后, 数据库中不再保存包名
    """
    return _wrap_usqlite(MAGISK_DB, "SELECT uid, policy FROM policies ORDER BY uid")

def set_policy(uid, policy):
    """ 修改Magisk数据库, 对指定uid设置root授权 """
    _wrap_usqlite(MAGISK_DB, "UPDATE policies SET policy=? WHERE uid=?", (policy, uid))

def get_package_name_by_uid_from_magisk_db(uid):
    """ 从Magisk数据库中, 通过uid获取包名 """
    r = _wrap_usqlite(
        MAGISK_DB,
        "SELECT package_name FROM policies WHERE uid=? LIMIT 1",
        (uid,)
    )
    if not r:
        return ""
    return r[0][0]

################################################################
# 以下这些函数与其他脚本交互
################################################################

def clear_su_log():
    """ 清空MagiskSU日志 """
    if not SULOGS_DB:
        return 2
    try:
        _wrap_usqlite(SULOGS_DB, "DELETE FROM logs")
        return 0
    except:
        return 1

class MagiskSettings:
    key = ""
    check = False
    error_message = ""

    @classmethod
    def _check(cls):
        if not cls.check:
            if __name__ == "__main__":
                sys.exit(-1)
            raise NotImplementedError(cls.error_message)

    @classmethod
    def get(cls):
        cls._check()
        r = _wrap_usqlite(MAGISK_DB, "SELECT value FROM settings WHERE key='%s'" % cls.key)
        if not r:
            # 数据库中没有键时则认为已禁用
            return 0
        return r[0][0]

    @classmethod
    def set(cls, value):
        cls._check()
        try:
            _wrap_usqlite(
                MAGISK_DB,
                "REPLACE INTO settings (key, value) VALUES ('%s', ?)" % cls.key,
                (value,)
            )
            return 0
        except:
            return 1

class MagiskHide(MagiskSettings):
    key = "magiskhide"
    check = MAGISK_VER_CODE < 23010
    error_message = "Magisk Hide has been removed in Magisk 23010+."

class Zygisk(MagiskSettings):
    key = "zygisk"
    check = MAGISK_VER_CODE >= 23010
    error_message = "Zygisk is only available in Magisk 23010+."

class DenyList(MagiskSettings):
    key = "denylist"
    check = MAGISK_VER_CODE >= 23010
    error_message = "Deny List is only available in Magisk 23010+."

if __name__ == "__main__":
    if len(sys.argv) == 2:
        if sys.argv[1] == "clear_su_log":
            sys.exit(clear_su_log())
        if sys.argv[1] == "get_magiskhide_status":
            sys.exit(MagiskHide.get())
        if sys.argv[1] == "get_zygisk_status":
            sys.exit(Zygisk.get())
        if sys.argv[1] == "get_denylist_status":
            sys.exit(DenyList.get())
    elif len(sys.argv) == 3:
        if sys.argv[1] == "set_magiskhide_status":
            sys.exit(MagiskHide.set(sys.argv[2]))
        if sys.argv[1] == "set_zygisk_status":
            sys.exit(Zygisk.set(sys.argv[2]))
        if sys.argv[1] == "set_denylist_status":
            sys.exit(DenyList.set(sys.argv[2]))
    print('''Usage: %s <operate>

operate:
    clear_su_log                  : Clear MagiskSU logs
    set_policy <uid> <vaule>      : Change policy value
    get_magiskhide_status         : Get Magisk Hide status (NOT for Magisk 23010+)
    set_magiskhide_status <value> : Set Magisk Hide status (0: disable, 1: enable) (NOT for Magisk 23010+)
    get_zygisk_status             : Get Zygisk status (only for Magisk 23010+)
    set_zygisk_status <value>     : Set Zygisk status (0: disable, 1: enable) (only for Magisk 23010+)
    get_denylist_status           : Get Deny List status (only for Magisk 23010+)
    set_denylist_status <value>   : Set Deny List status (0: disable, 1: enable) (only for Magisk 23010+)
    ''' % sys.argv[0])
