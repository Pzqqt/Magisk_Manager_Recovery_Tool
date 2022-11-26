try:
    import usys as sys
except ImportError:
    import sys

from common import MAGISK_VER_CODE
from control_sqlite import get_saved_uid_policy, set_policy

if MAGISK_VER_CODE >= 24305:
    from common import get_package_name_by_uid
else:
    from control_sqlite import get_package_name_by_uid_from_magisk_db as get_package_name_by_uid


MAGISKSU_APPS_PROP = "/tmp/aroma/magisksu_apps.prop"

def gen_prop():
    with open(MAGISKSU_APPS_PROP, "w", encoding="utf-8") as f:
        for index, item in enumerate(get_saved_uid_policy(), 1):
            _, policy = item
            f.write("item.0.%s=%s\n" % (index, policy-1))
    with open(MAGISKSU_APPS_PROP, 'rb') as f1, open(MAGISKSU_APPS_PROP+'.bak', 'wb') as f2:
        f2.write(f1.read())

def apply_change():

    def _parse_prop(prop_file):
        _dict = {}
        with open(prop_file, "r", encoding="utf-8") as f:
            while l := f.readline():
                l = l.rstrip()
                if not l:
                    continue
                key, _, value = l.partition('=')
                # key: "item.0.0" ~ "item.0.9"
                # index: 0 ~ 9
                index = int(key.rsplit('.', 1)[1])
                _dict[index] = int(value)
        return _dict

    index_to_uid = {}
    for index, item in enumerate(get_saved_uid_policy(), 1):
        uid, _ = item
        index_to_uid[index] = uid

    new_policies = _parse_prop(MAGISKSU_APPS_PROP)
    old_policies = _parse_prop(MAGISKSU_APPS_PROP+".bak")
    diff_policies = set(new_policies.items()) - set(old_policies.items())
    for index, value in diff_policies:
        uid = index_to_uid[index]
        set_policy(uid, value+1)
        package_name = get_package_name_by_uid(uid)
        if value == 1:
            print("允许 %s 获取超级用户权限" % package_name)
        elif value == 0:
            print("拒绝 %s 获取超级用户权限" % package_name)

if __name__ == "__main__":
    if len(sys.argv) == 1:
        gen_prop()
    elif len(sys.argv) == 2:
        if sys.argv[1] == "apply_change":
            apply_change()
