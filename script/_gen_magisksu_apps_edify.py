from common import MMRT_PATH, MAGISK_VER_CODE, get_package_name_by_uid
from control_sqlite import (
    get_app_name, get_saved_package_name_uid_policy, get_saved_uid_policy
)


AC_3 = "%s/template/META-INF/com/google/android/aroma/magisksu_apps.edify" % MMRT_PATH

with open(AC_3, "w", encoding="utf-8") as f:
    f.write('''
            checkbox(
                "授权管理",
                "勾选即为授予超级用户权限, 反之为拒绝.",
                "@welcome",
                "magisksu_apps.prop",
    ''')
    f.write("\n")
    if MAGISK_VER_CODE < 24305:
        saved_package_name_uid_policy = get_saved_package_name_uid_policy()
        if not saved_package_name_uid_policy:
            f.write('                "看起来你尚未授权任何应用 ...", "", 2,\n')
        else:
            for item in saved_package_name_uid_policy:
                package_name, uid, _ = item
                app_name = get_app_name(uid)
                if app_name:
                    app_name = " (%s)" % app_name
                f.write('                "%s%s", "uid: %s", 0,\n' % (package_name, app_name, uid))
    else:
        saved_uid_policy = get_saved_uid_policy()
        if not saved_uid_policy:
            f.write('                "看起来你尚未授权任何应用 ...", "", 2,\n')
        else:
            for item in saved_uid_policy:
                uid, _ = item
                package_name = get_package_name_by_uid(uid)
                app_name = get_app_name(uid)
                if app_name:
                    app_name = " (%s)" % app_name
                f.write('                "%s%s", "uid: %s", 0,\n' % (package_name, app_name, uid))
    f.write('''
            "", "", 3
        );
    ''')
    f.write("\n")
