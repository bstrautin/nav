#
# Copyright (C) 2013 UNINETT AS
#
# This file is part of Network Administration Visualized (NAV).
#
# NAV is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 2 as published by
# the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.  You should have received a copy of the GNU General Public
# License along with NAV. If not, see <http://www.gnu.org/licenses/>.
#
"""Provides functions for fetching prefix related data in the API"""

from IPy import IP
from django.db import connection


class UsageResult(object):
    """Container for creating usage results for serializing"""
    def __init__(self, prefix, active_addresses, starttime=None, endtime=None):
        self.prefix = IP(prefix)
        self.active_addresses = active_addresses
        self.max_addresses = len(self.prefix)
        self.usage = self.active_addresses / float(self.max_addresses) * 100
        self.starttime = starttime
        self.endtime = endtime if self.starttime else None


def fetch_usage(prefix, starttime, endtime):
    """Fetches usage for the prefix

    :param prefix: the prefix to fetch active addresses from
    :type prefix: str
    :type starttime: datetime.datetime
    :type endtime: datetime.datetime
    """
    result = collect_active_ip(prefix, starttime, endtime)
    return UsageResult(prefix, result, starttime, endtime)


def collect_active_ip(prefix, starttime=None, endtime=None):
    """Collects active ip based on prefix and optional starttime and endtime

    :param prefix: prefix to find active ip addresses for
    :type prefix: str

    :param starttime: if set will query for active ip-addresses at that time.
                      if set with endtime indicates the start of the window
                      for finding active ip addresses
    :type starttime: datetime.datetime

    :param endtime: if set indicates the end of the window for finding
                    active ip addresses
    :type endtime: datetime.datetime

    :returns: int -- an integer representing the active addresses
    """

    cursor = connection.cursor()

    if starttime and endtime:
        query = """
        SELECT COUNT(DISTINCT ip) AS ipcount
        FROM arp
        WHERE (ip << %s AND (start_time, end_time) OVERLAPS (%s, %s))
        """
        cursor.execute(query, (prefix, starttime, endtime))
    elif starttime:
        query = """
        SELECT COUNT(DISTINCT ip) AS ipcount
        FROM arp
        WHERE (ip << %s AND %s BETWEEN start_time AND end_time)
        """
        cursor.execute(query, (prefix, starttime))
    else:
        query = """
        SELECT COUNT(DISTINCT ip) AS ipcount
        FROM arp
        WHERE (ip << %s AND end_time = 'infinity')
        """
        cursor.execute(query, (prefix,))

    result = cursor.fetchone()
    return int(result[0])
