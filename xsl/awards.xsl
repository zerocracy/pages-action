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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="z">
  <xsl:function name="z:award">
    <xsl:param name="a"/>
    <xsl:if test="$a &gt; 0">
      <xsl:text>+</xsl:text>
    </xsl:if>
    <xsl:value-of select="$a"/>
  </xsl:function>
  <xsl:variable name="since" select="current-dateTime() - xs:dayTimeDuration(concat('P', z:pmp(/fb, 'hr', 'days_of_running_balance'), 'D'))"/>
  <xsl:template match="/" mode="awards">
    <xsl:apply-templates select="/fb" mode="awards"/>
  </xsl:template>
  <xsl:template match="/fb[not(f[award and when &gt; $since])]" mode="awards">
    <p>
      <xsl:text>No awards as of yet.</xsl:text>
    </p>
  </xsl:template>
  <xsl:template match="/fb[f[award and when &gt; $since]]" mode="awards">
    <table id="awards" border="1">
      <colgroup>
        <col style="width: 2em;"/>
        <col style="width: 2.5em;"/>
        <col style="width: 2em;"/>
        <col style="width: 40em;"/>
        <col/>
        <col style="width: 15em;"/>
      </colgroup>
      <thead>
        <tr>
          <th class="right">
            <xsl:text>#</xsl:text>
          </th>
          <th>
            <xsl:text> </xsl:text>
          </th>
          <th colspan="2">
            <xsl:text>Programmer / Award Reason</xsl:text>
          </th>
          <th class="right">
            <xsl:text>Score</xsl:text>
          </th>
          <th>
            <xsl:text> </xsl:text>
          </th>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each-group select="f[who_name and award]" group-by="who_name">
          <xsl:sort select="sum(award)" data-type="number" order="descending"/>
          <xsl:call-template name="programmer">
            <xsl:with-param name="name" select="who_name/text()"/>
          </xsl:call-template>
        </xsl:for-each-group>
      </tbody>
    </table>
  </xsl:template>
  <xsl:template name="programmer">
    <xsl:param name="name"/>
    <tr>
      <td class="ff right">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="position()"/>
      </td>
      <td class="avatar">
        <img src="https://github.com/{$name}.png" width="64" height="64" alt="@{$name}"/>
      </td>
      <td colspan="2">
        <span class="ff">
          <a>
            <xsl:attribute name="href">
              <xsl:text>https://github.com/</xsl:text>
              <xsl:value-of select="$name"/>
            </xsl:attribute>
            <xsl:text>@</xsl:text>
            <xsl:value-of select="$name"/>
          </a>
        </span>
        <xsl:text> (</xsl:text>
        <xsl:variable name="c" select="count(/fb/f[who_name=$name and award]/award)"/>
        <a href="" onclick="$('.p_{$name}').show(); return false;">
          <xsl:value-of select="$c"/>
          <xsl:text> award</xsl:text>
          <xsl:if test="$c &gt; 1">
            <xsl:text>s</xsl:text>
          </xsl:if>
        </a>
        <xsl:text>)</xsl:text>
      </td>
      <td class="right">
        <xsl:value-of select="z:award(sum(/fb/f[who_name=$name and award]/award))"/>
      </td>
      <td>
        <xsl:text> </xsl:text>
      </td>
    </tr>
    <xsl:for-each select="/fb/f[who_name=$name and award]">
      <tr class="p_ p_{$name}" style="display: none;">
        <td>
          <xsl:text> </xsl:text>
        </td>
        <td>
          <xsl:text> </xsl:text>
        </td>
        <td>
          <xsl:text> </xsl:text>
        </td>
        <td>
          <xsl:value-of select="why"/>
        </td>
        <td class="ff right">
          <xsl:choose>
            <xsl:when test="href">
              <a>
                <xsl:attribute name="href">
                  <xsl:value-of select="href"/>
                </xsl:attribute>
                <xsl:value-of select="z:award(award)"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="z:award(award)"/>
            </xsl:otherwise>
          </xsl:choose>
        </td>
        <td>
          <xsl:variable name="age" select="number((current-dateTime() - xs:dateTime(time)) div xs:dayTimeDuration('P1D'))"/>
          <xsl:choose>
            <xsl:when test="$age &lt; 1">
              <xsl:text>today</xsl:text>
            </xsl:when>
            <xsl:when test="$age &lt; 7">
              <xsl:text>this week</xsl:text>
            </xsl:when>
            <xsl:when test="$age &lt; 99">
              <xsl:value-of select="floor($age)"/>
              <xsl:text>d ago</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>earlier</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
