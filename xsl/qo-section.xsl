<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs z">
  <xsl:include href="script-with-cdata.xsl"/>
  <xsl:function name="z:snake-case-to-title" as="xs:string">
    <xsl:param name="line" as="xs:string"/>
    <xsl:variable name="words" select="tokenize($line, '_')"/>
    <xsl:value-of select="string-join(for $word in $words return concat(upper-case(substring($word, 1, 1)), substring($word, 2)), ' ')"/>
  </xsl:function>
  <xsl:template name="qo-section">
    <xsl:param name="what" as="xs:string"/>
    <xsl:param name="title" as="xs:string"/>
    <xsl:param name="colors" as="xs:string" select="'n_composite:orange'"/>
    <xsl:param name="before"/>
    <xsl:variable name="facts" select="/fb/f[what=$what and xs:dateTime(when) &gt; (xs:dateTime($today) - xs:dayTimeDuration('P180D'))]"/>
    <h2>
      <xsl:value-of select="$title"/>
    </h2>
    <xsl:choose>
      <xsl:when test="empty($facts)">
        <p class="darkred">
          <xsl:text>No information visible at the moment.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
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
        <xsl:variable name="js-content">
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
            <xsl:value-of select="z:snake-case-to-title(substring-after($n, 'n_'))"/>
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
            <xsl:if test="contains(substring-after($n, 'n_'), '_')">
              <xsl:text>,hidden:true</xsl:text>
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
        </xsl:variable>
        <xsl:call-template name="script-with-cdata">
          <xsl:with-param name="content" select="string($js-content)"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
