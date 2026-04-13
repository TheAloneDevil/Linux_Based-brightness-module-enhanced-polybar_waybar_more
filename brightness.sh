#!/usr/bin/env bash

DDC_BUS=11
DDC_DEV="--bus=$DDC_BUS"
THINSPACE=$'\xE2\x80\x86'

get_brightness_ddc() {
    ddcutil $DDC_DEV getvcp 10 2>/dev/null | sed -n 's/.*current value = *\([0-9]*\).*/\1/p'
}

get_brightness_sysfs() {
    local current=$(cat /sys/class/backlight/intel_backlight/brightness 2>/dev/null || echo 0)
    local max=$(cat /sys/class/backlight/intel_backlight/max_brightness 2>/dev/null || echo 1)
    [ "$max" -eq 0 ] && max=1
    echo $((current * 100 / max))
}

get_icon() {
    local pct=$1
    if [ "$pct" -le 5 ] 2>/dev/null; then
        echo "%{T9}󰪞%{T-}"
    elif [ "$pct" -le 20 ] 2>/dev/null; then
        echo "%{T9}󰪟%{T-}"
    elif [ "$pct" -le 35 ] 2>/dev/null; then
        echo "%{T9}󰪠%{T-}"
    elif [ "$pct" -le 50 ] 2>/dev/null; then
        echo "%{T9}󰪡%{T-}"
    elif [ "$pct" -le 65 ] 2>/dev/null; then
        echo "%{T9}󰪢%{T-}"
    elif [ "$pct" -le 80 ] 2>/dev/null; then
        echo "%{T9}󰪣%{T-}"
    elif [ "$pct" -le 95 ] 2>/dev/null; then
        echo "%{T9}󰪤%{T-}"
    else
        echo "%{T9}󰪥%{T-}"
    fi
}

get_bar() {
    local pct=$1
    local filled=$((pct / 10))
    local empty=$((10 - filled))
    printf '%*s' "$filled" | sed 's/ /▓/g' | sed 's/.*/%{T16}&%{T-}/'
    printf '%*s' "$empty" | sed 's/ /░/g' | sed 's/.*/%{T16}&%{T-}/'
}

case "$1" in
    get)
        ddc_val=$(get_brightness_ddc)
        
        if [ -n "$ddc_val" ] && [ "$ddc_val" -gt 0 ] 2>/dev/null; then
            icon=$(get_icon "$ddc_val")
            bar=$(get_bar "$ddc_val")
            echo "%{F#a8ff00}$icon%{F-} ${ddc_val}%$THINSPACE%{F#555555}$bar%{F-}"
        else
            sysfs_val=$(get_brightness_sysfs)
            [ -z "$sysfs_val" ] && sysfs_val=0
            icon=$(get_icon "$sysfs_val")
            bar=$(get_bar "$sysfs_val")
            echo "%{F#00aaff}$icon%{F-} ${sysfs_val}%$THINSPACE%{F#555555}$bar%{F-}"
        fi
        ;;
    inc)
        ddc_val=$(get_brightness_ddc)
        if [ -n "$ddc_val" ] && [ "$ddc_val" -gt 0 ] 2>/dev/null; then
            newpct=$((ddc_val + 5))
            [ $newpct -gt 100 ] && newpct=100
            ddcutil $DDC_DEV setvcp 10 $newpct 2>/dev/null
        else
            current=$(brightnessctl -d intel_backlight get 2>/dev/null || echo 0)
            max=$(brightnessctl -d intel_backlight max 2>/dev/null || echo 100)
            [ "$max" -eq 0 ] && max=1
            newval=$((current + max * 5 / 100))
            [ $newval -gt $max ] && newval=$max
            brightnessctl -d intel_backlight set $newval 2>/dev/null
        fi
        ;;
    dec)
        ddc_val=$(get_brightness_ddc)
        if [ -n "$ddc_val" ] && [ "$ddc_val" -gt 0 ] 2>/dev/null; then
            newpct=$((ddc_val - 5))
            [ $newpct -lt 5 ] && newpct=5
            ddcutil $DDC_DEV setvcp 10 $newpct 2>/dev/null
        else
            current=$(brightnessctl -d intel_backlight get 2>/dev/null || echo 0)
            max=$(brightnessctl -d intel_backlight max 2>/dev/null || echo 100)
            [ "$max" -eq 0 ] && max=1
            newval=$((current - max * 5 / 100))
            [ $newval -lt 1 ] && newval=1
            brightnessctl -d intel_backlight set $newval 2>/dev/null
        fi
        ;;
    icon)
        ddc_val=$(get_brightness_ddc)
        if [ -n "$ddc_val" ] && [ "$ddc_val" -gt 0 ] 2>/dev/null; then
            icon=$(get_icon "$ddc_val")
            echo "%{F#a8ff00}$icon%{F-}"
        else
            sysfs_val=$(get_brightness_sysfs)
            [ -z "$sysfs_val" ] && sysfs_val=0
            icon=$(get_icon "$sysfs_val")
            echo "%{F#00aaff}$icon%{F-}"
        fi
        ;;
esac
