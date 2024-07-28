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
  <xsl:variable name="fb" select="/fb"/>
  <xsl:variable name="days" select="z:pmp(/fb, 'hr', 'days_of_running_balance')"/>
  <xsl:variable name="weeks" select="xs:integer($days div 7)"/>
  <xsl:variable name="since" select="xs:dateTime($today) - xs:dayTimeDuration(concat('P', $days, 'D'))"/>
  <xsl:function name="z:monday" as="xs:date">
    <xsl:param name="week" as="xs:integer"/>
    <xsl:variable name="d" select="xs:dateTime($today) - xs:dayTimeDuration(concat('P', ($weeks - $week) * 7, 'D'))"/>
    <xsl:variable name="dow" select="xs:integer(format-date(xs:date($d), '[F1]'))"/>
    <xsl:value-of select="xs:date($d) - xs:dayTimeDuration(concat('P', $dow - 1, 'D'))"/>
  </xsl:function>
  <xsl:function name="z:in-week" as="xs:boolean">
    <xsl:param name="when" as="xs:string"/>
    <xsl:param name="week" as="xs:integer"/>
    <xsl:variable name="monday" select="xs:dateTime(z:monday($week))"/>
    <xsl:variable name="sunday" select="$monday + xs:dayTimeDuration('P7D')"/>
    <xsl:value-of select="xs:dateTime($when) &gt; $monday and xs:dateTime($when) &lt; $sunday"/>
  </xsl:function>
  <xsl:function name="z:award">
    <xsl:param name="a"/>
    <span>
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="$a = 0">
            <xsl:text>lightgray</xsl:text>
          </xsl:when>
          <xsl:when test="$a &gt; 0">
            <xsl:text>darkgreen</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>darkred</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </span>
    <xsl:choose>
      <xsl:when test="$a = 0">
        <xsl:text>—</xsl:text>
      </xsl:when>
      <xsl:when test="$a &gt; 0">
        <xsl:text>+</xsl:text>
        <xsl:value-of select="$a"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$a"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:template match="/" mode="awards">
    <xsl:apply-templates select="/fb" mode="awards"/>
  </xsl:template>
  <xsl:template match="/fb[not(f[award and xs:dateTime(when) &gt; $since])]" mode="awards">
    <p>
      <xsl:text>No awards since </xsl:text>
      <xsl:value-of select="$since"/>
      <xsl:text> (</xsl:text>
      <xsl:value-of select="$days"/>
      <xsl:text> days before today)</xsl:text>
      <xsl:if test="/fb/f[award]">
        <xsl:text>, while there are </xsl:text>
        <xsl:value-of select="count(/fb/f[award])"/>
        <xsl:text> awards in total</xsl:text>
      </xsl:if>
      <xsl:text>.</xsl:text>
      <xsl:text> Either, you are having no activity in the project or the reporting is not configured correctly.</xsl:text>
    </p>
  </xsl:template>
  <xsl:template match="/fb[f[award and xs:dateTime(when) &gt; $since]]" mode="awards">
    <script type="text/javascript">
      $(function() {
        $("#awards").tablesorter();
      });
    </script>
    <table id="awards" border="1">
      <colgroup span="4">
        <!-- ID -->
        <col style="width: 2em;"/>
        <!-- Avatar -->
        <col style="width: 2.5em;"/>
        <!-- Award reason -->
        <col/>
      </colgroup>
      <colgroup>
        <xsl:attribute name="span">
            <xsl:value-of select="$weeks + 1"/>
        </xsl:attribute>
        <xsl:for-each select="1 to $weeks">
          <!-- Weeks -->
          <col style="width: 3em;"/>
        </xsl:for-each>
        <!-- Total -->
        <col style="width: 3em;"/>
      </colgroup>
      <thead>
        <tr>
          <th class="right">
            <xsl:text>#</xsl:text>
          </th>
          <th>
            <!-- Avatar -->
            <xsl:text> </xsl:text>
          </th>
          <th>
            <xsl:text>Programmer / Award Reason</xsl:text>
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
          <th class="right sorter">
            <xsl:text>Total</xsl:text>
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
      <tfoot>
        <tr>
          <td>
            <!-- ID -->
            <xsl:text> </xsl:text>
          </td>
          <td>
            <!-- Avatar -->
            <xsl:text> </xsl:text>
          </td>
          <td>
            <!-- Name -->
            <xsl:text> </xsl:text>
          </td>
          <xsl:for-each select="1 to $weeks">
            <xsl:variable name="week" select="."/>
            <td class="right">
              <xsl:copy-of select="z:award(sum($fb/f[award and z:in-week(when, $week)]/award))"/>
            </td>
          </xsl:for-each>
          <td class="right">
            <xsl:copy-of select="z:award(sum($fb/f[award and xs:dateTime(when) &gt; $since]/award))"/>
          </td>
        </tr>
      </tfoot>
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
      <td>
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
        <a href="" onclick="$('.p_{$name}').toggle(); return false;">
          <xsl:value-of select="$c"/>
          <xsl:text> award</xsl:text>
          <xsl:if test="$c &gt; 1">
            <xsl:text>s</xsl:text>
          </xsl:if>
        </a>
        <xsl:text>)</xsl:text>
      </td>
      <xsl:for-each select="1 to $weeks">
        <xsl:variable name="week" select="."/>
        <td class="right">
          <xsl:copy-of select="z:award(sum($fb/f[who_name=$name and award and z:in-week(when, $week)]/award))"/>
        </td>
      </xsl:for-each>
      <td class="right">
        <xsl:copy-of select="z:award(sum(/fb/f[who_name=$name and award and xs:dateTime(when) &gt; $since]/award))"/>
      </td>
    </tr>
    <xsl:for-each select="/fb/f[who_name=$name and award]">
      <xsl:variable name="fact" select="."/>
      <tr class="sub tablesorter-childRow p_ p_{$name}" style="display: none;">
        <td>
          <!-- ID -->
          <xsl:text> </xsl:text>
        </td>
        <td>
          <!-- Avatar -->
          <xsl:text> </xsl:text>
        </td>
        <td>
          <xsl:value-of select="why"/>
        </td>
        <xsl:for-each select="1 to $weeks">
          <xsl:variable name="week" select="."/>
          <td class="ff right">
            <xsl:choose>
              <xsl:when test="z:in-week($fact/when, $week)">
                <xsl:choose>
                  <xsl:when test="$fact/href">
                    <a>
                      <xsl:attribute name="href">
                        <xsl:value-of select="$fact/href"/>
                      </xsl:attribute>
                      <xsl:copy-of select="z:award($fact/award)"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="z:award($fact/award)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <!-- Empty -->
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </xsl:for-each>
        <td>
          <!-- Total -->
          <xsl:text> </xsl:text>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
