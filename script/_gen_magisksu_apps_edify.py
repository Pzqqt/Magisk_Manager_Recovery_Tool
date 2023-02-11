from common import MMRT_PATH, MAGISK_VER_CODE, get_package_name_by_uid
from control_sqlite import (
    get_app_name, get_saved_package_name_uid_policy, get_saved_uid_policy
)


AC_3 = "%s/template/META-INF/com/google/android/aroma/magisksu_apps.edify" % MMRT_PATH

def _get_saved_package_name_uid():
    if MAGISK_VER_CODE < 24305:
        return [(package_name, uid) for package_name, uid, _ in get_saved_package_name_uid_policy()]
    else:
        return [(get_package_name_by_uid(uid), uid) for uid, _ in get_saved_uid_policy()]

with open(AC_3, "w", encoding="utf-8") as f:
    f.write('''
            checkbox(
                "Root manager",
                "Check the box to grant superuser rights, otherwise denied.",
                "@welcome",
                "magisksu_apps.prop",
    ''')
    f.write("\n")

    saved_package_name_uid = _get_saved_package_name_uid()
    if not saved_package_name_uid:
        f.write('                "Seem you have not given rights for any app", "", 2,\n')
    else:
        for package_name, uid in saved_package_name_uid:
            app_name = get_app_name(uid)
            if app_name:
                app_name = " (%s)" % app_name
            f.write('                "%s%s", "uid: %s", 0,\n' % (package_name, app_name, uid))

    f.write('''
                "", "", 3
            );
        '''
    )
    f.write("\n")
