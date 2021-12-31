#!/sbin/sh

ac_4=/tmp/mmr/template/META-INF/com/google/android/aroma/module_backup_list.edify

path_split() { echo ${1%.*}; }

. /tmp/mmr/script/common.sh

backedup_modules=`ls_module_backup_path | sort`

cat >> $ac_4 <<EOF
        menubox(
            "Restore backed up modules",
            "Modules backup directory:\n${module_backup_path}",
            "@welcome",
            "module_backup_list.prop",

            "Back", "", "@back2",
EOF

if [ -z "$backedup_modules" ]; then
    echo "            \"If you see this option\", \"You have not backed up any Magisk modules...\", \"@what\"," >> $ac_4
else
    for backedup_file in $backedup_modules; do
        module_id=`path_split $(path_split "$backedup_file")`
        echo "            \"${module_id}\", \"\", \"@default\"," >> $ac_4
    done
fi

cat >> $ac_4 <<EOF
        "", "", ""
        );
        setvar("bm_id", "");
        prop("module_backup_list.prop", "selected") == "1" && back("2");
EOF

if [ -n "$backedup_modules" ]; then
    j=1
    for backedup_file in $backedup_modules; do
        let j+=1
        module_id=`path_split $(path_split "$backedup_file")`
        echo "        if prop(\"module_backup_list.prop\", \"selected\") == \"$j\" then" >> $ac_4
        echo "            setvar(\"bm_id\", \"${module_id}\");" >> $ac_4
        echo "            setvar(\"bm_size\", \"$(du -h ${module_backup_path}/${backedup_file} | awk '{print $1}')\");" >> $ac_4
        echo "        endif;" >> $ac_4
        echo "" >> $ac_4
    done
fi
