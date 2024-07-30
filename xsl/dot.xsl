<?xml version="1.0" encoding="UTF-8"?>
<!--
MIT License

Copyright (c) 2024 Zerocracy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to who_namem the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" exclude-result-prefixes="xs">
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
        <xsl:for-each select="distinct-values($dot_facts/*[contains(name(), '_')]/name())">
          <xsl:variable name="n" select="."/>
          <tr>
            <td class="ff">
              <xsl:value-of select="$n"/>
            </td>
            <xsl:for-each select="1 to $weeks">
              <xsl:variable name="week" select="xs:integer(.)"/>
              <xsl:variable name="f" select="$dot_facts[z:in-week(when, $week) and last()]"/>
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
