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
 */
function displayOutdatedWarning() {
  if ($("#page-outdated-warning").length === 0) {
    const time = Date.parse($("#generated-time").attr("datetime"));
    if (isNaN(time)) {
      console.error("Could not parse the generated time");
      return;
    }
    const hours = Math.floor((Date.now() - time) / TIME_UNITS.HOUR);
    if (hours > OUTDATED_THRESHOLD_HOURS) {
      $('footer').prepend(
        `<p id="page-outdated-warning" class='red'>This page was generated ${hours} ${hours === 1 ? 'hour' : 'hours'} ago. The information is most probably outdated.</p>`
      );
    }
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
