/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
 */

$(function() {
  const dob = Date.parse($("time[itemprop='datePublished']").attr("datetime"));
  const hours = parseInt((new Date() - dob) / (1000 * 60 * 60));
  if (hours > 24) {
    $("article").prepend(
      "<p class='warning'><span>" +
      "This page was generated " + hours + " hours ago. " +
      "The information is most probably outdated.</span></p>"
    );
  }
});
