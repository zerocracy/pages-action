/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
 */

$(() => {
  $('.copy').click((event) => {
    const $this = $(event.currentTarget),
      text = $this.attr('data-text');
    if (navigator.clipboard) {
      if (window.isSecureContext) {
        navigator.clipboard.writeText(text);
      } else {
        alert('Cannot copy to clipboard!');
        return false;
      }
    } else {
      alert('The clipboard is inaccessible!');
      return false;
    }
    $check = $('<span class="darkgreen"> ✓</span>');
    $this.after($check);
    $check.delay(1000).fadeOut();
    return false;
  });
});
