/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
 */

/**
 * Render QO canvas.
 * @param canvas The ID of "canvas" element in HTML
 * @param data Hash with data for the Chart
 */
function qo_render(canvas, data) {
  const ctx = document.getElementById(canvas);
  ctx.style.height = '10em';
  new Chart(ctx, {
    type: 'line',
    data: data,
    options: {
      responsive: false,
      plugins: {
        legend: {
          position: 'right'
        }
      }
    }
  });
}
