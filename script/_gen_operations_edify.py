from common import MMRT_PATH, WORK_PATH, file_getprop, ls_mount_path


AC_2="%s/template/META-INF/com/google/android/aroma/operations.edify" % MMRT_PATH

installed_modules = sorted(
    ls_mount_path(),
    key=lambda x: file_getprop("%s/%s/module.prop" % (WORK_PATH, x), "name")  # 按模块name排序
)

with open(AC_2, "w", encoding="utf-8") as f:
    f.write('''
menubox(
    "主菜单",
    "请选择操作" +
    getvar("exec_buffer") +
    getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "重启", "重启您的设备", "@refresh",
    "退出", getvar("exit_text2"), "@back2",
    ''')
    if not installed_modules:
        f.write('    "如果你看到了此选项", "说明你尚未安装任何 Magisk 模块...", "@what",\n')
    else:
        for module in installed_modules:
            f.write('''
    file_getprop("{WORK_PATH}/{module}/module.prop", "name") || "(未提供信息)",
    "<i><b>" + (file_getprop("{WORK_PATH}/{module}/module.prop", "version") || "(未提供信息)") +
    "\n作者: " + (file_getprop("{WORK_PATH}/{module}/module.prop", "author") || "(未提供信息)") + "</b></i>",
    prop("module_icon.prop", "module.icon.{module}") || "@removed",
            '''.format(WORK_PATH=WORK_PATH, module=module)
            )
    f.write('''
    "高级选项", "", "@action"
);
    ''')
    for index, module in enumerate(installed_modules, 3):
        # TODO: No modsize
        f.write('''
if prop("operations.prop", "selected") == "{index}" then
    setvar("modid", "{module}");
    setvar("modname", file_getprop("{WORK_PATH}/{module}/module.prop", "name") || "(未提供信息)");
    setvar("modsize", "");
endif;
        '''.format(WORK_PATH=WORK_PATH, index=index, module=module)
        )
    f.write('setvar("operations_last_index", "%s");\n' % (
        len(installed_modules)+3 if installed_modules else 4
    ))
