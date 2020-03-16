#!/sbin/sh

ac_2=/tmp/mmr/template/META-INF/com/google/android/aroma/operations.edify

. /tmp/mmr/script/common.sh

ls_modules_sort_by_name() {
    local installed_modules_tmp=`ls_mount_path`
    [ -z "$installed_modules_tmp" ] && return
    for d in $installed_modules_tmp; do echo "$d, "$(file_getprop ${workPath}/${d}/module.prop name); done | \
    sort -k2 -f | while read line; do echo ${line%,*}; done
}

installed_modules=`ls_modules_sort_by_name`

cat >> $ac_2 <<EOF
menubox(
    "主菜单",
    "请选择操作" +
    getvar("exec_buffer") +
    getvar("core_only_mode_warning"),
    "@welcome",
    "operations.prop",

    "重启", "重启您的设备", "@refresh",
    "退出", getvar("exit_text2"), "@back2",
EOF

if [ -z "$installed_modules" ]; then
    echo "    \"如果你看到了此选项\", \"说明你尚未安装任何 Magisk 模块...\", \"@what\"," >> $ac_2
else
    for module in $installed_modules; do
        echo "    file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(未提供信息)\"," >> $ac_2
        echo "    \"<i><b>\" + (file_getprop(\"${workPath}/${module}/module.prop\", \"version\") || \"(未提供信息)\") +" >> $ac_2
        echo "    \"\n作者: \" + (file_getprop(\"${workPath}/${module}/module.prop\", \"author\") || \"(未提供信息)\") + \"</b></i>\"," >> $ac_2
        echo "    prop(\"module_icon.prop\", \"module.icon.${module}\") || \"@removed\"," >> $ac_2
    done
fi

cat >> $ac_2 <<EOF
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
        echo "if prop(\"operations.prop\", \"selected\") == \"$i\" then" >> $ac_2
        echo "    setvar(\"modid\", \"$module\");" >> $ac_2
        echo "    setvar(\"modname\", file_getprop(\"${workPath}/${module}/module.prop\", \"name\") || \"(未提供信息)\");" >> $ac_2
        echo "    setvar(\"modsize\", \"$(du -sh ${workPath}/${module} | awk '{print $1}')\");" >> $ac_2
        echo "endif;" >> $ac_2
        echo "" >> $ac_2
    done
fi

let i+=1
echo "setvar(\"operations_last_index\", \"$i\");" >> $ac_2
