<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs">
  <xsl:template name="qo-section">
    <xsl:param name="what" as="xs:string"/>
    <xsl:param name="title" as="xs:string"/>
    <xsl:param name="colors" as="xs:string" select="'n_composite:orange'"/>
    <xsl:param name="before"/>
    <xsl:variable name="facts" select="/fb/f[what=$what and xs:dateTime(when) &gt; (xs:dateTime($today) - xs:dayTimeDuration('P180D'))]"/>
    <xsl:choose>
      <xsl:when test="empty($facts)">
        <p class="darkred">
          <xsl:text>There is no information about the </xsl:text>
          <xsl:value-of select="$title"/>
          <xsl:text>.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <h2>
          <xsl:value-of select="$title"/>
        </h2>
        <xsl:if test="$before != ''">
          <p>
            <xsl:copy-of select="$before"/>
          </p>
        </xsl:if>
        <div class="qo-section">
          <canvas id="{$what}">
            <xsl:text> </xsl:text>
          </canvas>
        </div>
        <script type="text/javascript">
          <xsl:text>$(function(){const color = chroma('#D3D3D3'); qo_render('</xsl:text>
          <xsl:value-of select="$what"/>
          <xsl:text>',{labels:[</xsl:text>
          <xsl:for-each select="$facts">
            <xsl:sort select="when" data-type="text" order="ascending"/>
            <xsl:if test="position() &gt; 1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>'</xsl:text>
            <xsl:value-of select="format-date(xs:date(xs:dateTime(when)), '[M1]/[D1]')"/>
            <xsl:text>'</xsl:text>
          </xsl:for-each>
          <xsl:text>],</xsl:text>
          <xsl:text>datasets:[</xsl:text>
          <xsl:for-each select="distinct-values($facts/*[starts-with(name(), 'n_')]/name())">
            <xsl:variable name="n" select="."/>
            <xsl:if test="position() &gt; 1">
              <xsl:text>,</xsl:text>
            </xsl:if>
            <xsl:text>{label:'</xsl:text>
            <xsl:value-of select="substring-after($n, 'n_')"/>
            <xsl:text>',borderColor:</xsl:text>
            <xsl:variable name='c' select="substring-before(substring-after(concat(',', $colors, ','), concat(',', $n, ':')), ',')"/>
            <xsl:choose>
              <xsl:when test="$c">
                <xsl:text>'</xsl:text>
                <xsl:value-of select="$c"/>
                <xsl:text>'</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>color.darken(</xsl:text>
                <xsl:value-of select="position() * 0.4"/>
                <xsl:text>).hex()</xsl:text>
                <xsl:text>,borderWidth:1</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="substring-after($n, 'n_') != 'composite'">
              <xsl:text>,hidden: true</xsl:text>
            </xsl:if>
            <xsl:text>,data:[</xsl:text>
            <xsl:for-each select="$facts">
              <xsl:sort select="when" data-type="text" order="ascending"/>
              <xsl:if test="position() &gt; 1">
                <xsl:text>,</xsl:text>
              </xsl:if>
              <xsl:variable name="cell" select="*[name()=$n]/text()"/>
              <xsl:choose>
                <xsl:when test="$cell = ''">
                  <xsl:text>null</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$cell"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:text>]}</xsl:text>
          </xsl:for-each>
          <xsl:text>]});});</xsl:text>
        </script>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
