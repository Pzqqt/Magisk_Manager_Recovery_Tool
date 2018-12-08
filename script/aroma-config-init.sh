#!/sbin/sh

ls_mount_path() { ls -1 /magisk | grep -v 'lost+found'; }

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

gen_aroma_config() {
    installed_modules=`ls_mount_path`
    ac_tmp=/tmp/mmr/script/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    chmod 0755 $ac_tmp
    if [ ${#installed_modules} -eq 0 ]; then
        echo "    \"If you see this option\", \"You have not installed any Magisk modules...\", \"\"," >> $ac_tmp
    else
        for module in ${installed_modules}; do
            module_name=$(file_getprop /magisk/$module/module.prop name)
            module_author=$(file_getprop /magisk/$module/module.prop author)
            module_version=$(file_getprop /magisk/$module/module.prop version)
            echo "    \"$module_name\", \"Author: $module_author \nVersion: $module_version\", \"@default\"," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
    "Save recovery log",       "Copies /tmp/recovery.log to internal SD", "@action",
    "Shrinking magisk.img",    "Shrinking magisk.img capacity.\nRecommended to use after removing large modules.", "@action"
);

# Reboot
if prop("operations.prop", "selected") == "1" then
    if confirm("Reboot",
               "Are you sure want to reboot your device?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "-ex", "/tmp/mmr/script/umount-magisk.sh");
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
        exec("/sbin/sh", "-ex", "/tmp/mmr/script/umount-magisk.sh");
        exit("");
    else
        goto("main_menu");
    endif;
endif;

setvar("romid", "NONE");

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
            echo "    setvar(\"romid\", \"$module\");" >> $ac_tmp
            echo "    setvar(\"romname\", \"$(file_getprop /magisk/$module/module.prop name)\");" >> $ac_tmp
            echo "endif;" >> $ac_tmp
            echo "" >> $ac_tmp
        done
        echo "if cmp(prop(\"operations.prop\", \"selected\"), \">=\", \"3\") &&" >> $ac_tmp
        echo "    cmp(prop(\"operations.prop\", \"selected\"), \"<=\", \"$i\")" >> $ac_tmp
        cat >> $ac_tmp <<EOF
then
    setvar("stat_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status", getvar("romid")));
    setvar("stat_am_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status_am", getvar("romid")));

    if cmp(getvar("stat_code"),"==", "0") then
        setvar("module_status", "Disabled");
    endif;
    if cmp(getvar("stat_code"),"==", "1") then
        setvar("module_status", "Enabled");
    endif;
    if cmp(getvar("stat_code"),"==", "2") then
        setvar("module_status", "Removed");
    endif;
    if cmp(getvar("stat_code"),"==", "3") then
        setvar("module_status", "Ready update");
    endif;
    if cmp(getvar("stat_code"),"==", "4") then
        setvar("module_status", "Ready remove");
    endif;

    if cmp(getvar("stat_am_code"),"==", "0") then
        setvar("module_am_status", "\nauto_mount status: Disabled");
    endif;
    if cmp(getvar("stat_am_code"),"==", "1") then
        setvar("module_am_status", "\nauto_mount status: Enabled");
    endif;
    if cmp(getvar("stat_am_code"),"==", "2") then
        setvar("module_am_status", "");
    endif;

    menubox(
        "Module: " + getvar("romname"),
        "Module status: " + getvar("module_status") + getvar("module_am_status"),
        "@welcome",
        "romoperations.prop",

        "Enable module",      "", "@action2",
        "Disable module",     "", "@crash",
        "Enable auto_mount",  "", "@action2",
        "Disable auto_mount", "", "@crash",
        "Remove",             "", "@delete"
    );

    if prop("romoperations.prop", "selected") == "1" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh on_module " + getvar("romid") + "\n");
    endif;
    if prop("romoperations.prop", "selected") == "2" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh off_module " + getvar("romid") + "\n");
    endif;
    if prop("romoperations.prop", "selected") == "3" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh on_auto_mount " + getvar("romid") + "\n");
    endif;
    if prop("romoperations.prop", "selected") == "4" then
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/control-module.sh off_auto_mount " + getvar("romid") + "\n");
    endif;
    if prop("romoperations.prop", "selected") == "5" then
        if confirm("Warning!",
                   "Are you sure want to remove this module?",
                   "@warning") == "yes"
        then
            write("/tmp/mmr/cmd.sh",
                  "#!/sbin/sh\n" +
                  "/tmp/mmr/script/control-module.sh remove " + getvar("romid") + "\n");
        else
            back("1");
        endif;
    endif;
else
    # Save recovery log
EOF
    fi
    echo "    if prop(\"operations.prop\", \"selected\") == cal(\"$i\", \"+\", \"1\") then" >> $ac_tmp
    cat >> $ac_tmp <<EOF
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "echo \"Copying /tmp/recovery.log to internal SD\"\n" +
              "cp /tmp/recovery.log /sdcard/\n"
              );
    endif;
EOF
    echo "    if prop(\"operations.prop\", \"selected\") == cal(\"$i\", \"+\", \"2\") then" >> $ac_tmp
    cat >> $ac_tmp <<EOF
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "/tmp/mmr/script/shrink-magiskimg.sh\n"
              );
    endif;
EOF
    [ ${#installed_modules} -eq 0 ] || echo "    endif;" >> $ac_tmp
    cat >> $ac_tmp <<EOF

pleasewait("Executing Shell...");

setvar("exitcode", exec("/sbin/sh", "-ex", "/tmp/mmr/cmd.sh"));

# ini_set("text_back", "");
# ini_set("icon_back", "@none");
ini_set("text_next", "Done");
ini_set("icon_next", "@next");

if prop("operations.prop", "selected") == cal("$i", "+", "2") then
    if cmp(getvar("exitcode"),"==","0") then
        alert(
            "Done",
            getvar("exec_buffer"),
            "@done",
            "Next"
        );
        alert(
            "Note",
            "The magisk image has been unmounted.\n\nPress \"OK\" to exit.\nIf you need to continue using, please reflash this tool later.\n\n",
            "@warning",
            "OK"
        );
    else
        alert(
            "Failed",
            getvar("exec_buffer"),
            "@crash",
            "Exit"
        );
    endif;
    exec("umount", "/system");
    exit("");
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
