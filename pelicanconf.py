#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = 'Sergey Shepelev'
SITENAME = 'Темотин шкафчик. Завтра будет лучше.'
SITEURL = 'http://temoto.ru'

PATH = 'src'
DELETE_OUTPUT_DIRECTORY = True

DEFAULT_DATE_FORMAT = '%Y-%m-%d'
# DATE_FORMATS = {'en': '', 'ru': '%Y-%m-%d'}
TIMEZONE = 'UTC'
DEFAULT_LANG = 'ru'

FEED_ALL_ATOM = 'feeds/all.atom.xml'
CATEGORY_FEED_ATOM = 'feeds/%s.atom.xml'
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

RELATIVE_URLS = True
DEFAULT_PAGINATION = False

# Blogroll
LINKS = (
    ('Pelican', 'http://getpelican.com/'),
    ('Python.org', 'http://python.org/'),
    ('Jinja2', 'http://jinja.pocoo.org/'),
    ('You can modify those links in your config file', '#'),
)

# Social widget
SOCIAL = (
    ('You can add links in your config file', '#'),
    ('Another social link', '#'),
)

#DISQUS_SITENAME = ""
#GOOGLE_ANALYTICS = ""
