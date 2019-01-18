#!/sbin/sh

ls_mount_path() { ls -1 /magisk | grep -v 'lost+found'; }

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

gen_aroma_config() {
    installed_modules=`ls_mount_path`
    echo $installed_modules > /tmp/mmr/script/modules_ids
    ac_tmp=/tmp/mmr/script/aroma-config
    mv /tmp/mmr/script/ac-1.in $ac_tmp
    chmod 0755 $ac_tmp
    if [ ${#installed_modules} -eq 0 ]; then
        echo "    \"如果你看到了此选项\", \"说明你尚未安装任何 Magisk 模块...\", \"@what\"," >> $ac_tmp
    else
        for module in ${installed_modules}; do
            module_name=$(file_getprop /magisk/$module/module.prop name)
            module_author=$(file_getprop /magisk/$module/module.prop author)
            module_version=$(file_getprop /magisk/$module/module.prop version)
            echo "    \"$module_name\", \"作者: $module_author \n<i>版本: $module_version</i>\", prop(\"module_icon.prop\", \"module.icon.${module}\")," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
    "保存 recovery 日志", "复制 /tmp/recovery.log 到内部存储", "@action",
    "瘦身 magisk.img",    "压缩 magisk.img 容量以减少其存储空间占用.\n建议在移除大型模块后使用.", "@action"
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
               "您确定要退出 Magisk Manager Recovery 工具吗?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "-ex", "/tmp/mmr/script/umount-magisk.sh");
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
    setvar("stat_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status", getvar("modid")));
    setvar("stat_am_code", exec("/sbin/sh", "-ex", "/tmp/mmr/script/control-module.sh", "status_am", getvar("modid")));

    if cmp(getvar("stat_code"),"==", "0") then
        setvar("module_status", "已禁用");
    endif;
    if cmp(getvar("stat_code"),"==", "1") then
        setvar("module_status", "已启用");
    endif;
    if cmp(getvar("stat_code"),"==", "2") then
        alert(
            "注意",
            "这个模块已经被移除了.\n\n",
            "@warning",
            "确定"
        );
        back("1");
    endif;
    if cmp(getvar("stat_code"),"==", "3") then
        setvar("module_status", "待更新");
    endif;
    if cmp(getvar("stat_code"),"==", "4") then
        setvar("module_status", "待移除");
    endif;

    if cmp(getvar("stat_am_code"),"==", "0") then
        setvar("module_am_status", "已禁用");
    endif;
    if cmp(getvar("stat_am_code"),"==", "1") then
        setvar("module_am_status", "已启用");
    endif;

    menubox(
        "模块: " + getvar("modname"),
        "模块 ID: " + getvar("modid") + "\n" +
        "模块状态: " + getvar("module_status") + "\n" +
        "auto_mount 状态: " + getvar("module_am_status"),
        "@welcome",
        "modoperations.prop",

        "查看模块描述",    "", "@info",
        "启用该模块",      "", "@action2",
        "禁用该模块",      "", "@crash",
        "启用 auto_mount", "", "@action2",
        "禁用 auto_mount", "", "@crash",
        "移除",            "", "@delete"
    );

    if prop("modoperations.prop", "selected") == "1" then
        alert(
            "描述",
            resread("modinfo/" + getvar("modid") + ".txt"),
            "@info",
            "返回"
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
        if confirm("警告",
                   "您确定要移除该模块吗?",
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
    # Save recovery log
EOF
    fi
    echo "    if prop(\"operations.prop\", \"selected\") == cal(\"$i\", \"+\", \"1\") then" >> $ac_tmp
    cat >> $ac_tmp <<EOF
        write("/tmp/mmr/cmd.sh",
              "#!/sbin/sh\n" +
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

pleasewait("正在执行脚本 ...");

setvar("exitcode", exec("/sbin/sh", "-ex", "/tmp/mmr/cmd.sh"));

ini_set("text_next", "完成");
ini_set("icon_next", "@next");

if prop("operations.prop", "selected") == cal("$i", "+", "2") then
    if cmp(getvar("exitcode"),"==","0") then
        alert(
            "运行成功",
            getvar("exec_buffer"),
            "@done",
            "确定"
        );
        if confirm(
            "注意",
            "magisk 镜像已取消挂载.\n\n本工具即将退出.\n如果还需使用, 请重新卡刷本工具.\n\n",
            "@warning",
            "退出到 Recovery",
            "重启设备") == "yes"
        then
            exit("");
        else
            reboot("now");
        endif;
    else
        alert(
            "运行失败",
            getvar("exec_buffer"),
            "@crash",
            "退出"
        );
        exit("");
    endif;
endif;

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
}

gen_mod_info() {
    modinfodir=/tmp/mmr/template/META-INF/com/google/android/aroma/modinfo
    mkdir -p $modinfodir
    for module in ${installed_modules}; do
        infofile=${modinfodir}/${module}.txt
        if [ -f /magisk/$module/module.prop ]; then
            infotext=`file_getprop /magisk/$module/module.prop description`
            if ! [ -z $infotext ]; then
                echo $infotext > $infofile
                continue
            fi
        fi
        echo "无法获取模块描述!" > $infofile
    done
}

gen_aroma_config

gen_mod_info
