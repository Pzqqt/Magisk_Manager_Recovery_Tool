#!/sbin/sh

ls_mount_path() { ls -1 /magisk | grep -v 'lost+found'; }

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

gen_aroma_config() {
    cd /tmp/mmr/script/
    cp ./ac-1.in ./aroma-config
    chmod 0755 ./aroma-config
    if [ -z $(ls_mount_path) ]; then
        echo "    \"如果你看到了此选项\", \"说明你尚未安装任何 Magisk 模块...\", \"\"," >> ./aroma-config
    else
        for module in $(ls_mount_path); do
            module_name=$(file_getprop /magisk/$module/module.prop name)
            module_author=$(file_getprop /magisk/$module/module.prop author)
            module_version=$(file_getprop /magisk/$module/module.prop version)
            echo "    \"$module_name\", \"作者: $module_author \n版本: $module_version\", \"@default\"," >> ./aroma-config
        done
    fi
    cat >> ./aroma-config <<EOF
    "保存 recovery 日志",       "复制 /tmp/recovery.log 到内部存储", "@action"
);

# Reboot
if prop("operations.prop", "selected") == "1" then
    if confirm("重启",
               "您确定要重启设备吗?",
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
    if confirm("退出",
               "您确定要退出 Magisk Manager 工具吗?",
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
    echo "" >> ./aroma-config
    if [ -z $(ls_mount_path) ]; then
        i=3
        echo "if prop(\"operations.prop\", \"selected\") == \"3\" then" >> ./aroma-config
        echo "    back(\"1\");" >> ./aroma-config
        echo "endif;" >> ./aroma-config
        echo "" >> ./aroma-config
    else
        i=2
        for module in $(ls_mount_path); do
            let i+=1
            echo "if prop(\"operations.prop\", \"selected\") == \"$i\" then" >> ./aroma-config
            echo "    setvar(\"romid\", \"$module\");" >> ./aroma-config
            echo "    setvar(\"romname\", \"$(file_getprop /magisk/$module/module.prop name)\");" >> ./aroma-config
            echo "endif;" >> ./aroma-config
            echo "" >> ./aroma-config
        done
        echo "if cmp(prop(\"operations.prop\", \"selected\"), \">=\", \"3\") &&" >> ./aroma-config
        echo "    cmp(prop(\"operations.prop\", \"selected\"), \"<=\", \"$i\")" >> ./aroma-config
        cat >> ./aroma-config <<EOF
then
    setvar("stat_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status", getvar("romid")));
    setvar("stat_am_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status_am", getvar("romid")));

    if cmp(getvar("stat_code"),"==", "0") then
        setvar("module_status", "已禁用");
    endif;
    if cmp(getvar("stat_code"),"==", "1") then
        setvar("module_status", "已启用");
    endif;
    if cmp(getvar("stat_code"),"==", "2") then
        setvar("module_status", "已移除");
    endif;
    if cmp(getvar("stat_code"),"==", "3") then
        setvar("module_status", "待更新");
    endif;
    if cmp(getvar("stat_code"),"==", "4") then
        setvar("module_status", "待移除");
    endif;

    if cmp(getvar("stat_am_code"),"==", "0") then
        setvar("module_am_status", "\nauto_mount 状态: 已禁用");
    endif;
    if cmp(getvar("stat_am_code"),"==", "1") then
        setvar("module_am_status", "\nauto_mount 状态: 已启用");
    endif;
    if cmp(getvar("stat_am_code"),"==", "2") then
        setvar("module_am_status", "");
    endif;

    menubox(
        "模块: " + getvar("romname"),
        "模块状态: " + getvar("module_status") + getvar("module_am_status"),
        "@welcome",
        "romoperations.prop",

        "启用该模块",      "", "@action2",
        "禁用该模块",      "", "@crash",
        "启用 auto_mount", "", "@action2",
        "禁用 auto_mount", "", "@crash",
        "移除",            "", "@delete"
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
        if confirm("警告",
                   "您确定要移除该模块吗?",
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
    echo "if prop(\"operations.prop\", \"selected\") == cal(\"$i\", \"+\", \"1\") then" >> ./aroma-config
    cat >> ./aroma-config <<EOF
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
              "echo \"Copying /tmp/recovery.log to internal SD\"\n" +
              "cp /tmp/recovery.log /sdcard/\n"
              );
EOF
    [ -z $(ls_mount_path) ] || echo "    endif;" >> ./aroma-config
    cat >> ./aroma-config <<EOF
endif;

pleasewait("正在执行脚本 ...");

setvar("exitcode", exec("/sbin/sh", "-ex", "/tmp/mmr/cmd.sh"));

# ini_set("text_back", "");
# ini_set("icon_back", "@none");
ini_set("text_next", "完成");
ini_set("icon_next", "@next");

if cmp(getvar("exitcode"),"==","0") then
    textbox(
        "完成",
        "操作完成",
        "@done",
        "\n" + "<b>退出码: " + getvar("exitcode") + "\n\n" +
        "执行操作过程中没有发生错误."+ "</b>" + "\n\n" +
        getvar("exec_buffer")
    );
else
    textbox(
        "失败",
        "操作失败",
        "@crash",
        "\n" + "<b>退出码: " + getvar("exitcode") + "\n\n" +
        "执行操作过程中有错误发生." + "\n" +
        "请检查错误信息." + "</b>" + "\n\n" +
        getvar("exec_buffer")
    );
endif;

goto("main_menu");

EOF
    sync
    chmod 0755 ./control-module.sh
    cd /tmp/mmr/
}

gen_aroma_config
