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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xsl:variable name="qod_facts" select="/fb/f[what='quantity-of-deliverables' and xs:dateTime(when) &gt; (xs:dateTime($today) - xs:dayTimeDuration('P180D'))]"/>
  <xsl:template match="/fb" mode="qod">
    <xsl:choose>
      <xsl:when test="empty($qod_facts)">
        <p class="darkred">
          <xsl:text>There is no information about the Quantity of Deliverables.</xsl:text>
        </p>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="." mode="qod-non-empty"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="/fb" mode="qod-non-empty">
    <div class="qod">
      <h2>
        <xsl:text>Quantity of Deliverables</xsl:text>
      </h2>
      <div style="width: 800px;">
        <canvas id="qod" style="width: 100%">
          <xsl:text> </xsl:text>
        </canvas>
      </div>
    </div>
    <script type="text/javascript">
      <xsl:text>const qod_data = { labels: [</xsl:text>
      <xsl:for-each select="$qod_facts">
        <xsl:sort select="when" data-type="text" order="ascending"/>
        <xsl:if test="position() &gt; 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>'</xsl:text>
        <xsl:value-of select="format-date(xs:date(xs:dateTime(when)), '[M1]/[D1]')"/>
        <xsl:text>'</xsl:text>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
      <xsl:text>datasets: [</xsl:text>
      <xsl:for-each select="distinct-values($qod_facts/*[starts-with(name(), 'n_')]/name())">
        <xsl:variable name="metric" select="."/>
        <xsl:if test="position() &gt; 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>{ label: '</xsl:text>
        <xsl:value-of select="$metric"/>
        <xsl:text>', data: [</xsl:text>
        <xsl:for-each select="$qod_facts">
          <xsl:sort select="when" data-type="text" order="ascending"/>
          <xsl:if test="position() &gt; 1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="*[name()=$metric]">
              <xsl:value-of select="*[name()=$metric]/text()"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>null</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:text>] }</xsl:text>
      </xsl:for-each>
      <xsl:text>] };</xsl:text>
    </script>
  </xsl:template>
</xsl:stylesheet>
