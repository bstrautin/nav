/*
 * Copyright (C) 2009 UNINETT AS
 *
 * This file is part of Network Administration Visualized (NAV).
 *
 * NAV is free software: you can redistribute it and/or modify it under the
 * terms of the GNU General Public License version 2 as published by the Free
 * Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.  You should have received a copy of the GNU General Public
 * License along with NAV. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Calendar component.
 *
 * Creates a calendar showing one month, with buttons for navigating
 * one month/year forward and back, and with selectable days.
 *
 * The calendar allows for selection of intervals, as represented by
 * TimeInterval.  This is, however, somewhat limited: The calendar has
 * no finer resolution than days (so for intervals smaller than one
 * day, it is only possible to select which day the interval should
 * lie in), and it provides no UI mechanism for changing the interval
 * size.  It is assumed that when interval selection is desired (which
 * is the case in Geomap), other mechanisms handle these issues (which
 * is the case in Geomap).
 *
 * Uses a HTML table for the days and a set of arbitrary HTML elements
 * for the navigation buttons.  All these elements must already exist
 * in the HTML document, but the table of days should be empty (all
 * its content is generated by the Calendar).
 *
 * Arguments:
 *
 * idPrefix -- prefix of id of HTML elements used by the calendar.
 *
 * changeCallback -- function to be called (with the selected time as
 * argument) when the selection is changed.
 *
 * interval -- initially selected time interval.
 *
 * dateSelectable -- predicate which takes a date (Time object) as
 * argument and determines whether that day should be selectable in
 * the calendar.
 *
 * monthSelectable -- predicate which takes a month (Time object) as
 * argument and determines whether it should be possible to navigate
 * to that month.
 *
 * {date,month}Selectable, if omitted, default to letting everything
 * be selectable.
 */
function Calendar(idPrefix, changeCallback, interval,
		  dateSelectable, monthSelectable) {
    this.idPrefix = idPrefix;
    this.changeCallback = changeCallback;
    this.interval = interval;
    this.dateSelectable = dateSelectable || function() { return true; };
    this.monthSelectable = monthSelectable || function() { return true; };

    this.writeInitialHTML();
    this.updateHTML();
}

Calendar.prototype = {
    idPrefix: null,
    changeCallback: null,
    interval: null,
    dateSelectable: null,
    monthSelectable: null,

    /*
     * Size of the calendar (the last row is not always used).
     */
    num_rows: 6,
    num_cols: 7,

    /*
     * The selection is stored as TimeInterval in this.interval, but
     * also available (both for reading and writing) as a Time object
     * through this.time.
     *
     * By the getter and setter defined here, the time property
     * magically reflects the value in the interval property.
     */
    get time() { return this.interval.time; },
    set time(t) {
	this.interval = new TimeInterval(this.interval.size, t);
    },

    /*
     * Change the calendar selection.
     *
     * The argument is a new selection, either a Time or TimeInterval
     * object.
     */
    select: function(timeOrInterval) {
	if (timeOrInterval instanceof Time)
	    this.time = timeOrInterval;
	else
	    this.interval = timeOrInterval;
	this.updateHTML();
	this.changeCallback(this.time);
    },

    /*
     * Create the HTML rows and cells for the calendar.
     */
    writeInitialHTML: function() {
	var makeCell = encapsulate(this, function(i, j) {
	    return format('<td id="%s-cell-%d,%d"></td>', this.idPrefix, i, j);
	});
	var makeRow = encapsulate(this, function(i) {
	    return format('<tr id="%s-row-%d">%s</tr>',
			  this.idPrefix, i,
			  concat(map(fix(makeCell, i), range(this.num_cols))));
	});
	var monthElem = this.getElem('month');
	monthElem.innerHTML = concat(map(makeRow, range(this.num_rows)));
    },
    
    /*
     * Update the user interface.
     */
    updateHTML: function() {
	var cal = this; // useful for inner function which are not
			// called on this object
	var now = new Time();
	var tab = this.makeMonthTable();
	var selectUnit = this.interval.getSize().unit;

	/*
	 * Create a function which selects the given time in the
	 * calendar.
	 */ 
	function makeSelectFunc(time) {
	    return function() { cal.select(time); };
	}

	function updateMovementButton(id, timeOffset) {
	    var elem = cal.getElem(id);
	    var time = cal.time.add(timeOffset);
	    var selectable = cal.monthSelectable(time);
	    
	    elem.onclick = selectable ? makeSelectFunc(time) : function(){};
	    elem.className = selectable ? 'selectable' : '';
	}

	/*
	 * Is t (a Time object) today?
	 */
	function todayp(t) {
	    return t.year==now.year && t.month==now.month && t.day==now.day;
	}

	function updateCell(row, col, rowSelected) {
	    var day = tab[row][col];
	    var elem = cal.getElem(format('cell-%d,%d', row, col));
	    var time = cal.time.relative(
		{day: day || (row == 0 ? 1 : cal.time.daysInMonth)});
	    var selected = (day == cal.time.day);
	    var selectable =
		cal.dateSelectable(time) &&
		!selected && !rowSelected &&
		selectUnit != 'month' &&
		day != null;
	    var classes =
		(todayp(time) ? 'today ' : '') +
		(selected ? 'selected' :
		 (selectable ? 'selectable' : ''));

	    elem.innerHTML = day ? format('%d', day) : '';
	    elem.onclick = selectable ? makeSelectFunc(time) : function(){};
	    elem.className = classes;
	}

	function updateRow(row) {
	    var elem = cal.getElem('row-'+row);
	    var firstDay = firstWith(identity, tab[row], null)
	    var time =
		(firstDay != null ?
		 cal.time.relative({day: firstDay}).weekCenter() :
		 null);
	    var selected =
		(selectUnit == 'month' ||
		 (selectUnit == 'week' &&
		  time != null && cal.interval.contains(time)));
	    var selectable =
		time != null && cal.dateSelectable(time) &&
		(selectUnit == 'week') && !selected;

	    elem.className = (selected ? 'selected' :
			      (selectable ? 'selectable' : ''));
	    for (var i = 0; i < cal.num_cols; i++)
		updateCell(row, i, selected);
	}

	this.getElem().className = 'enabled';

	map(updateMovementButton,
	    ['prev-year', 'next-year', 'prev-month', 'next-month'],
	    [{year: -1},  {year: +1},  {month: -1},  {month: +1}]);

	this.getElem('header').innerHTML = this.time.format('%b %Y');

	range(this.num_rows).forEach(updateRow);
    },

    /*
     * Get an element by id (without prefix).
     */
    getElem: function(id) {
	id = id ? (this.idPrefix+'-'+id) : this.idPrefix;
	return document.getElementById(id);
    },

    /*
     * Create a table of the days in the selected month.
     *
     * The table is represented as an array of arrays, one for each
     * week.  The week arrays contain day numbers, with null on the
     * positions which are outside the month.
     */
    makeMonthTable: function() {
	var lastDay = this.time.daysInMonth;
	var firstWeekday = this.time.relative({day: 1}).weekDay;

	var cal = [];
	var row, col, day;
	for (row = 0, day = -firstWeekday+1; row < this.num_rows; row++) {
	    cal[row] = [];
	    for (col = 0; col < this.num_cols; col++, day++) {
		if (day < 1 || day > lastDay) {
		    cal[row][col] = null;
		} else {
		    cal[row][col] = day;
		}
	    }
	}
	return cal;
    },

    toString: function() {
	return format('<Calendar "%s", %s>',
		      this.idPrefix,
		      this.time.format('%Y-%m-%d'));
    }

};

