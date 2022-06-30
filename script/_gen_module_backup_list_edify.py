from common import MMRT_PATH, MODULE_BACKUP_PATH, ls_module_backup_path, get_file_size


AC_4="%s/template/META-INF/com/google/android/aroma/module_backup_list.edify" % MMRT_PATH

with open(AC_4, "w", encoding="utf-8") as f:
    f.write('''
        menubox(
            "恢复已备份的模块",
            "模块备份目录:\n%s",
            "@welcome",
            "module_backup_list.prop",

            "返回", "", "@back2",
    ''' % MODULE_BACKUP_PATH)
    backedup_modules = ls_module_backup_path()
    if not backedup_modules:
        f.write('            "如果你看到了此选项", "说明你尚未备份任何 Magisk 模块...", "@what",\n')
    else:
        for backedup_file in backedup_modules:
            f.write('            "%s", "", "@default",\n' % backedup_file.rsplit('.', 2)[0])
    f.write('''
            "", "", ""
        );
        setvar("bm_id", "");
        prop("module_backup_list.prop", "selected") == "1" && back("2");
    ''')
    for index, backedup_file in enumerate(backedup_modules, 2):
        f.write('''
        if prop("module_backup_list.prop", "selected") == "%s" then
            setvar("bm_id", "%s");
            setvar("bm_size", "%s");
        endif;
        ''' % (
            index,
            backedup_file.rsplit('.', 2)[0],
            get_file_size("%s/%s" % (MODULE_BACKUP_PATH, backedup_file))
        ))
    f.write('\n')
