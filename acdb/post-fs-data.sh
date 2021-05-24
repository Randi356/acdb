#!/system/bin/sh


# Audio Configuration Database
# gh


# Configuration Conflict Resolution script


acdb=/data/adb/modules/acdb
module=$(find /data/adb/modules -mindepth 1 -maxdepth 1 -type d -not -path $acdb -print)
modulefx=$(find $module -type f -name "*audio_effects*" ! -name "audio_effects_tune*")
acdbconfig=$(find $module -type f -name "acdb.conf")
acdbconfigs=$(find $module -type f -name "acdb[0-9].conf")
acdbetc=$acdb/system/etc
acdbsvetc=$acdb/system/vendor/etc
modetc=$module/system/etc
modsvetc=$module/system/vendor/etc
mirror=/sbin/.magisk/mirror
sys=$(realpath $mirror/system)
ven=$(realpath $mirror/vendor)
etc=$sys/etc
vetc=$ven/etc
conf=*audio_effects*.conf
xml=*audio_effects*.xml


if [ -e "$modulefx" ]; then
  rm -f $modulefx
fi

for fxconfig in $etc/$conf; do
  if [ -e "$fxconfig" ]; then
    cp -f $fxconfig $acdbetc/
    rm -f $acdbetc/placeholder 2>/dev/null
  fi
done

for fxconfig in $vetc/$conf $vetc/$xml; do
  if [ -e "$fxconfig" ]; then
    cp -f $fxconfig $acdbsvetc/
    rm -f $acdbsvetc/audio_effects_tune.xml 2>/dev/null
    rm -f $acdbsvetc/placeholder 2>/dev/null
  fi
done

for disable in /data/adb/modules/*/disable; do
  if [ -e "$disable" ]; then
    disabled=$(dirname $disable)
    for config in $disabled/acdb*.conf; do
      if [ -e "$config" ]; then
        mv -f $config $config.off
      fi
    done
  fi
done

for config in $module/acdb*.conf; do
  if [ -e "$config.off" ]; then
    disabled=$(dirname $config.off)
    for module in $disabled; do
      if [ ! -e "$module/disable" ]; then
        mv -f $config.off $config
      fi
    done
  fi
done


conf=$(find $acdb -type f -name "*audio_effects*.conf")
xml=$(find $acdb -type f -name "*audio_effects*.xml")


for config in $acdbconfig $acdbconfigs; do
  if [ -e "$config" ]; then 
    libraryid=$(cat $config | sed -n -e 's/^libraryid=//p')
    libraryname=$(cat $config | sed -n -e 's/^libraryname=//p')
    effectid=$(cat $config | sed -n -e 's/^effectid=//p')
    effectuuid=$(cat $config | sed -n -e 's/^effectuuid=//p')
    musicstream=$(grep "musicstream=true" $config)
    notification
    for libid in $libraryid; do
      library_id=${libid}
      for libname in $libraryname; do
        library_name=${libname}
        for fxid in $effectid; do
          effect_id=${fxid}
          for fxuuid in $effectuuid; do
            effect_uuid=${fxuuid}
            for fxconfig in $xml; do
              if [ -e "$fxconfig" ]; then
                sed -i "1,/^    <\/libraries>/s/^    <\/libraries>/        <library name=\"$library_id\" path=\"$library_name\"\/>\n    <\/libraries>/" $fxconfig
                sed -i "1,/^    <\/effects>/s/^    <\/effects>/        <effect name=\"$effect_id\" library=\"$library_id\" uuid=\"$effect_uuid\"\/>\n    <\/effects>/" $fxconfig
                if [ "$musicstream" ]; then
                  sed -i "s/^        <stream type=\"music\">/        <stream type=\"music\">\n            <apply effect=\"$effect_id\"\/>/g" $fxconfig
                fi
                sed -i "1,/^            <apply effect=\"alarm\_helper\"\/>/s/^            <apply effect=\"alarm\_helper\"\/>/            <!-- apply effect=\"alarm\_helper\"\/ -->/" $fxconfig
                sed -i "1,/^            <apply effect=\"music\_helper\"\/>/s/^            <apply effect=\"music\_helper\"\/>/            <!-- apply effect=\"music\_helper\"\/ -->/" $fxconfig
                sed -i "1,/^            <apply effect=\"notification\_helper\"\/>/s/^            <apply effect=\"notification\_helper\"\/>/            <!-- apply effect=\"notification\_helper\"\/ -->/" $fxconfig
                sed -i "1,/^            <apply effect=\"ring\_helper\"\/>/s/^            <apply effect=\"ring\_helper\"\/>/            <!-- apply effect=\"ring\_helper\"\/ -->/" $fxconfig
              fi
            done
            for fxconfig in $conf; do
              if [ -e "$fxconfig" ]; then
                sed -i "s/^libraries {/libraries {\n  $library_id {\n    path \/vendor\/lib\/soundfx\/$library_name\n  }/" $fxconfig
                sed -i "s/^effects {/effects {\n  $effect_id {\n    library $library_id\n    uuid $effect_uuid\n  }/" $fxconfig
                if [ "$musicstream" ]; then
                  sed -i "s/^    music {/    music {\n        $effect_id {\n        }/g" $fxconfig
                fi
                sed -i "/^        alarm_helper {/ {;N s/        alarm_helper {\n        }/#        alarm_helper {\n#        }/}" $fxconfig
                sed -i "/^        music_helper {/ {;N s/        music_helper {\n        }/#        music_helper {\n#        }/}" $fxconfig
                sed -i "/^        notification_helper {/ {;N s/        notification_helper {\n        }/#        notification_helper {\n#        }/}" $fxconfig
                sed -i "/^        ring_helper {/ {;N s/        ring_helper {\n        }/#        ring_helper {\n#        }/}" $fxconfig
              fi
            done
          done
        done
      done
    done
  fi
done
