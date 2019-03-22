#!/sbin/sh

dst_prop_file=/tmp/aroma/module_icon.prop

: > $dst_prop_file

for module in `cat /tmp/mmr/script/modules_ids`; do
  module_status=`/tmp/mmr/script/control-module.sh status $module; echo $?`
  # Enable: 1, Disable: 0, Removed: 2, UpdateFlag: 3, RemoveFlag: 4
  case $module_status in
    1) useicon="@default"
    ;;
    0) useicon="@disable"
    ;;
    2) useicon="@removed"
    ;;
    3) useicon="@updateflag"
    ;;
    4) useicon="@removeflag"
    ;;
    *) useicon="@default"
    ;;
  esac
  echo "module.icon.${module}=${useicon}" >> $dst_prop_file
done
