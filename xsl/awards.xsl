<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:include href="script-with-cdata.xsl"/>
  <xsl:variable name="days" select="z:pmp('hr', 'days_of_running_balance', '28')"/>
  <xsl:variable name="weeks" select="xs:integer(ceiling(xs:float($days) div 7))"/>
  <xsl:variable name="since" select="xs:dateTime($today) - xs:dayTimeDuration(concat('P', $days, 'D'))"/>
  <xsl:variable name="facts" select="$fb/f[award and xs:dateTime(when) &gt; $since and is_human = 1]"/>
  <xsl:function name="z:monday" as="xs:date">
    <!--
    Takes week number (e.g. 4) and returns ISO-8601 date of the
    Monday of this week. Weeks counting starts from the n-th week
    before $today (total number of weeks is specified in
    the "days_of_running_balance" property of the "pmp/hr" fact. Thus,
    if the week number is 2 and there are 56 days of running balance, it is
    the 7th week back in the past from today.
    -->
    <xsl:param name="week" as="xs:integer"/>
    <xsl:variable name="d" select="xs:dateTime($today) - xs:dayTimeDuration(concat('P', ($weeks - $week) * 7, 'D'))"/>
    <xsl:variable name="dow" select="xs:integer(format-date(xs:date($d), '[F1]'))"/>
    <xsl:value-of select="xs:date($d) - xs:dayTimeDuration(concat('P', $dow - 1, 'D'))"/>
  </xsl:function>
  <xsl:function name="z:in-week" as="xs:boolean">
    <!--
    Takes date and week number (e.g. 4) and returns 'true' if the date is
    inside the week. Weeks counting starts from the n-th week before today.
    -->
    <xsl:param name="when" as="xs:string"/>
    <xsl:param name="week" as="xs:integer"/>
    <xsl:variable name="monday" select="xs:dateTime(z:monday($week))"/>
    <xsl:variable name="sunday" select="$monday + xs:dayTimeDuration('P7D')"/>
    <xsl:value-of select="xs:dateTime($when) &gt; $monday and xs:dateTime($when) &lt; $sunday"/>
  </xsl:function>
  <xsl:function name="z:payables">
    <!--
    Calculates the amount to be paid to a user, according to the information
    in current awards and previously posted "reconciliation" facts.
    -->
    <xsl:param name="name" as="xs:string"/>
    <xsl:variable name="rec" select="$fb/f[what='reconciliation' and who_name=$name][last()]"/>
    <xsl:choose>
      <xsl:when test="$rec">
        <xsl:for-each select="'awarded', 'since', 'balance', 'payout', 'when'">
          <xsl:variable name="n" select="."/>
          <xsl:if test="not($rec/*[name()=$n])">
            <xsl:message terminate="yes">
              <xsl:text>There is no '</xsl:text>
              <xsl:value-of select="."/>
              <xsl:text>' property in the fact</xsl:text>
            </xsl:message>
          </xsl:if>
        </xsl:for-each>
        <td class="right ff">
          <xsl:variable name="accumulated" select="xs:integer(sum($fb/f[award and is_human = 1 and who_name=$name and xs:dateTime(when) &gt; xs:dateTime($rec/since)]/award))"/>
          <xsl:variable name="delta" select="$accumulated - xs:integer($rec/awarded)"/>
          <xsl:variable name="payable" select="$accumulated - xs:integer($rec/awarded) + xs:integer($rec/balance)"/>
          <xsl:attribute name="title">
            <xsl:text>The last payout of </xsl:text>
            <xsl:value-of select="xs:integer($rec/payout)"/>
            <xsl:text> points has been made on </xsl:text>
            <xsl:value-of select="xs:date(xs:dateTime($rec/when))"/>
            <xsl:text>, making the amount payable equal to </xsl:text>
            <xsl:value-of select="$rec/balance"/>
            <xsl:text>; since </xsl:text>
            <xsl:value-of select="xs:date(xs:dateTime($rec/since))"/>
            <xsl:text> you've accumulated </xsl:text>
            <xsl:value-of select="$delta"/>
            <xsl:text> points (</xsl:text>
            <xsl:value-of select="$accumulated"/>
            <xsl:text> - </xsl:text>
            <xsl:value-of select="xs:integer($rec/awarded)"/>
            <xsl:text>), that's why the amount payable now is </xsl:text>
            <xsl:value-of select="$payable"/>
          </xsl:attribute>
          <xsl:value-of select="$payable"/>
        </td>
      </xsl:when>
      <xsl:otherwise>
        <td>
          <xsl:comment>
            <xsl:text>There was no reconciliation (payouts) as of yet. </xsl:text>
            <xsl:text>The entire rolling balance may be paid.</xsl:text>
          </xsl:comment>
        </td>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  <xsl:function name="z:award">
    <!--
    Converts a number to a "span" with a properly formatted monetary value.
    The span will have a "class" with the HTML color, according to the value.
    -->
    <xsl:param name="a" as="xs:integer"/>
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
    </span>
  </xsl:function>
  <xsl:function name="z:td-award">
    <xsl:param name="a" as="xs:integer"/>
    <td class="ff right" data-value="{$a}">
      <xsl:copy-of select="z:award($a)"/>
    </td>
  </xsl:function>
  <xsl:template match="/" mode="awards">
    <xsl:apply-templates select="/fb" mode="awards"/>
  </xsl:template>
  <xsl:template match="/fb" mode="awards">
    <xsl:choose>
      <xsl:when test="empty($facts)">
        <p class="darkred">
          <xsl:text>No awards since </xsl:text>
          <xsl:value-of select="xs:date($since)"/>
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
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="/fb" mode="awards-non-empty"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="/fb" mode="awards-non-empty">
    <xsl:call-template name="script-with-cdata">
      <xsl:with-param name="content">
        <xsl:text>const weeks = </xsl:text>
        <xsl:value-of select="$weeks"/>
        <xsl:text>;</xsl:text>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="script-with-cdata">
      <xsl:with-param name="content">
        $(function() {
          $("#awards").tablesorter({
            sortList: [[2 + weeks, 1]]
          });
        });
      </xsl:with-param>
    </xsl:call-template>
    <table id="awards">
      <colgroup>
        <!-- Avatar -->
        <col style="width: 2.5em;"/>
        <!-- Award reason -->
        <col/>
        <xsl:for-each select="1 to $weeks">
          <!-- Weeks -->
          <col style="width: 4em;"/>
        </xsl:for-each>
        <!-- Run -->
        <col style="width: 4em;"/>
        <!-- Pay -->
        <xsl:if test="$fb/f[what='reconciliation']">
          <col style="width: 4em;"/>
        </xsl:if>
      </colgroup>
      <thead>
        <tr>
          <td colspan="{$weeks + 1}">
            <xsl:text> </xsl:text>
          </td>
          <td class="smaller center orange">
            <xsl:text>This week</xsl:text>
            <br/>
            <xsl:text>⬇</xsl:text>
          </td>
          <td colspan="{if ($fb/f[what='reconciliation']) then '2' else '1'}">
            <xsl:text> </xsl:text>
          </td>
        </tr>
        <tr>
          <th>
            <!-- Avatar -->
            <xsl:text> </xsl:text>
          </th>
          <th class="sorter">
            <xsl:text>Programmer / Award Reason</xsl:text>
          </th>
          <xsl:for-each select="1 to $weeks">
            <th class="right sorter">
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
            <xsl:text>Run</xsl:text>
          </th>
          <xsl:if test="$fb/f[what='reconciliation']">
            <th class="right sorter">
              <xsl:text>Pay</xsl:text>
            </th>
          </xsl:if>
        </tr>
      </thead>
      <tbody>
        <xsl:for-each-group select="$facts" group-by="who_name">
          <xsl:sort select="sum(award)" data-type="number" order="descending"/>
          <xsl:variable name="id" select="who/text()"/>
          <xsl:variable name="name" select="who_name/text()"/>
          <xsl:if test="count($facts[who_name = $name]) &gt; 0">
            <xsl:call-template name="programmer">
              <xsl:with-param name="id" select="$id"/>
              <xsl:with-param name="name" select="$name"/>
            </xsl:call-template>
          </xsl:if>
        </xsl:for-each-group>
      </tbody>
      <tfoot>
        <tr>
          <td>
            <!-- Avatar -->
            <xsl:text> </xsl:text>
          </td>
          <td class="right">
            <!-- Name -->
            <span>
              <xsl:attribute name="title">
                <xsl:text>There are </xsl:text>
                <xsl:copy-of select="count(/fb/f[award])"/>
                <xsl:text> awarding facts in the XML, while </xsl:text>
                <xsl:copy-of select="count($facts)"/>
                <xsl:text> of them count</xsl:text>
              </xsl:attribute>
              <xsl:text>Total</xsl:text>
              <xsl:if test="count($facts) != count(/fb/f[award])">
                <xsl:text> (</xsl:text>
                <xsl:copy-of select="count($facts)"/>
                <xsl:text>/</xsl:text>
                <xsl:copy-of select="count(/fb/f[award])"/>
                <xsl:text>)</xsl:text>
              </xsl:if>
              <xsl:text>:</xsl:text>
            </span>
          </td>
          <xsl:for-each select="1 to $weeks">
            <xsl:variable name="week" select="."/>
            <xsl:copy-of select="z:td-award(xs:integer(sum($facts[z:in-week(when, $week)]/award)))"/>
          </xsl:for-each>
          <xsl:copy-of select="z:td-award(xs:integer(sum($facts/award)))"/>
          <xsl:if test="$fb/f[what='reconciliation']">
            <td class="right ff">
              <!-- Pay -->
              <xsl:text> </xsl:text>
            </td>
          </xsl:if>
        </tr>
      </tfoot>
    </table>
  </xsl:template>
  <xsl:template name="programmer">
    <xsl:param name="id"/>
    <xsl:param name="name"/>
    <tr>
      <td class="avatar" title="{$id}">
        <a href="https://github.com/{$name}">
          <img src="https://github.com/{$name}.png" width="64" height="64" alt="@{$name}"/>
        </a>
      </td>
      <td>
        <span class="ff" title="{$id}">
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
        <xsl:variable name="c" select="count($facts[who_name=$name]/award)"/>
        <a href="#" onclick="$('.p_{$name}').toggle(); return false;">
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
        <xsl:copy-of select="z:td-award(xs:integer(sum($facts[who_name=$name and z:in-week(when, $week)]/award)))"/>
      </xsl:for-each>
      <xsl:copy-of select="z:td-award(xs:integer(sum($facts[who_name=$name]/award)))"/>
      <xsl:if test="$fb/f[what='reconciliation']">
        <xsl:copy-of select="z:payables($name)"/>
      </xsl:if>
    </tr>
    <xsl:if test="$fb/f[what='reconciliation' and who=$id]">
      <tr class="sub tablesorter-childRow p-table p_{$name}" style="display: none;">
        <td>
          <!-- Avatar -->
          <xsl:text> </xsl:text>
        </td>
        <td class="right">
          <!-- Reason -->
          <xsl:text>Payouts:</xsl:text>
        </td>
        <xsl:for-each select="1 to $weeks">
          <xsl:variable name="week" select="."/>
          <td class="right">
            <xsl:choose>
              <xsl:when test="$fb/f[what='reconciliation' and who=$id and z:in-week(when, $week)]">
                <xsl:for-each select="$fb/f[what='reconciliation' and who=$id and z:in-week(when, $week)]">
                  <xsl:if test="position() &gt; 1">
                    <br/>
                  </xsl:if>
                  <span>
                    <xsl:attribute name="title">
                      <xsl:text>Since </xsl:text>
                      <xsl:value-of select="xs:date(xs:dateTime(since))"/>
                      <xsl:text> you've accumulated </xsl:text>
                      <xsl:value-of select="xs:integer(awarded)"/>
                      <xsl:text> points, a payout of </xsl:text>
                      <xsl:value-of select="xs:integer(payout)"/>
                      <xsl:text> points has been made on </xsl:text>
                      <xsl:value-of select="xs:date(xs:dateTime(when))"/>
                      <xsl:text>, making the amount payable equal to </xsl:text>
                      <xsl:value-of select="balance"/>
                    </xsl:attribute>
                    <xsl:value-of select="xs:integer(payout)"/>
                  </span>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text> </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </xsl:for-each>
        <td>
          <!-- Run -->
          <xsl:text> </xsl:text>
        </td>
        <td>
          <!-- Pay -->
          <xsl:text> </xsl:text>
        </td>
      </tr>
    </xsl:if>
    <xsl:for-each select="$facts[who_name=$name]">
      <xsl:sort select="when" data-type="text"/>
      <xsl:variable name="fact" select="."/>
      <tr class="sub tablesorter-childRow p-table p_{$name}" style="display: none;">
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
                    <span title="The award hasn't been published yet">
                      <xsl:copy-of select="z:award($fact/award)"/>
                    </span>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <!-- Empty -->
                <xsl:text> </xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </xsl:for-each>
        <td>
          <!-- Run -->
          <xsl:text> </xsl:text>
        </td>
        <xsl:if test="$fb/f[what='reconciliation']">
          <td>
            <!-- Pay -->
            <xsl:text> </xsl:text>
          </td>
        </xsl:if>
      </tr>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
