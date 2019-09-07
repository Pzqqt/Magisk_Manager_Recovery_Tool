#!/sbin/sh

. /tmp/mmr/script/common.sh

ls_modules_sort_by_name() {
    local installed_modules_tmp=`ls_mount_path`
    [ -z "$installed_modules_tmp" ] && return
    for d in $installed_modules_tmp; do echo "$d, "$(file_getprop ${workPath}/${d}/module.prop name); done | \
    sort -k2 -f | while read line; do echo ${line%,*}; done
}

gen_aroma_config() {
    ac_tmp=/tmp/mmr/template/META-INF/com/google/android/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    installed_modules=`ls_modules_sort_by_name`
    cat >> $ac_tmp <<EOF
exec("/sbin/sh", "/tmp/mmr/script/count-modules.sh");

menubox(
    "Main menu",
    "Choose an action" +
    getvar("exec_buffer") +
    getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "Reboot", "Reboot your device", "@refresh",
    "Exit", getvar("exit_text2"), "@back2",
EOF
    if [ -z "$installed_modules" ]; then
        echo "    \"If you see this option\", \"You have not installed any Magisk modules...\", \"@what\"," >> $ac_tmp
    else
        for module in $installed_modules; do
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
    if confirm(
        "Reboot",
        "Are you sure want to reboot your device?",
        "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        reboot("now");
    endif;
endif;

# Exit
if prop("operations.prop", "selected") == "2" then
    if confirm(
        "Exit",
        "Are you sure to quit Magisk Manager Recovery Tool?",
        "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        exit("");
    endif;
endif;

EOF
    if [ -z "$installed_modules" ]; then
        i=3
    else
        i=2
        for module in $installed_modules; do
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

    setvar("module_remove_icon", "@delete");
    setvar("module_remove_text2", "");
    if getvar("stat_code") == "0" || getvar("stat_code") == "5" then
        setvar("module_status", "<#f00>Disabled</#>");
        setvar("module_status_switch_text",  "Enable module");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@action2");
    endif;
    if getvar("stat_code") == "1" || getvar("stat_code") == "4" then
        setvar("module_status", "<#0f0>Enabled</#>");
        setvar("module_status_switch_text",  "Disable module");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@offaction");
    endif;
    if cmp(getvar("stat_code"), ">=", "4") then
        setvar("module_status", "<#f00>Will be removed after reboot</#>");
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
        setvar("module_status", "<#f00>Will be updated after reboot</#>");
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
        "Mount status: " + getvar("module_mount_status") + "\n" +
        "Module status: " + getvar("module_status"),
        "@welcome",
        "modoperations.prop",

        "View description", "", "@info",
        "View module content", "", "@info",
        getvar("module_status_switch_text"), getvar("module_status_switch_text2"), getvar("module_status_switch_icon"),
        getvar("module_mount_status_switch_text"), getvar("module_mount_status_switch_text2"), getvar("module_mount_status_switch_icon"),
        getvar("module_remove_switch_text"), getvar("module_remove_switch_text2"), getvar("module_remove_switch_icon"),
        "Remove directly", getvar("module_remove_text2"), getvar("module_remove_icon")
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
        pleasewait("Executing Shell...");
        exec("/sbin/sh", "/tmp/mmr/script/get-module-tree.sh", getvar("modid"));
        ini_set("text_next", "");
        ini_set("icon_next", "@none");
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
        if confirm(
            "Warning!",
            getvar("module_remove_warning") + "Are you sure want to remove this module?",
            "@warning") == "yes"
        then
            setvar("module_operate", "remove");
        else
            back("1");
        endif;
    endif;
    if exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", getvar("module_operate"), getvar("modid")) != "0" then
        alert(
            "Failed",
            getvar("exec_buffer"),
            "@crash",
            "OK"
        );
    endif;
    prop("modoperations.prop", "selected") != "6" && back("1");
endif;

if prop("operations.prop", "selected") == "$(expr $i + 1)" then
    menubox(
        "Advanced options",
        "Choose an action" + getvar("core_only_mode_warning"),
        "@welcome",
        "advanced.prop",

        "Save recovery log", "Copies /tmp/recovery.log to internal SD", "@action",
        "Shrinking magisk.img", getvar("shrink_text2"), getvar("shrink_icon"),
        getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
        "Superuser", "", "@action",
        "Uninstall Magisk", "Root will be fully removed from the device.", "@action",
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
        cmp(getvar("MAGISK_VER_CODE"), ">", "18100") && back("1");
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
    if prop("advanced.prop", "selected") == "3" then
        exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "switch");
        back("1");
    endif;
    if prop("advanced.prop", "selected") == "4" then
        if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "get_sqlite3_path") == "2" then
            alert(
                "Not available",
                "Sorry,\nThis option is not available\nbecause we cannot find available sqlite3 programs\nfrom your device.",
                "@crash",
                "OK"
            );
            back("1");
        endif;
        setvar("magiskhide_status", exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "get_magiskhide_status"));
        if getvar("magiskhide_status") == "0" then
            setvar("magiskhide_switch_text", "Magisk Hide is disabled");
            setvar("magiskhide_switch_text_2", "Why would you disable Magisk Hide?:/");
        endif;
        if getvar("magiskhide_status") == "1" then
            setvar("magiskhide_switch_text", "Magisk Hide is enabled");
            setvar("magiskhide_switch_text_2", "Hide Magisk from various forms of detection.");
        endif;
        menubox(
            "Superuser",
            "Choose an action" + getvar("core_only_mode_warning"),
            "@welcome",
            "magisksu.prop",

            "Clear MagiskSU logs", "", "@action",
            "Root manager", "", "@action",
            getvar("magiskhide_switch_text"), getvar("magiskhide_switch_text_2"), "@action",
            "Back", "", "@back2"
        );
        prop("magisksu.prop", "selected") == "4" && back("2");
        if prop("magisksu.prop", "selected") == "1" then
            pleasewait("Executing Shell...");
            if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "clear_su_log") == "0" then
                alert(
                    "Done",
                    "Operation completed, no error occurred during execution.",
                    "@done",
                    "OK"
                );
            else
                alert(
                    "Failed",
                    "An error occurred during execution, please check.\n\n" + getvar("exec_buffer"),
                    "@crash",
                    "OK"
                );
            endif;
            back("1");
        endif;
        if prop("magisksu.prop", "selected") == "2" then
            pleasewait("Generating list...");
            exec("/sbin/sh", "/tmp/mmr/script/control-suapps.sh");
            ini_set("text_next", "Apply");
            checkbox(
                "Root manager",
                "Check the box to grant superuser rights, otherwise denied.",
                "@welcome",
                "magisksu_apps.prop",

EOF
    pps=`/tmp/mmr/script/control-sqlite.sh get_saved_package_name_uid | sed 's/|/=/g'`
    if [ -z "$pps" ]; then
        echo "                \"Seem you have not given rights for any app\",\"\", 2," >> $ac_tmp
    else
        for pp in $pps; do
            package_name=${pp%=*}
            uid_=${pp#*=}
            app_name=`/tmp/mmr/script/control-sqlite.sh get_app_name ${uid_}`
            [ -z "$app_name" ] || app_name=" (${app_name})"
            echo "                \"${package_name}${app_name}\", \"uid: ${uid_}\", 0," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
                "", "", 3
            );
            pleasewait("Executing Shell...");
            if exec("/sbin/sh", "/tmp/mmr/script/control-suapps.sh", "apply_change") == "0" then
                if getvar("exec_buffer") != "" then
                    alert(
                        "Done",
                        "Your changes have been applied:\n\n" + getvar("exec_buffer"),
                        "@done",
                        "OK"
                    );
                endif;
            else
                alert(
                    "Failed",
                    "Command execution failed, please check.\n\n" + getvar("exec_buffer"),
                    "@crash",
                    "OK"
                );
            endif;
            back("2");
        endif;
        if prop("magisksu.prop", "selected") == "3" then
            getvar("magiskhide_status") == "0" && setvar("magiskhide_status_set", "1");
            getvar("magiskhide_status") == "1" && setvar("magiskhide_status_set", "0");
            if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "set_magiskhide_status", getvar("magiskhide_status_set")) != "0" then
                alert(
                    "Failed",
                    "An error occurred during execution, please check.\n\n" + getvar("exec_buffer"),
                    "@crash",
                    "OK"
                );
            endif;
            back("1");
        endif;
    endif;
    if prop("advanced.prop", "selected") == "5" then
        if confirm(
            "Warning!",
            "Are you sure want to uninstall Magisk?\n\nAll modules will be disabled/removed.\nRoot will be removed. and your data\npotentially encrypted if not already.",
            "@warning",
            "I'm sure",
            "Give up") == "no"
        then
            back("1");
        endif;
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        setvar("uninstall_exitcode",
            install(
                "Uninstall Magisk",
                "Uninstalling Magisk, please wait...",
                "@welcome",
                "Press Next to continue..."
            )
        );
        if getvar("uninstall_exitcode") == "0" then
            if confirm(
                "Uninstall completed",
                "Magisk has been successfully uninstalled.",
                "@warning",
                "Exit to Recovery",
                "Reboot") == "no"
            then
                reboot("onfinish");
            endif;
        else
            alert(
                "Uninstall failed",
                "Sorry, we were unable to uninstall Magisk successfully.\n\nPlease try uninstalling from Magisk Manager after booting device.",
                "@crash",
                "Exit"
            );
        endif;
        exit("");
    endif;
    if prop("advanced.prop", "selected") == "6" then
        menubox(
            "Debug options",
            "Choose an action",
            "@alert",
            "debug.prop",

            "Force update module_icon.prop", "Regenerate module icon index file", "@action",
            "Back", "", "@back2"
        );
        prop("debug.prop", "selected") == "1" && exec("/sbin/sh", "/tmp/mmr/script/gen-icons-prop.sh", "--regen");
    endif;
endif;

goto("main_menu");
EOF
    sync
}

gen_aroma_config
