<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:function name="z:rounded" as="xs:double">
    <!--
    Rounds a value to the given factor (10 for one decimal, 100 for two),
    with a half going away from zero. The page and the badge both use it,
    so they show the same number for the same average.
    -->
    <xsl:param name="value" as="xs:double"/>
    <xsl:param name="factor" as="xs:integer"/>
    <xsl:sequence select="if ($value lt 0) then -(round(-$value * $factor) div $factor) else round($value * $factor) div $factor"/>
  </xsl:function>
</xsl:stylesheet>
