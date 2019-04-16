#!/sbin/sh

workPath=/magisk
settings_save_prop=/sdcard/TWRP/mmrt.prop

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

ls_mount_path() { ls -1 ${workPath} | grep -v 'lost+found'; }

ls_modules_sort_by_id() { ls_mount_path | sort -f; }

ls_modules_sort_by_name() {
    local installed_modules_tmp=`ls_mount_path`
    [ ${#installed_modules_tmp} -eq 0 ] && return
    local idn_file=/tmp/mmr/modules_idm
    : > $idn_file
    for d in $installed_modules_tmp; do
        echo "$d, "$(file_getprop ${workPath}/${d}/module.prop name) >> $idn_file
    done
    sort -k2 -f $idn_file | while read line; do
        echo ${line%,*}
    done
}

gen_aroma_config() {
    if [ -f $settings_save_prop ] && [ $(file_getprop $settings_save_prop "sort_by_name") -eq 1 ]; then
        installed_modules=`ls_modules_sort_by_name`
    else
        installed_modules=`ls_modules_sort_by_id`
    fi
    ac_tmp=/tmp/mmr/script/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    if [ ${#installed_modules} -eq 0 ]; then
        echo "    \"If you see this option\", \"You have not installed any Magisk modules...\", \"@what\"," >> $ac_tmp
    else
        for module in ${installed_modules}; do
            echo "    file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(No info provided)\"," >> $ac_tmp
            echo "    \"<i><b>\" + (file_getprop(\"${workPath}/${module}/module.prop\", \"version\") || \"(No info provided)\") +" >> $ac_tmp
            echo "    \"\nAuthor: \" + (file_getprop(\"${workPath}/${module}/module.prop\", \"author\") || \"(No info provided)\") + \"</b></i>\"," >> $ac_tmp
            echo "    prop(\"module_icon.prop\", \"module.icon.${module}\") || \"@removed\"," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
    "Advanced options", "", "@action"
);

# Reboot
if prop("operations.prop", "selected") == "1" then
    if confirm("Reboot",
               "Are you sure want to reboot your device?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        reboot("now");
    endif;
endif;

# Exit
if prop("operations.prop", "selected") == "2" then
    if confirm("Exit",
               "Are you sure to quit Magisk Manager Recovery Tool?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        exit("");
    endif;
endif;

EOF
    if [ ${#installed_modules} -eq 0 ]; then
        i=3
    else
        i=2
        for module in ${installed_modules}; do
            let i+=1
            echo "if prop(\"operations.prop\", \"selected\") == \"$i\" then" >> $ac_tmp
            echo "    setvar(\"modid\", \"$module\");" >> $ac_tmp
            echo "    setvar(\"modname\", file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(No info provided)\");" >> $ac_tmp
            echo "    setvar(\"modsize\", \"$(du -sh ${workPath}/${module} | awk '{print $1}')\");" >> $ac_tmp
            echo "endif;" >> $ac_tmp
            echo "" >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
if cmp(prop("operations.prop", "selected"), ">=", "3") &&
   cmp(prop("operations.prop", "selected"), "<=", "$i") &&
   getvar("modid") != ""
then

    setvar("stat_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status", getvar("modid")));
    setvar("stat_mount_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status_" + getvar("mount_switch_flag") + "_mount", getvar("modid")));

    if getvar("stat_code") == "2" then
        alert(
            "Note",
            "This module has been removed.\n",
            "@warning",
            "OK"
        );
        back("1");
    endif;

    if getvar("stat_code") == "0" || getvar("stat_code") == "5" then
        setvar("module_status", "Disabled");
        setvar("module_status_switch_text",  "Enable module");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@action2");
    endif;
    if getvar("stat_code") == "1" || getvar("stat_code") == "4" then
        setvar("module_status", "Enabled");
        setvar("module_status_switch_text",  "Disable module");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@offaction");
    endif;
    if cmp(getvar("stat_code"), ">=", "4") then
        setvar("module_status", "Ready remove");
        setvar("module_remove_switch_text",  "<b><i>Undo</i></b> remove at next reboot");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon",  "@refresh");
    else
        setvar("module_remove_switch_text",  "Remove at next reboot");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon",  "@delete");
    endif;

    if getvar("stat_mount_code") == "0" then
        setvar("module_mount_status", "Disabled");
        setvar("module_mount_status_switch_text",  "Enable mount");
        setvar("module_mount_status_switch_text2", "");
        setvar("module_mount_status_switch_icon",  "@action2");
    endif;
    if getvar("stat_mount_code") == "1" then
        setvar("module_mount_status", "Enabled");
        setvar("module_mount_status_switch_text",  "Disable mount");
        setvar("module_mount_status_switch_text2", "");
        setvar("module_mount_status_switch_icon",  "@offaction");
    endif;

    if getvar("stat_code") == "3" then
        setvar("module_status", "Ready update");
        setvar("module_status_switch_text",        "Enable/Disable module");
        setvar("module_status_switch_text2",       "Unallowed operation");
        setvar("module_status_switch_icon",        "@crash");
        setvar("module_mount_status_switch_text",  "Enable/Disable mount");
        setvar("module_mount_status_switch_text2", "Unallowed operation");
        setvar("module_mount_status_switch_icon",  "@crash");
        setvar("module_remove_switch_text2",       "Unallowed operation");
        setvar("module_remove_switch_icon",        "@crash");
        setvar("module_remove_text2",              "Unallowed operation");
        setvar("module_remove_icon",               "@crash");
    endif;

    menubox(
        "Module: " + getvar("modname"),
        "Module ID: " + getvar("modid") + "\n" +
        "Module size: " + getvar("modsize") + "\n" +
        "Module status: " + getvar("module_status") + "\n" +
        "Mount status: " + getvar("module_mount_status"),
        "@welcome",
        "modoperations.prop",

        "View description", "", "@info",
        "View module content", "", "@info",
        getvar("module_status_switch_text"), getvar("module_status_switch_text2"), getvar("module_status_switch_icon"),
        getvar("module_mount_status_switch_text"), getvar("module_mount_status_switch_text2"), getvar("module_mount_status_switch_icon"),
        getvar("module_remove_switch_text"), getvar("module_remove_switch_text2"), getvar("module_remove_switch_icon"),
        getvar("module_remove_text"), getvar("module_remove_text2"), getvar("module_remove_icon")
    );

    if prop("modoperations.prop", "selected") == "1" then
        alert(
            "Description",
            file_getprop("${workPath}/" + getvar("modid") + "/module.prop", "description") || "(No info provided)",
            "@info",
            "Back"
        );
        back("1");
    endif;
    if prop("modoperations.prop", "selected") == "2" then
        exec("/sbin/sh", "/tmp/mmr/script/get-module-tree.sh", getvar("modid"));
        textbox(
            "Preview",
            "Module directory structure:",
            "@info",
            getvar("exec_buffer")
        );
        back("2");
    endif;
    if getvar("stat_code") == "3" then
        alert(
            "Unallowed operation",
            "This module will be updated after reboot.\nPlease reboot once and try again.",
            "@crash",
            "Back"
        );
        back("1");
    endif;
    prop("modoperations.prop", "selected") == "3" && setvar("module_operate", "switch_module");
    prop("modoperations.prop", "selected") == "4" && setvar("module_operate", "switch_" + getvar("mount_switch_flag") + "_mount");
    prop("modoperations.prop", "selected") == "5" && setvar("module_operate", "switch_remove");
    if prop("modoperations.prop", "selected") == "6" then
        if confirm("Warning!",
                   "Are you sure want to remove this module?",
                   "@warning") == "yes"
        then
            setvar("module_operate", "remove");
        else
            back("1");
        endif;
    endif;
    if exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", getvar("module_operate"), getvar("modid")) == "0" then
        alert(
            "Done",
            getvar("exec_buffer"),
            "@done",
            "OK"
        );
    else
        alert(
            "Failed",
            getvar("exec_buffer"),
            "@crash",
            "OK"
        );
    endif;
    prop("modoperations.prop", "selected") != "6" && back("1");
endif;

if prop("operations.prop", "selected") == cal("$i", "+", "1") then
    menubox(
        "Advanced options",
        "Choose an action" + getvar("core_only_mode_warning"),
        "@welcome",
        "advanced.prop",

        "Save recovery log", "Copies /tmp/recovery.log to internal SD", "@action",
        "Shrinking magisk.img", getvar("shrink_text2"), getvar("shrink_icon"),
        getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
        "Clear MagiskSU logs", "", "@action",
        "Remove all MagiskSU permissions", "Remove all saved apps MagiskSU permissions", "@action",
        "Reject all MagiskSU permissions", "Reject all saved apps MagiskSU permissions", "@action",
        "Allow all MagiskSU permissions", "Allow all saved apps MagiskSU permissions", "@action",
        "Select module list sorting method", "Current: " + getvar("sort_text2"), "@action",
        "Debug options", "", "@action",
        "Back", "", "@back2"
    );
    if prop("advanced.prop", "selected") == "1" then
        exec("/sbin/sh", "/tmp/mmr/script/save-rec-log.sh");
        alert(
            "Done",
            "Recovery log has been saved to /sdcard/recovery.log!",
            "@done",
            "OK"
        );
        back("1");
    endif;
    if prop("advanced.prop", "selected") == "2" then
        if cmp(getvar("MAGISK_VER_CODE"), ">", "18100") then
            back("1");
        else
            pleasewait("Executing Shell...");
            if exec("/sbin/sh", "/tmp/mmr/script/shrink-magiskimg.sh") == "0" then
                alert(
                    "Done",
                    getvar("exec_buffer"),
                    "@done",
                    "OK"
                );
                if confirm(
                    "Note",
                    "The magisk image has been unmounted.\n\nThis tool will exit.\nIf you still need to use, please reflash this tool.\n\n",
                    "@warning",
                    "Exit to Recovery",
                    "Reboot") == "no"
                then
                    reboot("now");
                endif;
            else
                alert(
                    "Failed",
                    getvar("exec_buffer"),
                    "@crash",
                    "Exit"
                );
            endif;
            exit("");
        endif;
    endif;
    if prop("advanced.prop", "selected") == "3" then
        exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "switch");
        alert(
            "Done",
            getvar("exec_buffer"),
            "@done",
            "OK"
        );
        back("1");
    endif;
    prop("advanced.prop", "selected") == "4" && setvar("sqlite_operate", "clear_su_log");
    prop("advanced.prop", "selected") == "5" && setvar("sqlite_operate", "clear_su_policies");
    prop("advanced.prop", "selected") == "6" && setvar("sqlite_operate", "reject_all_su");
    prop("advanced.prop", "selected") == "7" && setvar("sqlite_operate", "allow_all_su");
    if cmp(prop("advanced.prop", "selected"), ">=", "4") &&
       cmp(prop("advanced.prop", "selected"), "<=", "7")
    then
        if prop("advanced.prop", "selected") == "5" then
            if confirm("Warning!",
                       "Are you sure want to remove all MagiskSU perm?\nThis operation cannot be undone.",
                       "@warning") == "no"
            then
                back("1");
            endif;
        endif;
        pleasewait("Executing Shell...");
        if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", getvar("sqlite_operate")) == "0" then
            alert(
                "Done",
                "Operation completed, no error occurred during execution.",
                "@done",
                "OK"
            );
            back("1");
        else
            alert(
                "Failed",
                "An error occurred during execution, please check.\n\n" + getvar("exec_buffer"),
                "@crash",
                "OK"
            );
            back("1");
        endif;
    endif;
    if prop("advanced.prop", "selected") == "8" then
        if confirm(
            "Select module list sorting method",
            "Please select sorting method:",
            "@info",
            getvar("sort_text2_s1"),
            getvar("sort_text2_s2")) == "yes"
        then
            setvar("sort_by_name", "0");
        else
            setvar("sort_by_name", "1");
        endif;
        exec("/sbin/sh", "/tmp/mmr/script/save-settings.sh", "sort_by_name", getvar("sort_by_name"));
        alert(
            "Done",
            "You select \"Sort " + iif(getvar("sort_by_name") == "0", getvar("sort_text2_s1"), getvar("sort_text2_s2")) + "\",\n" +
            "Will be applied the next time you use this tool.",
            "@done",
            "OK"
        );
        back("1");
    endif;
    if prop("advanced.prop", "selected") == "9" then
        menubox(
            "Debug options",
            "Choose an action",
            "@alert",
            "debug.prop",

            "Force update module_icon.prop", "Regenerate module icon index file", "@action",
            "Back", "", "@back2"
        );
        prop("debug.prop", "selected") == "1" && exec("/sbin/sh", "/tmp/mmr/script/gen-icons-prop.sh", "_", "true");
    endif;
endif;

goto("main_menu");
EOF
    sync
}

gen_aroma_config
