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
    "Magisk 版本\t\t: " + "<b><#selectbg_g>${MAGISK_VER_CODE}</#></b>\n\n"
);
EOF
    if ! $migrated; then
        cat >> $ac_tmp <<EOF
setvar("sysinfo",
    getvar("sysinfo") +
    "magisk.img 空间\t: "  + "<b><#selectbg_g>" + getdisksize("/magisk", "m") + " MB" + "</#></b>\n" +
    "\t剩余\t\t\t: "       + "<b><#selectbg_g>" + getdiskfree("/magisk", "m") + " MB" + "</#></b>\n"
);
EOF
    fi
    cat >> $ac_tmp <<EOF
viewbox(
    "<~welcome.title>",
    "<~welcome.text1> <b>" + ini_get("rom_name") + "</b>.\n\n" + "<~welcome.text2>\n\n\n\n\n" +

    "  <~welcome.version>\t\t\t: " + "<b><#selectbg_g>" + ini_get("rom_version") + "</#></b>\n" +
    "  <~welcome.updated>\t\t: " + "<b><#selectbg_g>" + ini_get("rom_date") + "</#></b>\n\n\n" +

    getvar("sysinfo"),

    "@welcome"
);

gotolabel("main_menu");

ini_set("text_next", "下一步");
ini_set("icon_next", "@next");

exec("/sbin/sh", "/tmp/mmr/script/gen-icons-prop.sh");

setvar("core_only_mode_code", exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "status"));

if cmp(getvar("core_only_mode_code"), "==", "0") then
    setvar("core_only_mode_warning", "");
    setvar("core_only_mode_switch_text", "启用 Magisk 核心模式");
    setvar("core_only_mode_switch_text2", "阻止载入所有模块");
endif;
if cmp(getvar("core_only_mode_code"), "==", "1") then
    setvar("core_only_mode_warning", "\n<#f00>Magisk 核心模式已启用, 所有模块均不会被载入.</#>");
    setvar("core_only_mode_switch_text", "禁用 Magisk 核心模式");
    setvar("core_only_mode_switch_text2", "");
endif;

menubox(
    "主菜单",
    "请选择操作" + getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "重启", "重启您的设备", "@refresh",
EOF
    if $migrated; then
        echo "    \"退出\", \"退出到 Recovery\", \"@back2\"," >> $ac_tmp
    else
        echo "    \"退出\", \"取消挂载 $workPath 并退出到 Recovery\", \"@back2\"," >> $ac_tmp
    fi
    if [ ${#installed_modules} -eq 0 ]; then
        echo "    \"如果你看到了此选项\", \"说明你尚未安装任何 Magisk 模块...\", \"@what\"," >> $ac_tmp
    else
        for module in ${installed_modules}; do
            module_name=$(get_module_info $module name)
            module_author=$(get_module_info $module author)
            module_version=$(get_module_info $module version)
            echo "    \"$module_name\", \"<i><b>$module_version\n作者: $module_author</b></i>\", prop(\"module_icon.prop\", \"module.icon.${module}\")," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
    "高级选项", "", "@action"
);

# Reboot
if prop("operations.prop", "selected") == "1" then
    if confirm("重启",
               "您确定要重启设备吗?",
               "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        reboot("now");
    endif;
endif;

# Exit
if prop("operations.prop", "selected") == "2" then
    if confirm("退出",
               "您确定要退出 Magisk Manager Recovery 工具吗?",
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
            "注意",
            "这个模块已经被移除了.\n\n",
            "@warning",
            "确定"
        );
        back("1");
    endif;

    if cmp(getvar("stat_code"), "==", "0") then
        setvar("module_status", "已禁用");
    endif;
    if cmp(getvar("stat_code"), "==", "1") then
        setvar("module_status", "已启用");
    endif;
    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_status", "待更新");
    endif;
    if cmp(getvar("stat_code"), "==", "4") then
        setvar("module_status", "待移除");
    endif;

    if cmp(getvar("stat_am_code"), "==", "0") then
        setvar("module_am_status", "已禁用");
    endif;
    if cmp(getvar("stat_am_code"), "==", "1") then
        setvar("module_am_status", "已启用");
    endif;

    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_status_switch_text",     "启用/禁用该模块");
        setvar("module_status_switch_text2",    "不允许的操作");
        setvar("module_status_switch_icon",     "@crash");
        setvar("module_am_status_switch_text",  "启用/禁用 auto_mount");
        setvar("module_am_status_switch_text2", "不允许的操作");
        setvar("module_am_status_switch_icon",  "@crash");
    else
        if cmp(getvar("stat_code"), "==", "0") then
            setvar("module_status_switch_text",  "启用该模块");
            setvar("module_status_switch_text2", "");
            setvar("module_status_switch_icon",  "@action2");
        endif;
        if cmp(getvar("stat_code"), "==", "1") then
            setvar("module_status_switch_text",  "禁用该模块");
            setvar("module_status_switch_text2", "");
            setvar("module_status_switch_icon",  "@offaction");
        endif;
        if cmp(getvar("stat_am_code"), "==", "0") then
            setvar("module_am_status_switch_text",  "启用 auto_mount");
            setvar("module_am_status_switch_text2", "");
            setvar("module_am_status_switch_icon",  "@action2");
        endif;
        if cmp(getvar("stat_am_code"), "==", "1") then
            setvar("module_am_status_switch_text",  "禁用 auto_mount");
            setvar("module_am_status_switch_text2", "");
            setvar("module_am_status_switch_icon",  "@offaction");
        endif;
    endif;

    if cmp(getvar("stat_code"), "==", "4") then
        setvar("module_remove_switch_text", "<b><i>撤销</i></b> 重启后移除该模块");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon", "@refresh");
    else
        setvar("module_remove_switch_text", "重启后移除该模块");

        if cmp(getvar("stat_code"), "==", "3") then
            setvar("module_remove_switch_text2", "不允许的操作");
            setvar("module_remove_switch_icon", "@crash");
        else
            setvar("module_remove_switch_text2", "");
            setvar("module_remove_switch_icon", "@delete");
        endif;
    endif;

    if cmp(getvar("stat_code"), "==", "3") then
        setvar("module_remove_warning", "不允许的操作");
        setvar("module_remove_icon",    "@crash");
    else
        setvar("module_remove_warning", "");
        setvar("module_remove_icon",    "@delete");
    endif;

    menubox(
        "模块: " + getvar("modname"),
        "模块 ID: " + getvar("modid") + "\n" +
        "占用空间: " + getvar("modsize") + " MB\n" +
        "模块状态: " + getvar("module_status") + "\n" +
        "auto_mount 状态: " + getvar("module_am_status"),
        "@welcome",
        "modoperations.prop",

        "查看模块描述", "", "@info",
        "预览模块内容", "", "@info",
        getvar("module_status_switch_text"), getvar("module_status_switch_text2"), getvar("module_status_switch_icon"),
        getvar("module_am_status_switch_text"), getvar("module_am_status_switch_text2"), getvar("module_am_status_switch_icon"),
        getvar("module_remove_switch_text"), getvar("module_remove_switch_text2"), getvar("module_remove_switch_icon"),
        "立即移除", getvar("module_remove_warning"), getvar("module_remove_icon")
    );

    if prop("modoperations.prop", "selected") == "1" then
        exec("/sbin/sh", "/tmp/mmr/script/get-module-info.sh", getvar("modid"), "description");
        alert(
            "描述",
            getvar("exec_buffer"),
            "@info",
            "返回"
        );
        back("1");
    endif;
    if prop("modoperations.prop", "selected") == "2" then
        exec("/sbin/sh", "/tmp/mmr/script/get-module-tree.sh", getvar("modid"));
        textbox(
            "预览",
            "模块目录结构:",
            "@info",
            getvar("exec_buffer")
        );
        back("2");
    endif;
    if cmp(getvar("stat_code"), "==", "3") then
        alert(
            "不允许的操作",
            "该模块将在重启后完成更新,\n请重启一次后再试.",
            "@crash",
            "返回"
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
        if confirm("警告",
                   "您确定要移除该模块吗? 此操作不可恢复!",
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
            "成功",
            getvar("exec_buffer"),
            "@done",
            "确定"
        );
    else
        alert(
            "失败",
            getvar("exec_buffer"),
            "@crash",
            "确定"
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
        "高级功能",
        "请选择操作" + getvar("core_only_mode_warning"),
        "@welcome",
        "advanced.prop",

        "保存 recovery 日志",   "复制 /tmp/recovery.log 到内部存储", "@action",
EOF
    if $migrated; then
        echo "\"瘦身 magisk.img\", \"该选项不可用.\", \"@crash\"," >> $ac_tmp
    else
        echo "\"瘦身 magisk.img\", \"压缩 magisk.img 容量以减少其存储空间占用.\n建议在移除大型模块后使用.\", \"@action\"," >> $ac_tmp
    fi
    cat >> $ac_tmp <<EOF
        getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
        "返回",                 "", "@back2"
    );
    if prop("advanced.prop", "selected") == "1" then
        exec("/sbin/sh", "/tmp/mmr/script/save-rec-log.sh");
        alert(
            "完成",
            "已保存 Recovery 日志到 /sdcard/recovery.log!",
            "@done",
            "确定"
        );
        back("1");
    endif;
    if prop("advanced.prop", "selected") == "2" then
EOF
    if $migrated; then
        echo "back(\"1\");" >> $ac_tmp
    else
        cat >> $ac_tmp <<EOF
        pleasewait("正在执行脚本 ...");
        setvar("exitcode", exec("/sbin/sh", "/tmp/mmr/script/shrink-magiskimg.sh"));
        if cmp(getvar("exitcode"), "==", "0") then
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
                "重启设备") == "no"
            then
                reboot("now");
            endif;
        else
            alert(
                "运行失败",
                getvar("exec_buffer"),
                "@crash",
                "退出"
            );
        endif;
        exit("");
EOF
    fi
    cat >> $ac_tmp <<EOF
    endif;
    if prop("advanced.prop", "selected") == "3" then
        if cmp(getvar("core_only_mode_code"), "==", "0") then
            if confirm("警告",
                       "启用 Magisk 核心模式后, 所有模块均不会被载入.\n但 MagiskSU 和 MagiskHide 仍然会继续工作.\n您确定要继续吗?",
                       "@warning") == "no"
            then
                back("1");
            endif;
        endif;
        exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "switch");
        alert(
            "完成",
            getvar("exec_buffer"),
            "@done",
            "确定"
        );
        back("1");
    endif;
endif;

goto("main_menu");
EOF
    sync
}

gen_aroma_config
