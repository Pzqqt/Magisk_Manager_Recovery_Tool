#!/sbin/sh

workPath=/magisk
settings_save_prop=/sdcard/TWRP/mmrt.prop

file_getprop() { grep "^$2=" "$1" | head -n1 | cut -d= -f2; }

ls_mount_path() { ls -1 ${workPath} | grep -v 'lost+found'; }

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
menubox(
    "主菜单",
    "请选择操作" +
    "\n你已安装 $(ls_mount_path | wc -l) 个模块, 总占用空间: $(du -sh ${workPath}/ | awk '{print $1}')" +
    getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "重启", "重启您的设备", "@refresh",
    "退出", getvar("exit_text2"), "@back2",
EOF
    if [ -z "$installed_modules" ]; then
        echo "    \"如果你看到了此选项\", \"说明你尚未安装任何 Magisk 模块...\", \"@what\"," >> $ac_tmp
    else
        for module in $installed_modules; do
            echo "    file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(未提供信息)\"," >> $ac_tmp
            echo "    \"<i><b>\" + (file_getprop(\"${workPath}/${module}/module.prop\", \"version\") || \"(未提供信息)\") +" >> $ac_tmp
            echo '    "\\n作者: " +' "(file_getprop(\"${workPath}/${module}/module.prop\", \"author\") || \"(未提供信息)\") + \"</b></i>\"," >> $ac_tmp
            echo "    prop(\"module_icon.prop\", \"module.icon.${module}\") || \"@removed\"," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
    "高级选项", "", "@action"
);

# Reboot
if prop("operations.prop", "selected") == "1" then
    if confirm(
        "重启",
        "您确定要重启设备吗?",
        "@warning") == "yes"
    then
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        reboot("now");
    endif;
endif;

# Exit
if prop("operations.prop", "selected") == "2" then
    if confirm(
        "退出",
        "您确定要退出 Magisk Manager Recovery Tool 吗?",
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
            echo "    setvar(\"modname\", file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(未提供信息)\");" >> $ac_tmp
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
            "注意",
            "这个模块已经被移除了.\n",
            "@warning",
            "确定"
        );
        back("1");
    endif;

    if getvar("stat_code") == "0" || getvar("stat_code") == "5" then
        setvar("module_status", "<#f00>已禁用</#>");
        setvar("module_status_switch_text",  "启用该模块");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@action2");
    endif;
    if getvar("stat_code") == "1" || getvar("stat_code") == "4" then
        setvar("module_status", "<#0f0>已启用</#>");
        setvar("module_status_switch_text",  "禁用该模块");
        setvar("module_status_switch_text2", "");
        setvar("module_status_switch_icon",  "@offaction");
    endif;
    if cmp(getvar("stat_code"), ">=", "4") then
        setvar("module_status", "<#f00>重启后被移除</#>");
        setvar("module_remove_switch_text",  "<b><i>撤销</i></b> 重启后移除该模块");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon",  "@refresh");
    else
        setvar("module_remove_switch_text",  "重启后移除该模块");
        setvar("module_remove_switch_text2", "");
        setvar("module_remove_switch_icon",  "@delete");
    endif;

    if getvar("stat_mount_code") == "0" then
        setvar("module_mount_status", "已禁用");
        setvar("module_mount_status_switch_text",  "启用挂载");
        setvar("module_mount_status_switch_text2", "");
        setvar("module_mount_status_switch_icon",  "@action2");
    endif;
    if getvar("stat_mount_code") == "1" then
        setvar("module_mount_status", "已启用");
        setvar("module_mount_status_switch_text",  "禁用挂载");
        setvar("module_mount_status_switch_text2", "");
        setvar("module_mount_status_switch_icon",  "@offaction");
    endif;

    if getvar("stat_code") == "3" then
        setvar("module_status", "<#f00>重启后完成更新</#>");
        setvar("module_status_switch_text",        "启用/禁用该模块");
        setvar("module_status_switch_text2",       "不允许的操作");
        setvar("module_status_switch_icon",        "@crash");
        setvar("module_mount_status_switch_text",  "启用/禁用挂载");
        setvar("module_mount_status_switch_text2", "不允许的操作");
        setvar("module_mount_status_switch_icon",  "@crash");
        setvar("module_remove_switch_text2",       "不允许的操作");
        setvar("module_remove_switch_icon",        "@crash");
        setvar("module_remove_text2",              "不允许的操作");
        setvar("module_remove_icon",               "@crash");
    endif;

    menubox(
        "模块: " + getvar("modname"),
        "模块 ID: " + getvar("modid") + "\n" +
        "占用空间: " + getvar("modsize") + "\n" +
        "挂载状态: " + getvar("module_mount_status") + "\n" +
        "模块状态: " + getvar("module_status"),
        "@welcome",
        "modoperations.prop",

        "查看模块描述", "", "@info",
        "预览模块内容", "", "@info",
        getvar("module_status_switch_text"), getvar("module_status_switch_text2"), getvar("module_status_switch_icon"),
        getvar("module_mount_status_switch_text"), getvar("module_mount_status_switch_text2"), getvar("module_mount_status_switch_icon"),
        getvar("module_remove_switch_text"), getvar("module_remove_switch_text2"), getvar("module_remove_switch_icon"),
        getvar("module_remove_text"), getvar("module_remove_text2"), getvar("module_remove_icon")
    );

    if prop("modoperations.prop", "selected") == "1" then
        alert(
            "描述",
            file_getprop("${workPath}/" + getvar("modid") + "/module.prop", "description") || "(未提供信息)",
            "@info",
            "返回"
        );
        back("1");
    endif;
    if prop("modoperations.prop", "selected") == "2" then
        pleasewait("正在获取 ...");
        exec("/sbin/sh", "/tmp/mmr/script/get-module-tree.sh", getvar("modid"));
        ini_set("text_next", "");
        ini_set("icon_next", "@none");
        textbox(
            "预览",
            "模块目录结构:",
            "@info",
            getvar("exec_buffer")
        );
        back("2");
    endif;
    if getvar("stat_code") == "3" then
        alert(
            "不允许的操作",
            "该模块将在重启后完成更新,\n请重启一次后再试.",
            "@crash",
            "返回"
        );
        back("1");
    endif;
    prop("modoperations.prop", "selected") == "3" && setvar("module_operate", "switch_module");
    prop("modoperations.prop", "selected") == "4" && setvar("module_operate", "switch_" + getvar("mount_switch_flag") + "_mount");
    prop("modoperations.prop", "selected") == "5" && setvar("module_operate", "switch_remove");
    if prop("modoperations.prop", "selected") == "6" then
        if confirm(
            "警告",
            "您确定要移除该模块吗? 此操作不可恢复!",
            "@warning") == "yes"
        then
            setvar("module_operate", "remove");
        else
            back("1");
        endif;
    endif;
    if exec("/sbin/sh", "/tmp/mmr/script/control-module.sh", getvar("module_operate"), getvar("modid")) != "0" then
        alert(
            "失败",
            getvar("exec_buffer"),
            "@crash",
            "确定"
        );
    endif;
    prop("modoperations.prop", "selected") != "6" && back("1");
endif;

if prop("operations.prop", "selected") == "$(expr $i + 1)" then
    menubox(
        "高级功能",
        "请选择操作" + getvar("core_only_mode_warning"),
        "@welcome",
        "advanced.prop",

        "保存 recovery 日志", "复制 /tmp/recovery.log 到内部存储", "@action",
        "瘦身 magisk.img", getvar("shrink_text2"), getvar("shrink_icon"),
        getvar("core_only_mode_switch_text"), getvar("core_only_mode_switch_text2"), "@action",
        "超级用户", "", "@action",
        "卸载 Magisk", "Root 权限将从设备中完全移除", "@action",
        "调试选项", "", "@action",
        "返回", "", "@back2"
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
        if cmp(getvar("MAGISK_VER_CODE"), ">", "18100") then
            back("1");
        else
            pleasewait("正在执行脚本 ...");
            if exec("/sbin/sh", "/tmp/mmr/script/shrink-magiskimg.sh") == "0" then
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
        endif;
    endif;
    if prop("advanced.prop", "selected") == "3" then
        exec("/sbin/sh", "/tmp/mmr/script/core-mode.sh", "switch");
        back("1");
    endif;
    if prop("advanced.prop", "selected") == "4" then
        if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "get_sqlite3_path") == "2" then
            alert(
                "不可用的选项",
                "很抱歉,\n由于本工具无法从设备中找到可用的 sqlite3 程序,\n故该选项不可用.",
                "@crash",
                "确定"
            );
        endif;
        menubox(
            "超级用户",
            "请选择操作" + getvar("core_only_mode_warning"),
            "@welcome",
            "magisksu.prop",

            "清除 MagiskSU 日志", "", "@action",
            "授权管理", "", "@action",
            "返回", "", "@back2"
        );
        prop("magisksu.prop", "selected") == "3" && back("2");
        if prop("magisksu.prop", "selected") == "1" then
            pleasewait("正在执行脚本 ...");
            if exec("/sbin/sh", "/tmp/mmr/script/control-sqlite.sh", "clear_su_log") == "0" then
                alert(
                    "成功",
                    "操作完成, 执行过程中没有发生错误.",
                    "@done",
                    "确定"
                );
            else
                alert(
                    "失败",
                    "执行过程中有错误发生, 请确认.\n\n" + getvar("exec_buffer"),
                    "@crash",
                    "确定"
                );
            endif;
            back("1");
        endif;
        if prop("magisksu.prop", "selected") == "2" then
            pleasewait("正在生成列表 ...");
            exec("/sbin/sh", "/tmp/mmr/script/control-suapps.sh");
            ini_set("text_next", "应用更改");
            checkbox(
                "授权管理",
                "勾选即为授予超级用户权限, 反之为拒绝.",
                "@welcome",
                "magisksu_apps.prop",

EOF
    pps=`/tmp/mmr/script/control-sqlite.sh get_saved_package_name_policy | sed 's/|/=/g'`
    if [ -z "$pps" ]; then
        echo "                \"看起来你尚未授权任何应用 ...\",\"\", 2," >> $ac_tmp
    else
        for pp in $pps; do
            echo "                \"${pp%=*}\", \"\", 0," >> $ac_tmp
        done
    fi
    cat >> $ac_tmp <<EOF
                "", "", 3
            );
            pleasewait("正在执行脚本 ...");
            if exec("/sbin/sh", "/tmp/mmr/script/control-suapps.sh", "apply_change") == "0" then
                if getvar("exec_buffer") != "" then
                    alert(
                        "成功",
                        "您的更改已经生效:\n\n" + getvar("exec_buffer"),
                        "@done",
                        "确定"
                    );
                endif;
            else
                alert(
                    "失败",
                    "命令执行失败, 请确认.\n\n" + getvar("exec_buffer"),
                    "@crash",
                    "确定"
                );
            endif;
            back("2");
        endif;
    endif;
    if prop("advanced.prop", "selected") == "5" then
        if confirm(
            "警告",
            "您确定要卸载 Magisk 吗?\n\n所有模块将停用或删除, Root 会被移除.\n未加密的设备重启时可能会被进行加密.",
            "@warning",
            "确定卸载",
            "点错了不好意思") == "no"
        then
            back("1");
        endif;
        exec("/sbin/sh", "/tmp/mmr/script/done-script.sh");
        setvar("uninstall_exitcode",
            install(
                "卸载 Magisk",
                "正在卸载 Magisk, 请稍候...",
                "@welcome",
                "点击下一步以继续..."
            )
        );
        if getvar("uninstall_exitcode") == "0" then
            if confirm(
                "卸载完成",
                "已成功卸载 Magisk.",
                "@warning",
                "退出到 Recovery",
                "重启设备") == "no"
            then
                reboot("onfinish");
            endif;
        else
            alert(
                "卸载失败",
                "很抱歉, 本工具未能成功卸载 Magisk.\n\n请尝试开机后从 Magisk Manager 中卸载.",
                "@crash",
                "退出"
            );
        endif;
        exit("");
    endif;
    if prop("advanced.prop", "selected") == "6" then
        menubox(
            "调试选项",
            "请选择操作",
            "@alert",
            "debug.prop",

            "重建模块图标索引文件", "", "@action",
            "添加快捷启动选项到 Recovery 高级菜单", "", "@action",
            "返回", "", "@back2"
        );
        prop("debug.prop", "selected") == "1" && exec("/sbin/sh", "/tmp/mmr/script/gen-icons-prop.sh", "--regen");
        if prop("debug.prop", "selected") == "2" then
            if confirm(
                "警告",
                "你在使用 RedWolf, OrangeFox, PitchBlack,\n或其他的 TWRP 魔改版吗?",
                "@warning",
                "是的",
                "不, 我在使用 TWRP") == "yes"
            then
                alert(
                    "不允许的操作",
                    "很抱歉, 该选项仅适用于 TWRP 官方版!",
                    "@crash",
                    "返回"
                );
                back("1");
            endif;
            agreebox(
                "说明",
                "请认真阅读以下说明信息:",
                "@warning",
                resread("install_twrp_theme_about.txt"),
                "我已了解",
                "请在认真阅读完说明信息后勾选底部的复选框..."
            );
            writetmpfile("install_twrp_theme_flag", "# FLAG\n");
            setvar("uninstall_exitcode",
                install(
                    "安装 TWRP 主题",
                    "正在安装修改版 TWRP 主题, 请稍候...",
                    "@welcome",
                    "点击下一步以继续..."
                )
            );
            if getvar("uninstall_exitcode") == "0" then
                alert(
                    "完成",
                    "已成功安装修改版 TWRP 主题.\n\n请在下次进入 Recovery 模式后查看效果.",
                    "@done",
                    "返回"
                );
            else
                alert(
                    "失败",
                    "很抱歉, 主题安装失败!\n\n请保存日志并向作者反馈.",
                    "@crash",
                    "返回"
                );
            endif;
        endif;
    endif;
endif;

goto("main_menu");
EOF
    sync
}

gen_aroma_config
