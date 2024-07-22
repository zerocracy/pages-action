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
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/fb" mode="qos">
    <xsl:variable name="fb" select="."/>
    <div class="qos">
      <h2>
        <xsl:text>Quality of Service</xsl:text>
      </h2>
      <div style="width: 800px;">
        <canvas id="qos" style="width: 100%">
          <xsl:text> </xsl:text>
        </canvas>
      </div>
    </div>
    <script type="text/javascript">
      <xsl:text>const qos_data = { labels: [</xsl:text>
      <xsl:for-each select="f[what='quality-of-service']/when">
        <xsl:sort select="when" data-type="text" order="ascending"/>
        <xsl:if test="position() &gt; 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>'</xsl:text>
        <xsl:value-of select="when"/>
        <xsl:text>'</xsl:text>
      </xsl:for-each>
      <xsl:text>],</xsl:text>
      <xsl:text>datasets: [</xsl:text>
      <xsl:for-each select="tokenize('average_issue_lifetime average_pull_lifetime average_release_interval average_workflow_success_rate', ' ')">
        <xsl:variable name="metric" select="."/>
        <xsl:if test="position() &gt; 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:text>{ label: '</xsl:text>
        <xsl:value-of select="."/>
        <xsl:text>', data: [</xsl:text>
        <xsl:for-each select="$fb/f[what='quality-of-service']">
          <xsl:sort select="when" data-type="text" order="ascending"/>
          <xsl:if test="position() &gt; 1">
            <xsl:text>, </xsl:text>
          </xsl:if>
          <xsl:value-of select="*[name()=concat('n_', $metric)]/text()"/>
        </xsl:for-each>
        <xsl:text>] }</xsl:text>
      </xsl:for-each>
      <xsl:text>] };</xsl:text>
    </script>
  </xsl:template>
</xsl:stylesheet>
