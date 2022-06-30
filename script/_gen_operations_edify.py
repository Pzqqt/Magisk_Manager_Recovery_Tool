from common import MMRT_PATH, WORK_PATH, file_getprop, ls_mount_path


AC_2="%s/template/META-INF/com/google/android/aroma/operations.edify" % MMRT_PATH

installed_modules = sorted(
    ls_mount_path(),
    key=lambda x: file_getprop("%s/%s/module.prop" % (WORK_PATH, x), "name")  # Sort by module name
)

with open(AC_2, "w", encoding="utf-8") as f:
    f.write('''
menubox(
    "Main menu",
    "Choose an action" +
    getvar("exec_buffer") +
    getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "Reboot", "Reboot your device", "@refresh",
    "Exit", getvar("exit_text2"), "@back2",
    ''')
    if not installed_modules:
        f.write('    "If you see this option", "You have not installed any Magisk modules...", "@what",\n')
    else:
        for module in installed_modules:
            f.write('''
    file_getprop("{WORK_PATH}/{module}/module.prop", "name") || "(No info provided)",
    "<i><b>" + (file_getprop("{WORK_PATH}/{module}/module.prop", "version") || "(No info provided)") +
    "\nAuthor: " + (file_getprop("{WORK_PATH}/{module}/module.prop", "author") || "(No info provided)") + "</b></i>",
    prop("module_icon.prop", "module.icon.{module}") || "@removed",
            '''.format(WORK_PATH=WORK_PATH, module=module)
            )
    f.write('''
    "Advanced options", "", "@action"
);
    ''')
    for index, module in enumerate(installed_modules, 3):
        # TODO: No modsize
        f.write('''
if prop("operations.prop", "selected") == "{index}" then
    setvar("modid", "{module}");
    setvar("modname", file_getprop("{WORK_PATH}/{module}/module.prop", "name") || "(No info provided)");
    setvar("modsize", "");
endif;
        '''.format(WORK_PATH=WORK_PATH, index=index, module=module)
        )
    f.write('setvar("operations_last_index", "%s");\n' % (
        len(installed_modules)+3 if installed_modules else 4
    ))
