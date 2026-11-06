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
    <!--
    A direct decimal cast preserves the binary fraction. Format it first;
    340 optional places cover a double's decimal digits without exponent notation.
    -->
    <xsl:variable name="picture" select="concat('0.', string-join(for $n in 1 to 340 return '#', ''))"/>
    <xsl:variable name="product" select="if (abs($value) lt xs:double('INF') and $factor ne 0) then xs:decimal(format-number($value, $picture)) * $factor else $value * $factor"/>
    <xsl:sequence select="if ($value lt 0) then -(round(-$product) div $factor) else round($product) div $factor"/>
  </xsl:function>
</xsl:stylesheet>
