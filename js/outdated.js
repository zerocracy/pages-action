/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
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
  let totalMonths = yearsDiff * 12 + monthsDiff;
  totalMonths -= dateDiff >= 0 ? 0 : 1;
  return Math.max(0, totalMonths);
}

/**
 * Formats a time difference as a human-readable relative time string
 * @param {number} diffInMs - Time difference in milliseconds
 * @param {Date} startDate - The start date for accurate month/year calculation
 * @returns {string} Formatted relative time string
 */
function formatRelativeTime(diffInMs, startDate) {
  const endDate = new Date(startDate.getTime() + diffInMs);
  const totalMonths = getMonthsDifference(startDate, endDate);
  const years = Math.floor(totalMonths / 12);
  const months = totalMonths % 12;
  const days = Math.floor(diffInMs / TIME_UNITS.DAY);
  const hours = Math.floor(diffInMs / TIME_UNITS.HOUR);
  const minutes = Math.floor(diffInMs / TIME_UNITS.MINUTE);
  const timeUnits = [
    { value: years, singular: 'one year ago', plural: `${years} years ago` },
    { value: months, singular: 'one month ago', plural: `${months} months ago` },
    { value: days, singular: 'one day ago', plural: `${days} days ago` },
    { value: hours, singular: 'one hour ago', plural: `${hours} hours ago` },
    { value: minutes, singular: 'one minute ago', plural: `${minutes} minutes ago` }
  ];
  const matchedUnit = timeUnits.find((unit) => unit.value > 0);
  return matchedUnit ? (matchedUnit.value === 1 ? matchedUnit.singular : matchedUnit.plural) : 'just now';
}

/**
 * Displays a warning message if the page is outdated
 * @param {number} hours - Number of hours since publication
 */
function displayOutdatedWarning(hours) {
  if (hours > OUTDATED_THRESHOLD_HOURS) {
    const hourText = hours === 1 ? 'hour' : 'hours';
    $('article').prepend(
      `<p class='warning'><span>This page was generated ${hours} ${hourText} ago. The information is most probably outdated.</span></p>`
    );
  }
}

/**
 * Updates the time element with relative time display
 * @param {jQuery} $timeElements - jQuery object for the time element
 */
function updateTimeDisplay($timeElements) {
  $timeElements.each(function (index, element) {
    const $element = $(element);
    const datetime = $element.attr('datetime');
    if (!datetime) {
      return;
    }
    const publishedDate = Date.parse(datetime);
    const currentDate = new Date();
    const timeDiff = currentDate - publishedDate;
    const startDate = new Date(publishedDate);
    const relativeTime = formatRelativeTime(timeDiff, startDate);
    $element.text(relativeTime);
    if (index === 0) {
      const hours = Math.floor(timeDiff / TIME_UNITS.HOUR);
      displayOutdatedWarning(hours);
    }
  });
}

$(function() {
  updateTimeDisplay($("time.relative-time[datetime]"));
});
