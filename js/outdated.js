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
  DAY: 24 * 60 * 60 * 1000,
  MONTH: 30 * 24 * 60 * 60 * 1000,
  YEAR: 365 * 24 * 60 * 60 * 1000
};
const OUTDATED_THRESHOLD_HOURS = 24;
/**
 * Formats a time difference as a human-readable relative time string
 * @param {number} diffInMs - Time difference in milliseconds
 * @returns {string} Formatted relative time string
 */
function formatRelativeTime(diffInMs) {
  const years = Math.floor(diffInMs / TIME_UNITS.YEAR);
  const months = Math.floor(diffInMs / TIME_UNITS.MONTH);
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
