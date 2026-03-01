/**
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
 *
 * This file uses XML-special characters (&, <, >) in JavaScript operators.
 * It exists solely to verify that CDATA wrapping handles them correctly.
 */

var a = 1 < 2 && 3 > 2 && (1 & 1);
