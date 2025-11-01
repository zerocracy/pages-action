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
  return yearsDiff * 12 + monthsDiff;
}
/**
 * Calculates the difference in years between two dates
 * @param {Date} startDate - The earlier date
 * @param {Date} endDate - The later date
 * @returns {number} Number of years difference
 */
function getYearsDifference(startDate, endDate) {
  return endDate.getFullYear() - startDate.getFullYear();
}
/**
 * Formats a time difference as a human-readable relative time string
 * @param {number} diffInMs - Time difference in milliseconds
 * @param {Date} startDate - The start date for accurate month/year calculation
 * @returns {string} Formatted relative time string
 */
function formatRelativeTime(diffInMs, startDate) {
  const endDate = new Date(startDate.getTime() + diffInMs);
  const years = getYearsDifference(startDate, endDate);
  const months = getMonthsDifference(startDate, endDate);
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
  for (const unit of timeUnits) {
    if (unit.value > 0) {
      return unit.value === 1 ? unit.singular : unit.plural;
    }
  }
  return 'just now';
}
/**
 * Displays a warning message if the page is outdated
 * @param {number} hours - Number of hours since publication
 */
function displayOutdatedWarning(hours) {
  if (hours > OUTDATED_THRESHOLD_HOURS) {
    $('article').prepend(
      `<p class='warning'><span>This page was generated ${hours} hours ago. The information is most probably outdated.</span></p>`
    );
  }
}
/**
 * Updates the time element with relative time display
 * @param {jQuery} $timeElement - jQuery object for the time element
 */
function updateTimeDisplay($timeElement) {
  const datetime = $timeElement.attr('datetime');
  if (!datetime) {
    return;
  }
  const publishedDate = Date.parse(datetime);
  const currentDate = new Date();
  const timeDiff = currentDate - publishedDate;
  const relativeTime = formatRelativeTime(timeDiff);
  $timeElement.html(`<span title="${datetime}">${relativeTime}</span>`);
  const hours = Math.floor(timeDiff / TIME_UNITS.HOUR);
  displayOutdatedWarning(hours);
}
$(function () {
  const $time = $("time[itemprop='datePublished']");
  updateTimeDisplay($time);
});
