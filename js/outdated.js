/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
 */

/**
 * Time constants in milliseconds
 */
const TIME_UNITS = {
  SECOND: 1000,
  MINUTE: 60 * 1000,
  HOUR: 60 * 60 * 1000,
  DAY: 24 * 60 * 60 * 1000
};
const OUTDATED_THRESHOLD_HOURS = 24;

/**
 * Calculates the difference in months between two dates
 * @param {Date} startDate - The earlier date
 * @param {Date} endDate - The later date
 * @returns {number} Number of months difference
 */
function getMonthsDifference(startDate, endDate) {
  const yearsDiff = endDate.getFullYear() - startDate.getFullYear();
  const monthsDiff = endDate.getMonth() - startDate.getMonth();
  const dateDiff = endDate.getDate() - startDate.getDate();
  const lastDay = new Date(endDate.getFullYear(), endDate.getMonth() + 1, 0).getDate();
  let totalMonths = yearsDiff * 12 + monthsDiff;
  totalMonths -= dateDiff >= 0 || endDate.getDate() === lastDay ? 0 : 1;
  return Math.max(0, totalMonths);
}

/**
 * Formats a time difference as a human-readable relative time string
 * @param {number} diffInMs - Time difference in milliseconds
 * @param {Date} startDate - The start date for accurate month/year calculation
 * @returns {string} Formatted relative time string
 */
function formatRelativeTime(diffInMs, startDate) {
  const future = diffInMs < 0;
  const endDate = new Date(startDate.getTime() + diffInMs);
  const span = Math.abs(diffInMs);
  const totalMonths = future ? getMonthsDifference(endDate, startDate) : getMonthsDifference(startDate, endDate);
  const years = Math.floor(totalMonths / 12);
  const months = totalMonths % 12;
  const days = Math.floor(span / TIME_UNITS.DAY);
  const hours = Math.floor(span / TIME_UNITS.HOUR);
  const minutes = Math.floor(span / TIME_UNITS.MINUTE);
  const label = (count, unit) => {
    const amount = count === 1 ? `one ${unit}` : `${count} ${unit}s`;
    return future ? `in ${amount}` : `${amount} ago`;
  };
  const timeUnits = [
    { value: years, unit: 'year' },
    { value: months, unit: 'month' },
    { value: days, unit: 'day' },
    { value: hours, unit: 'hour' },
    { value: minutes, unit: 'minute' }
  ];
  const matchedUnit = timeUnits.find((unit) => unit.value > 0);
  return matchedUnit ? label(matchedUnit.value, matchedUnit.unit) : 'just now';
}

/**
 * Displays a warning message if the page is outdated
 */
function displayOutdatedWarning() {
  const time = Date.parse($("#generated-time").attr("datetime"));
  if (isNaN(time)) {
    console.error("Could not parse the generated time");
    return;
  }
  const age = Date.now() - time;
  const hours = Math.floor(age / TIME_UNITS.HOUR);
  const warning = $("#page-outdated-warning");
  if (age > OUTDATED_THRESHOLD_HOURS * TIME_UNITS.HOUR) {
    const message = `This page was generated ${hours} ${hours === 1 ? 'hour' : 'hours'} ago. The information is most probably outdated.`;
    if (warning.length === 0) {
      $('footer').prepend(`<p id="page-outdated-warning" class='red'>${message}</p>`);
    } else {
      warning.text(message);
    }
  } else if (warning.length > 0) {
    warning.remove();
  }
}

/**
 * Updates the time element with relative time display
 */
function updateTimeDisplay() {
  $("time.relative-time[datetime]").each(function (index, element) {
    const $element = $(element);
    const publishedDate = Date.parse($element.attr('datetime'));
    if (isNaN(publishedDate)) {
      console.error("Could not parse date and time");
      return;
    }
    const currentDate = new Date();
    const timeDiff = currentDate - publishedDate;
    const startDate = new Date(publishedDate);
    const relativeTime = formatRelativeTime(timeDiff, startDate);
    $element.text(relativeTime);
  });
}

$(function() {
  updateTimeDisplay();
  displayOutdatedWarning();
  setInterval(function() {
    updateTimeDisplay();
    displayOutdatedWarning();
  }, TIME_UNITS.MINUTE);
});
