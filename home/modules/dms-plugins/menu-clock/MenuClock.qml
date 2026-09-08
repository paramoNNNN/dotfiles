import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null

    function toPersianDigits(value) {
        const digits = "۰۱۲۳۴۵۶۷۸۹";
        return String(value).replace(/[0-9]/g, digit => digits[Number(digit)]);
    }

    function jalaliParts(date) {
        let gy = date.getFullYear();
        const gm = date.getMonth() + 1;
        const gd = date.getDate();
        const gregorianMonthDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        let jy = gy <= 1600 ? 0 : 979;
        gy -= gy <= 1600 ? 621 : 1600;
        const gy2 = gm > 2 ? gy + 1 : gy;
        let days = 365 * gy
            + Math.floor((gy2 + 3) / 4)
            - Math.floor((gy2 + 99) / 100)
            + Math.floor((gy2 + 399) / 400)
            - 80 + gd + gregorianMonthDays[gm - 1];

        jy += 33 * Math.floor(days / 12053);
        days %= 12053;
        jy += 4 * Math.floor(days / 1461);
        days %= 1461;
        if (days > 365) {
            jy += Math.floor((days - 1) / 365);
            days = (days - 1) % 365;
        }

        const jm = days < 186 ? 1 + Math.floor(days / 31) : 7 + Math.floor((days - 186) / 30);
        const jd = 1 + (days < 186 ? days % 31 : (days - 186) % 30);
        return [jy, jm, jd];
    }

    function jalaliDateText(date) {
        const months = ["فروردین", "اردیبهشت", "خرداد", "تیر", "مرداد", "شهریور", "مهر", "آبان", "آذر", "دی", "بهمن", "اسفند"];
        const weekdays = ["یکشنبه", "دوشنبه", "سه‌شنبه", "چهارشنبه", "پنجشنبه", "جمعه", "شنبه"];
        const parts = jalaliParts(date);
        return weekdays[date.getDay()] + "، " + toPersianDigits(parts[2]) + " " + months[parts[1] - 1] + " " + toPersianDigits(parts[0]);
    }

    function showJalaliTooltip(sourceItem) {
        if (!jalaliTooltip.item || !parentScreen)
            return;
        const position = sourceItem.mapToItem(null, sourceItem.width / 2, 0);
        const isBottom = axis?.edge === "bottom";
        const tooltipHeight = Theme.fontSizeSmall * 1.5 + Theme.spacingS * 2;
        const tooltipY = isBottom
            ? parentScreen.height - barThickness - barSpacing - Theme.spacingXS - tooltipHeight
            : barThickness + barSpacing + Theme.spacingXS;
        jalaliTooltip.item.show(jalaliDateText(systemClock.date), position.x, tooltipY, parentScreen, false, false);
    }

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    Loader {
        id: jalaliTooltip
        active: true
        sourceComponent: DankTooltip {}
    }

    pillClickAction: (x, y, width, section, screen) => {
        if (!popoutService)
            return;
        // Unlike built-in widgets, plugins must activate lazy popout loaders.
        popoutService.notificationCenterLoader.active = true;
        Qt.callLater(() => {
            popoutService.toggleNotificationCenter(x, y, width, section, screen);
        });
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: clockText.implicitWidth
            implicitHeight: clockText.implicitHeight

            StyledText {
                id: clockText
                text: Qt.formatDateTime(systemClock.date, "ddd MMM d HH:mm")
                color: Theme.widgetTextColor
                font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
                verticalAlignment: Text.AlignVCenter
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        root.showJalaliTooltip(parent);
                    else if (jalaliTooltip.item)
                        jalaliTooltip.item.hide();
                }
            }
        }
    }
}
