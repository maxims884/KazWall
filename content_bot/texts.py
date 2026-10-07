"""Какие открытки делать сегодня. Сами поздравления и даты праздников — в countries/<страна>.py"""
import datetime

import country


def upcoming_holiday(today: datetime.date, days: int = 10):
    """Ближайший праздник в пределах days дней, иначе None"""
    for shift in range(days + 1):
        day = today + datetime.timedelta(days=shift)
        full, short = day.isoformat(), day.isoformat()[5:]
        for holiday, dates in country.data.HOLIDAYS.items():
            if full in dates or short in dates:
                return holiday
    return None


def occasions_for(today: datetime.date):
    """Какие открытки делать сегодня: 1 обычно, 2 перед праздником и в четверг (к пятнице)"""
    holiday = upcoming_holiday(today)
    everyday = country.data.EVERYDAY[today.toordinal() % len(country.data.EVERYDAY)]
    if holiday:
        return [holiday, everyday]
    if today.weekday() == 3:
        return ["friday", everyday if everyday != "friday" else "morning"]
    return [everyday]
