/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
 */

$(() => {
  $('.copy').click((event) => {
    const $this = $(event.currentTarget),
      text = $this.attr('data-text');
    if (navigator.clipboard) {
      if (window.isSecureContext) {
        navigator.clipboard.writeText(text).then(() => {
          const $check = $('<span class="darkgreen"> ✓</span>');
          $this.after($check);
          $check.delay(1000).fadeOut();
        }).catch(() => {
          alert('Failed to copy to clipboard!');
        });
      } else {
        alert('Cannot copy to clipboard!');
        return false;
      }
    } else {
      alert('The clipboard is inaccessible!');
      return false;
    }
    return false;
  });
});
