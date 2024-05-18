<?xml version="1.0" encoding="UTF-8"?>
<!--
MIT License

Copyright (c) 2024 Zerocracy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
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
  <xsl:template match="/" mode="awards">
    <table id="awards">
      <colgroup>
        <col/>
        <col style="width: 2.5em;"/>
        <col/>
      </colgroup>
      <thead>
        <tr>
          <th>
            <xsl:text></xsl:text>
          </th>
          <th>
            <xsl:text></xsl:text>
          </th>
          <th>
            <xsl:text>Programmer</xsl:text>
          </th>
          <th>
            <xsl:text>Score</xsl:text>
          </th>
        </tr>
      </thead>
      <xsl:apply-templates select="/fb" mode="awards"/>
    </table>
  </xsl:template>
  <xsl:template match="fb" mode="awards">
    <tbody>
      <xsl:for-each-group select="f[payee and award]" group-by="payee">
        <xsl:call-template name="programmer">
          <xsl:with-param name="name" select="payee/text()"/>
        </xsl:call-template>
      </xsl:for-each-group>
    </tbody>
  </xsl:template>
  <xsl:template name="programmer">
    <xsl:param name="name"/>
    <tr>
      <td class="num">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="position()"/>
      </td>
      <td class="avatar">
        <img src="https://github.com/{$name}.png" width="64" height="64"/>
      </td>
      <td>
        <a>
          <xsl:attribute name="href">
            <xsl:text>https://github.com/</xsl:text>
            <xsl:value-of select="$name"/>
          </xsl:attribute>
          <xsl:text>@</xsl:text>
          <xsl:value-of select="$name"/>
        </a>
      </td>
      <td class="right">
        <xsl:variable name="sum" select="sum(/fb/f[payee=$name and award]/award)"/>
        <xsl:if test="$sum &gt; 0">
          <xsl:text>+</xsl:text>
        </xsl:if>
        <xsl:value-of select="$sum"/>
      </td>
    </tr>
  </xsl:template>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
