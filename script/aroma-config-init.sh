#!/sbin/sh

ls_mount_path() { ls -1 /magisk | grep -v 'lost+found'; }

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

get_module_info() {
    if [ -f /magisk/$1/module.prop ]; then
        infotext=`file_getprop /magisk/$1/module.prop $2`
        if [ ${#infotext} -ne 0 ]; then
            echo $infotext
        else
            echo "(No info provided)"
        fi
    else
        echo "(No info provided)"
    fi
}

gen_aroma_config() {
    installed_modules=`ls_mount_path`
    echo $installed_modules > /tmp/mmr/script/modules_ids
    ac_tmp=/tmp/mmr/script/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    chmod 0755 $ac_tmp
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
        exec("/sbin/sh", "/tmp/mmr/script/umount-magisk.sh");
        reboot("now");
    else
        goto("main_menu");
    endif;
endif;

# Exit
if prop("operations.prop", "selected") == "2" then
    if confirm("Exit",
               "Are you sure to quit Magisk Manager Recovery Tool?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/umount-magisk.sh");
        exit("");
    else
        goto("main_menu");
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
            echo "    setvar(\"modname\", \"$(file_getprop /magisk/$module/module.prop name)\");" >> $ac_tmp
            echo "endif;" >> $ac_tmp
            echo "" >> $ac_tmp
        done
        echo "if cmp(prop(\"operations.prop\", \"selected\"), \">=\", \"3\") &&" >> $ac_tmp
        echo "    cmp(prop(\"operations.prop\", \"selected\"), \"<=\", \"$i\")" >> $ac_tmp
        cat >> $ac_tmp <<EOF
then
    setvar("stat_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status", getvar("modid")));
    setvar("stat_am_code", exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", "status_am", getvar("modid")));

    if cmp(getvar("stat_code"),"==", "0") then
        setvar("module_status", "Disabled");
    endif;
    if cmp(getvar("stat_code"),"==", "1") then
        setvar("module_status", "Enabled");
    endif;
    if cmp(getvar("stat_code"),"==", "2") then
        alert(
            "Note",
            "This module has been removed.\n\n",
            "@warning",
            "OK"
        );
        back("1");
    endif;
    if cmp(getvar("stat_code"),"==", "3") then
        setvar("module_status", "Ready update");
    endif;
    if cmp(getvar("stat_code"),"==", "4") then
        setvar("module_status", "Ready remove");
    endif;

    if cmp(getvar("stat_am_code"),"==", "0") then
        setvar("module_am_status", "Disabled");
    endif;
    if cmp(getvar("stat_am_code"),"==", "1") then
        setvar("module_am_status", "Enabled");
    endif;

    menubox(
        "Module: " + getvar("modname"),
        "Module ID: " + getvar("modid") + "\n" +
        "Module status: " + getvar("module_status") + "\n" +
        "auto_mount status: " + getvar("module_am_status"),
        "@welcome",
        "modoperations.prop",

        "View description",   "", "@info",
        "Enable module",      "", "@action2",
        "Disable module",     "", "@crash",
        "Enable auto_mount",  "", "@action2",
        "Disable auto_mount", "", "@crash",
        "Remove",             "", "@delete"
    );

    if prop("modoperations.prop", "selected") == "1" then
        exec("/sbin/sh", "/tmp/mmr/script/get-description.sh", getvar("modid"));
        alert(
            "Description",
            getvar("exec_buffer"),
            "@info",
            "Back"
        );
        back("1");
    endif;
    if prop("modoperations.prop", "selected") == "2" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh on_module " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "3" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh off_module " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "4" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh on_auto_mount " + getvar("modid") + "\n");
    endif;
    if prop("modoperations.prop", "selected") == "5" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh off_auto_mount " + getvar("modid") + "\n");
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
else
EOF
    fi
    echo "    if prop(\"operations.prop\", \"selected\") == cal(\"$i\", \"+\", \"1\") then" >> $ac_tmp
    cat >> $ac_tmp <<EOF
        menubox(
            "advanced options",
            "Choose an action" + getvar("core_only_mode_warning"),
            "@welcome",
            "advanced.prop",

            "Save recovery log",    "Copies /tmp/recovery.log to internal SD", "@action",
            "Shrinking magisk.img", "Shrinking magisk.img capacity.\nRecommended to use after removing large modules.", "@action",
            getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
            "Back",                 "", "@back2"
        );
        if prop("advanced.prop", "selected") == "1" then
            write("/tmp/mmr/cmd.sh",
                  "#!/sbin/sh\n" +
                  "cp /tmp/recovery.log /sdcard/\n"
                  );
        endif;
        if prop("advanced.prop", "selected") == "2" then
            write("/tmp/mmr/cmd.sh",
                  "#!/sbin/sh\n" +
                  "/tmp/mmr/script/shrink-magiskimg.sh\n"
                  );
        endif;
        if prop("advanced.prop", "selected") == "3" then
            if cmp(getvar("core_only_mode_code"),"==", "0") then
                if confirm("Warning",
                           "If you enable Magisk core only mode,\nno modules will be load.\nBut MagiskSU and MagiskHide will still be enabled.\nContinue?",
                           "@warning") == "no"
                then
                    back("1");
                endif;
            endif;
            write("/tmp/mmr/cmd.sh",
                  "#!/sbin/sh\n" +
                  "/tmp/mmr/script/core-mode.sh switch\n"
                  );
        endif;
        if prop("advanced.prop", "selected") == "4" then
            back("2");
        endif;
    endif;
EOF
    [ ${#installed_modules} -eq 0 ] || echo "    endif;" >> $ac_tmp
    cat >> $ac_tmp <<EOF

pleasewait("Executing Shell...");

setvar("exitcode", exec("/sbin/sh", "/tmp/mmr/cmd.sh"));

ini_set("text_next", "Done");
ini_set("icon_next", "@next");

if prop("advanced.prop", "selected") == "2" then
    if cmp(getvar("exitcode"),"==","0") then
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
            exit("");
        else
            reboot("now");
        endif;
    else
        alert(
            "Failed",
            getvar("exec_buffer"),
            "@crash",
            "Exit"
        );
        exit("");
    endif;
endif;

if cmp(getvar("exitcode"),"==","0") then
    textbox(
        "Done",
        "Operation complete",
        "@done",
        "\n" + "<b>EXIT CODE: " + getvar("exitcode") + "\n\n" +
        "No errors occurred."+ "</b>" + "\n\n" +
        getvar("exec_buffer")
    );
else
    textbox(
        "Failed",
        "Operation failed",
        "@crash",
        "\n" + "<b>EXIT CODE: " + getvar("exitcode") + "\n\n" +
        "An error occurred during the execution of the operation." + "\n" +
        "Please check the error message." + "</b>" + "\n\n" +
        getvar("exec_buffer")
    );
endif;

goto("main_menu");

EOF
    sync
}

gen_aroma_config
