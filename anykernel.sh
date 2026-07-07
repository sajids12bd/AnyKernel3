### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
### AnyKernel setup
# global properties
properties() { '
kernel.string=by ZeroKnowledge
do.devicecheck=1
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
device.name1=topaz
device.name2=tapas
device.name3=sapphiren
device.name4=sapphire
device.name5=xun
device.name6=creek
supported.versions=13-16
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties
### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1
# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

# Generic two-option chooser: VOL+ = option 1, VOL- = option 2
# $1 = label for option 1, $2 = label for option 2
# returns 1 or 2 via $?
choose_two() {
  ui_print " "
  ui_print "  VOL + : $1"
  ui_print "  VOL - : $2"
  ui_print " "
  ui_print "Waiting for input... "
  while true; do
    input=$(getevent -qlc 1 2>/dev/null | grep -E "KEY_VOLUME(UP|DOWN)")
    case "$input" in
      *KEY_VOLUMEUP*)
        return 1
        ;;
      *KEY_VOLUMEDOWN*)
        return 2
        ;;
    esac
    sleep 0.1
  done
}

# --- Detect which variants exist ---
have_gki_ksu=0;    [ -f "$AKHOME/Image.gki.ksu" ]    && have_gki_ksu=1
have_gki_nonksu=0; [ -f "$AKHOME/Image.gki.nonksu" ] && have_gki_nonksu=1
have_clo_ksu=0;    [ -f "$AKHOME/Image.clo.ksu" ]    && have_clo_ksu=1
have_clo_nonksu=0; [ -f "$AKHOME/Image.clo.nonksu" ] && have_clo_nonksu=1

count=$((have_gki_ksu + have_gki_nonksu + have_clo_ksu + have_clo_nonksu))

if [ "$count" -eq 0 ]; then
  # fallback: maybe a plain single-name Image was shipped instead
  if [ -f "$AKHOME/Image" ]; then
    ui_print " "
    ui_print "Single kernel image found, flashing it"
  else
    ui_print " "
    ui_print "ERROR: No kernel image found in zip!"
    abort "No Image/Image.gki.*/Image.clo.* file found in $AKHOME"
  fi

elif [ "$count" -eq 1 ]; then
  ui_print " "
  if [ "$have_gki_ksu" -eq 1 ]; then
    ui_print "Single kernel version found (gki.ksu), flashing it"
    mv -f "$AKHOME/Image.gki.ksu" "$AKHOME/Image"
  elif [ "$have_gki_nonksu" -eq 1 ]; then
    ui_print "Single kernel version found (gki.nonksu), flashing it"
    mv -f "$AKHOME/Image.gki.nonksu" "$AKHOME/Image"
  elif [ "$have_clo_ksu" -eq 1 ]; then
    ui_print "Single kernel version found (clo.ksu), flashing it"
    mv -f "$AKHOME/Image.clo.ksu" "$AKHOME/Image"
  elif [ "$have_clo_nonksu" -eq 1 ]; then
    ui_print "Single kernel version found (clo.nonksu), flashing it"
    mv -f "$AKHOME/Image.clo.nonksu" "$AKHOME/Image"
  fi

else
  # More than one variant present
  have_gki=0
  [ "$have_gki_ksu" -eq 1 -o "$have_gki_nonksu" -eq 1 ] && have_gki=1
  have_clo=0
  [ "$have_clo_ksu" -eq 1 -o "$have_clo_nonksu" -eq 1 ] && have_clo=1

  # --- Step 1: choose base (gki/clo) only if both are present ---
  if [ "$have_gki" -eq 1 -a "$have_clo" -eq 1 ]; then
    ui_print " "
    ui_print "Choose kernel base:"
    choose_two "GKI" "CLO"
    case $? in
      1) base="gki" ;;
      2) base="clo" ;;
    esac
  elif [ "$have_gki" -eq 1 ]; then
    base="gki"
  else
    base="clo"
  fi

  # --- Step 2: choose variant (ksu/nonksu) only if both exist for chosen base ---
  if [ "$base" = "gki" ]; then
    ksu_avail=$have_gki_ksu
    nonksu_avail=$have_gki_nonksu
  else
    ksu_avail=$have_clo_ksu
    nonksu_avail=$have_clo_nonksu
  fi

  if [ "$ksu_avail" -eq 1 -a "$nonksu_avail" -eq 1 ]; then
    ui_print " "
    ui_print "Choose $base variant:"
    choose_two "KSU" "non-KSU"
    case $? in
      1) variant="ksu" ;;
      2) variant="nonksu" ;;
    esac
  elif [ "$ksu_avail" -eq 1 ]; then
    variant="ksu"
  else
    variant="nonksu"
  fi

  chosen="$AKHOME/Image.$base.$variant"
  ui_print " "
  ui_print "Selected: $base.$variant"
  mv -f "$chosen" "$AKHOME/Image"

  # Clean up unselected variants so nothing stale is left in the ramdisk overlay
  for f in "$AKHOME/Image.gki.ksu" "$AKHOME/Image.gki.nonksu" "$AKHOME/Image.clo.ksu" "$AKHOME/Image.clo.nonksu"; do
    [ -f "$f" ] && rm -f "$f"
  done
fi

# boot install
if [ -L "/dev/block/bootdevice/by-name/init_boot_a" -o -L "/dev/block/by-name/init_boot_a" ]; then
    split_boot # for devices with init_boot ramdisk
    flash_boot # for devices with init_boot ramdisk
else
    dump_boot # use split_boot to skip ramdisk unpack, e.g. for devices with init_boot ramdisk
    write_boot # use flash_boot to skip ramdisk repack, e.g. for devices with init_boot ramdisk
fi
## end boot install
