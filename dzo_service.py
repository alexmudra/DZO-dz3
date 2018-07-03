# !/usr/bin/python
# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from iso8601 import parse_date
from pytz import timezone
import os
import urllib
import re

DZO_dict = {u'килограммы': u'кг', u'кілограм': u'кг', u'кілограми': u'кг', u'метри': u'м', u'пара': u'пар',
            u'літр': u'л', u'набір': u'наб', u'пачок': u'пач', u'послуга': u'послуги', u'метри кубічні': u'м.куб',
            u'тони': u'т', u'метри квадратні': u'м.кв', u'кілометри': u'км', u'штуки': u'шт', u'місяць': u'міс',
            u'пачка': u'пачка', u'упаковка': u'уп', u'гектар': u'Га', u'лот': u'лот', u"грн": u"UAH",
            u"з ПДВ": u"True", u"без ПДВ": u"false", u"Код CPV": u"CPV", u"Переможець": u"active",
            u"місто Київ": u"м. Київ",
            u"ПОДАННЯ ПРОПОЗИЦІЙ": u"active.tendering",
            u"АУКЦІОН": u"active.auction",
            u"ТОРГИ НЕ ВІДБУЛИСЯ": u"unsuccessful",
            u"ТОРГИ ВІДМІНЕНО": u"cancelled",
            u"ТОРГИ ЗАВЕРШЕНО": u"complete",
            u'В черзі': u'pending.waiting',
            u'ВИКЛЮЧЕНО З ПЕРЕЛІКУ': u'deleted',
            u'ОБ’ЄКТ ВИКЛЮЧЕНО': u'deleted',
            u'ОПУБЛІКОВАНО. ОЧІКУВАННЯ ІНФОРМАЦІЙНОГО ПОВІДОМЛЕННЯ': u'pending',
            u'ОПУБЛІКОВАНО': u'pending',
            u'PENDING DELETED': u'pending.deleted',
            u'Об’єкт реєструється': u'registering',
            u'об\'єкт зареєстровано': u'complete',
            u'Об’єкт зареєстровано': u'complete',
            u'ТИП АУКЦІОНУ : АУКЦІОН': u'sellout.english',
            u'?:tender method open_sellout.english_2': u'sellout.english',
            u'ТИП АУКЦІОНУ: АУКЦІОН ІЗ ЗНИЖЕННЯМ СТАРТОВОЇ ЦІНИ': u'sellout.english',
            u'ТИП АУКЦІОНУ: АУКЦІОН ЗА МЕТОДОМ ПОКРОКОВОГО ЗНИЖЕННЯ СТАРТОВОЇ ЦІНИ ТА ПОДАЛЬШОГО ПОДАННЯ ЦІНОВИХ ПРОПОЗИЦІЙ': u'sellout.insider',
            u'СТАТУС АУКЦІОНУ: ЗАПЛАНОВАНО.': u'scheduled',
            u'СТАТУС АУКЦІОНУ: В ПРОЦЕСІ.': u'active',
            u'Інформація про оприлюднення інформаційного повідомлення': u'informationDetails'}


def convert_date_for_decision(date):
    date = datetime.strptime(date, '%Y-%m-%d').strftime('%d/%m/%Y')
    return '{}'.format(date)


def adapt_data_for_role(role_name, tender_data):
    if role_name == 'tender_owner' and 'assetCustodian' in tender_data['data']:
        tender_data = adapt_unit_names_asset(adapt_assetCustodian(tender_data))
    return tender_data


def convert_string_from_dict_dzo(string):
    return DZO_dict.get(string, string)

