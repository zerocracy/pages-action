<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:function name="z:num" as="xs:double?">
    <xsl:param name="property" as="element()*"/>
    <xsl:variable name="value" select="($property/v, $property[not(v)])[1]"/>
    <xsl:variable name="number" select="if (empty($value) or not(string($value) castable as xs:double)) then () else xs:double($value)"/>
    <xsl:sequence select="$number[. = . and abs(.) != xs:double('INF')]"/>
  </xsl:function>
  <xsl:template match="f[what='earned-value']" priority="2">
    <xsl:variable name="ac" select="z:num(ac)"/>
    <xsl:variable name="ev" select="z:num(ev)"/>
    <xsl:variable name="pv" select="z:num(pv)"/>
    <xsl:variable name="cpi" select="$ev div $ac"/>
    <xsl:variable name="spi" select="$ev div $pv"/>
    <xsl:choose>
      <xsl:when test="abs($cpi) lt xs:double('INF') and abs($spi) lt xs:double('INF')">
        <p>
          <xsl:text>AC: </xsl:text>
          <xsl:value-of select="format-number($ac, '0')"/>
          <xsl:text>, EV: </xsl:text>
          <xsl:value-of select="format-number($ev, '0')"/>
          <xsl:text>, PV: </xsl:text>
          <xsl:value-of select="format-number($pv, '0')"/>
          <xsl:text>, CPI: </xsl:text>
          <xsl:copy-of select="z:index($cpi)"/>
          <xsl:text>, SPI: </xsl:text>
          <xsl:copy-of select="z:index($spi)"/>
          <xsl:text>.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="f[what='earned-value']" priority="1">
    <p class="darkred">
      <xsl:text>Not enough data in the latest earned-value fact.</xsl:text>
    </p>
  </xsl:template>
</xsl:stylesheet>
