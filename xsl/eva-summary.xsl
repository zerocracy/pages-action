<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs z">
  <xsl:template match="f[what='earned-value' and ac and ev and pv]" priority="2">
    <xsl:text>AC: </xsl:text>
    <xsl:value-of select="format-number(ac, '0')"/>
    <xsl:text>, EV: </xsl:text>
    <xsl:value-of select="format-number(ev, '0')"/>
    <xsl:text>, PV: </xsl:text>
    <xsl:value-of select="format-number(pv, '0')"/>
    <xsl:text>, CPI: </xsl:text>
    <xsl:copy-of select="z:index(ev div ac)"/>
    <xsl:text>, SPI: </xsl:text>
    <xsl:copy-of select="z:index(ev div pv)"/>
    <xsl:text>.</xsl:text>
  </xsl:template>
  <xsl:template match="f[what='earned-value']" priority="1">
    <p class="darkred">
      <xsl:text>Not enough data in the latest earned-value fact.</xsl:text>
    </p>
  </xsl:template>
</xsl:stylesheet>
