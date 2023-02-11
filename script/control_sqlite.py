try:
    import usys as sys
except ImportError:
    import sys

import usqlite

from common import MAGISK_VER_CODE, MAGISK_DB, SULOGS_DB, SULOGS_LABEL_APPNAME, SULOGS_LABEL_FROMUID


def _wrap_usqlite(db_file, sql, extra=()):
    """ Simply wrap the usqlite module, simplifying usage """
    con = usqlite.connect(db_file)
    try:
        with con.execute(sql, extra) as cur:
            return list(cur)
    finally:
        con.close()

################################################################
# The following functions are called by other py scripts
################################################################

def get_app_name(uid):
    """ Get the name of app (not the package name) by uid from MagiskSu database """
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
    """ Get the saved root policies, return (package name, uid, policy)
    Note: policy: 1: root denied, 2: root granted
    """
    return _wrap_usqlite(MAGISK_DB, "SELECT package_name, uid, policy FROM policies ORDER BY uid")

def get_saved_uid_policy():
    """ Get the saved root policies, return (uid, policy)
    Note: Package names are no longer saved in Magisk database since Magisk 24305
    """
    return _wrap_usqlite(MAGISK_DB, "SELECT uid, policy FROM policies ORDER BY uid")

def set_policy(uid, policy):
    """ Modify the Magisk database and set root policy for the specified uid """
    _wrap_usqlite(MAGISK_DB, "UPDATE policies SET policy=? WHERE uid=?", (policy, uid))

def get_package_name_by_uid_from_magisk_db(uid):
    """ Get package name by uid from Magisk database """
    r = _wrap_usqlite(
        MAGISK_DB,
        "SELECT package_name FROM policies WHERE uid=? LIMIT 1",
        (uid,)
    )
    if not r:
        return ""
    return r[0][0]

################################################################
# The following functions interact with other scripts
################################################################

def clear_su_log():
    """ Clear MagiskSU logs """
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
            # When there is no key in the database, it's considered disabled
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

    def _main():
        if len(sys.argv) == 2:
            if sys.argv[1] == "clear_su_log":
                return clear_su_log()
            if sys.argv[1] == "get_magiskhide_status":
                return MagiskHide.get()
            if sys.argv[1] == "get_zygisk_status":
                return Zygisk.get()
            if sys.argv[1] == "get_denylist_status":
                return DenyList.get()
        elif len(sys.argv) == 3:
            if sys.argv[1] == "set_magiskhide_status":
                return MagiskHide.set(sys.argv[2])
            if sys.argv[1] == "set_zygisk_status":
                return Zygisk.set(sys.argv[2])
            if sys.argv[1] == "set_denylist_status":
                return DenyList.set(sys.argv[2])
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
        return 1

    sys.exit(_main())
