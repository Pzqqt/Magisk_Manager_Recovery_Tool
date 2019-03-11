#!/sbin/sh

workPath=/magisk

ls_mount_path() { ls -1 $workPath | grep -v 'lost+found'; }

get_module_info() {
    /tmp/mmr/script/get-module-info.sh $1 $2
}

get_magisk_info() {
    /tmp/mmr/script/get-magisk-info.sh $1
}

gen_aroma_config() {
    [ -d /data/adb/modules ] && migrated=true || migrated=false
    installed_modules=`ls_mount_path`
    echo $installed_modules > /tmp/mmr/script/modules_ids
    ac_tmp=/tmp/mmr/script/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    MAGISK_VER_CODE=$(get_magisk_info "MAGISK_VER_CODE")
    cat >> $ac_tmp <<EOF
setvar("sysinfo",
    getvar("sysinfo") +
    "Magisk Version\t: " + "<b><#selectbg_g>${MAGISK_VER_CODE}</#></b>\n\n"
);
EOF
    if ! $migrated; then
        cat >> $ac_tmp <<EOF
setvar("sysinfo",
    getvar("sysinfo") +
    "magisk.img Size\t: "  + "<b><#selectbg_g>" + getdisksize("/magisk", "m") + " MB" + "</#></b>\n" +
    "\tFree\t\t\t: "       + "<b><#selectbg_g>" + getdiskfree("/magisk", "m") + " MB" + "</#></b>\n"
);
EOF
    fi
    cat >> $ac_tmp <<EOF
viewbox(
    "<~welcome.title>",
    "<~welcome.text1> <b>" + ini_get("rom_name") + "</b>.\n\n" + "<~welcome.text2>\n\n\n\n" +

    "  <~welcome.version>\t\t\t: " + "<b><#selectbg_g>" + ini_get("rom_version") + "</#></b>\n" +
    "  <~welcome.updated>\t\t: " + "<b><#selectbg_g>" + ini_get("rom_date") + "</#></b>\n\n\n" +

    getvar("sysinfo"),

    "@welcome"
);

gotolabel("main_menu");

ini_set("text_next", "Next");
ini_set("icon_next", "@next");

exec("/sbin/sh", "/tmp/mmr/script/gen-icons-prop.sh");

setvar("core_only_mode_code", exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "status"));

if cmp(getvar("core_only_mode_code"), "==", "0") then
    setvar("core_only_mode_warning", "");
    setvar("core_only_mode_switch_text", "Enable Magisk core only mode");
    setvar("core_only_mode_switch_text2", "Block loading all modules");
endif;
if cmp(getvar("core_only_mode_code"), "==", "1") then
    setvar("core_only_mode_warning", "\n<#f00>Magisk core only mode is enabled, no modules will be load.</#>");
    setvar("core_only_mode_switch_text", "Disable Magisk core only mode");
    setvar("core_only_mode_switch_text2", "");
endif;

menubox(
    "Main menu",
    "Choose an action" + getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "Reboot", "Reboot your device", "@refresh",
EOF
    if $migrated; then
        echo "    \"Exit\", \"Exit to recovery\", \"@back2\"," >> $ac_tmp
    else
        echo "    \"Exit\", \"Unmount $workPath & exit to recovery\", \"@back2\"," >> $ac_tmp
    fi
    if [ ${#installed_modules} -eq 0 ]; then
        echo "    \"If you see this option\", \"You have not installed any Magisk modules...\", \"@what\"," >> $ac_tmp
    else
        for module in ${installed_modules}; do
            module_name=$(get_module_info $module name)
            module_author=$(get_module_info $module author)
            module_version=$(get_module_info $module version)
            echo "    \"$module_name\", \"<i><b>$module_version\nAuthor: $module_author</b></i>\", prop(\"module_icon.prop\", \"module.icon.${module}\")," >> $ac_tmp
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

setvar("modid", "NONE");

EOF
    if [ ${#installed_modules} -eq 0 ]; then
        i=3
        echo "if prop(\"operations.prop\", \"selected\") == \"3\" then" >> $ac_tmp
        echo "    back(\"1\");" >> $ac_tmp
        echo "endif;" >> $ac_tmp
        echo "" >> $ac_tmp
    else
        i=2
        for module in ${installed_modules}; do
            let i+=1
            echo "if prop(\"operations.prop\", \"selected\") == \"$i\" then" >> $ac_tmp
            echo "    setvar(\"modid\", \"$module\");" >> $ac_tmp
            echo "    setvar(\"modname\", \"$(get_module_info $module name)\");" >> $ac_tmp
            echo "    setvar(\"modsize\", \"$(get_module_info $module size)\");" >> $ac_tmp
            echo "endif;" >> $ac_tmp
            echo "" >> $ac_tmp
        done
        cat >> $ac_tmp <<EOF
if cmp(prop("operations.prop", "selected"), ">=", "3") &&
   cmp(prop("operations.prop", "selected"), "<=", "$i")
then
    setvar("stat_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status", getvar("modid")));
    setvar("stat_am_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status_am", getvar("modid")));

    if cmp(getvar("stat_code"), "==", "2") then
        alert(
            "Note",
            "This module has been removed.\n\n",
            "@warning",
            "OK"
        );
        back("1");
    endif;

    if cmp(getvar("stat_code"), "==", "0") then
        setvar("module_status", "Disabled");
    endif;
    if cmp(getvar("stat_code"), "==", "1") then
        setvar("module_status", "Enabled");
    endif;
    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_status", "Ready update");
    endif;
    if cmp(getvar("stat_code"), "==", "4") then
        setvar("module_status", "Ready remove");
    endif;

    if cmp(getvar("stat_am_code"), "==", "0") then
        setvar("module_am_status", "Disabled");
    endif;
    if cmp(getvar("stat_am_code"), "==", "1") then
        setvar("module_am_status", "Enabled");
    endif;

    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_status_switch_text",     "Enable/Disable module");
        setvar("module_status_switch_text2",    "Unallowed operation");
        setvar("module_status_switch_icon",     "@crash");
        setvar("module_am_status_switch_text",  "Enable/Disable auto_mount");
        setvar("module_am_status_switch_text2", "Unallowed operation");
        setvar("module_am_status_switch_icon",  "@crash");
    else
        if cmp(getvar("stat_code"), "==", "4") then
            setvar("module_status_switch_text",  "Enable/Disable module");
            setvar("module_status_switch_text2", "");
            setvar("module_status_switch_icon",  "@what");
        else
            if cmp(getvar("stat_code"), "==", "0") then
                setvar("module_status_switch_text",  "Enable module");
                setvar("module_status_switch_text2", "");
                setvar("module_status_switch_icon",  "@action2");
            endif;
            if cmp(getvar("stat_code"), "==", "1") then
                setvar("module_status_switch_text",  "Disable module");
                setvar("module_status_switch_text2", "");
                setvar("module_status_switch_icon",  "@offaction");
            endif;
        endif;
        if cmp(getvar("stat_am_code"), "==", "0") then
            setvar("module_am_status_switch_text",  "Enable auto_mount");
            setvar("module_am_status_switch_text2", "");
            setvar("module_am_status_switch_icon",  "@action2");
        endif;
        if cmp(getvar("stat_am_code"), "==", "1") then
            setvar("module_am_status_switch_text",  "Disable auto_mount");
            setvar("module_am_status_switch_text2", "");
            setvar("module_am_status_switch_icon",  "@offaction");
        endif;
    endif;

    if cmp(getvar("stat_code"), "==", "4") then
        setvar("module_remove_switch_text", "<b><i>Undo</i></b>  remove module at next reboot");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon", "@refresh");
    else
        setvar("module_remove_switch_text", "Remove at next reboot");

        if cmp(getvar("stat_code"), "==", "3") then
            setvar("module_remove_switch_text2", "Unallowed operation");
            setvar("module_remove_switch_icon",  "@crash");
        else
            setvar("module_remove_switch_text2", "");
            setvar("module_remove_switch_icon",  "@delete");
        endif;
    endif;

    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_remove_warning", "Unallowed operation");
        setvar("module_remove_icon",    "@crash");
    else
        setvar("module_remove_warning", "");
        setvar("module_remove_icon",    "@delete");
    endif;

    menubox(
        "Module: " + getvar("modname"),
        "Module ID: " + getvar("modid") + "\n" +
        "Module size: " + getvar("modsize") + " MB\n" +
        "Module status: " + getvar("module_status") + "\n" +
        "auto_mount status: " + getvar("module_am_status"),
        "@welcome",
        "modoperations.prop",

        "View description", "", "@info",
        "View module content", "", "@info",
        getvar("module_status_switch_text"), getvar("module_status_switch_text2"), getvar("module_status_switch_icon"),
        getvar("module_am_status_switch_text"), getvar("module_am_status_switch_text2"), getvar("module_am_status_switch_icon"),
        getvar("module_remove_switch_text"), getvar("module_remove_switch_text2"), getvar("module_remove_switch_icon"),
        "Remove", getvar("module_remove_warning"), getvar("module_remove_icon")
    );

    if prop("modoperations.prop", "selected") == "1" then
        exec("/sbin/sh", "/tmp/mmr/script/get-module-info.sh", getvar("modid"), "description");
        alert(
            "Description",
            getvar("exec_buffer"),
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
    if cmp(getvar("stat_code"), "==", "3") then
        alert(
            "Unallowed operation",
            "This module will be updated after reboot.\nPlease reboot once and try again.",
            "@crash",
            "Back"
        );
        back("1");
    endif;
    if prop("modoperations.prop", "selected") == "3" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh switch_module " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "4" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh switch_auto_mount " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "5" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh switch_remove " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "6" then
        if confirm("Warning!",
                   "Are you sure want to remove this module?",
                   "@warning") == "yes"
        then
            write("/tmp/mmr/cmd.sh",
                  "#!/sbin/sh\n" +
                  "/tmp/mmr/script/control-module.sh remove " + getvar("modid") + "\n");
        else
            back("1");
        endif;
    endif;
    setvar("exitcode", exec("/sbin/sh", "/tmp/mmr/cmd.sh"));
    if cmp(getvar("exitcode"), "==", "0") then
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
    if prop("modoperations.prop", "selected") != "6" then
        back("1");
    endif;
endif;
EOF
    fi
    cat >> $ac_tmp <<EOF
if prop("operations.prop", "selected") == cal("$i", "+", "1") then
    menubox(
        "advanced options",
        "Choose an action" + getvar("core_only_mode_warning"),
        "@welcome",
        "advanced.prop",

        "Save recovery log",    "Copies /tmp/recovery.log to internal SD", "@action",
EOF
    if $migrated; then
        echo "\"Shrinking magisk.img\", \"Not available\", \"@crash\"," >> $ac_tmp
    else
        echo "\"Shrinking magisk.img\", \"Shrinking magisk.img capacity.\nRecommended to use after removing large modules.\", \"@action\"," >> $ac_tmp
    fi
    cat >> $ac_tmp <<EOF
        getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
        "Back",                 "", "@back2"
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
EOF
    if $migrated; then
        echo "back(\"1\");" >> $ac_tmp
    else
        cat >> $ac_tmp <<EOF
        pleasewait("Executing Shell...");
        setvar("exitcode", exec("/sbin/sh", "/tmp/mmr/script/shrink-magiskimg.sh"));
        if cmp(getvar("exitcode"), "==", "0") then
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
                "Reboot") == "yes"
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
EOF
    fi
    cat >> $ac_tmp <<EOF
    endif;
    if prop("advanced.prop", "selected") == "3" then
        if cmp(getvar("core_only_mode_code"), "==", "0") then
            if confirm("Warning",
                       "If you enable Magisk core only mode,\nno modules will be load.\nBut MagiskSU and MagiskHide will still be enabled.\nContinue?",
                       "@warning") == "no"
            then
                back("1");
            endif;
        endif;
        exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "switch");
        alert(
            "Done",
            getvar("exec_buffer"),
            "@done",
            "OK"
        );
        back("1");
    endif;
endif;

goto("main_menu");
EOF
    sync
}

gen_aroma_config
