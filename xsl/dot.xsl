<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs z">
  <xsl:variable name="dot_facts" select="/fb/f[what='dimensions-of-terrain' and xs:dateTime(when) &gt; $since]"/>
  <xsl:template match="/" mode="dot">
    <xsl:choose>
      <xsl:when test="empty($dot_facts)">
        <p class="darkred">
          <xsl:text>There is no information about the dimensions of terrain.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/fb" mode="dot-non-empty"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="/fb" mode="dot-non-empty">
    <h2>
      <xsl:text>Dimensions of Terrain (DoT)</xsl:text>
    </h2>
    <table>
      <colgroup>
        <!-- Name -->
        <col/>
      </colgroup>
      <colgroup>
        <xsl:attribute name="span">
          <xsl:value-of select="$weeks"/>
        </xsl:attribute>
        <xsl:for-each select="1 to $weeks">
          <!-- Weeks -->
          <col style="width: 4em;"/>
        </xsl:for-each>
      </colgroup>
      <thead>
        <tr>
          <th>
            <xsl:text>Dimension</xsl:text>
          </th>
          <xsl:for-each select="1 to $weeks">
            <th class="right">
              <xsl:variable name="week" select="xs:integer(.)"/>
              <xsl:variable name="d" select="xs:dateTime($today) - xs:dayTimeDuration(concat('P', ($weeks - $week) * 7, 'D'))"/>
              <xsl:variable name="w" select="xs:integer(format-date(xs:date($d), '[W]'))"/>
              <xsl:attribute name="title">
                <xsl:text>Week #</xsl:text>
                <xsl:value-of select="$w"/>
                <xsl:text> in </xsl:text>
                <xsl:value-of select="substring(xs:string(xs:date($d)), 1, 4)"/>
                <xsl:text>, starting on Monday </xsl:text>
                <xsl:value-of select="z:monday($week)"/>
              </xsl:attribute>
              <xsl:text>w</xsl:text>
              <xsl:value-of select="$w"/>
            </th>
          </xsl:for-each>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each select="distinct-values($dot_facts/*[contains(name(), '_') and not(starts-with(name(), '_'))]/name())">
          <xsl:sort select="." data-type="text"/>
          <xsl:variable name="n" select="."/>
          <tr>
            <td class="ff">
              <xsl:value-of select="$n"/>
            </td>
            <xsl:for-each select="1 to $weeks">
              <xsl:variable name="week" select="xs:integer(.)"/>
              <xsl:variable name="f" select="$dot_facts[z:in-week(when, $week)][last()]"/>
              <td class="ff right">
                <xsl:choose>
                  <xsl:when test="$f">
                    <xsl:variable name="v" select="$f/*[name()=$n]"/>
                    <xsl:choose>
                      <xsl:when test="$v">
                        <xsl:value-of select="$v/text()"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:text> </xsl:text>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:text> </xsl:text>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </xsl:for-each>
          </tr>
        </xsl:for-each>
      </tbody>
    </table>
  </xsl:template>
</xsl:stylesheet>
