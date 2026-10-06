<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:function name="z:counted" as="xs:string">
    <xsl:param name="n"/>
    <xsl:param name="noun" as="xs:string"/>
    <xsl:sequence select="concat($n, ' ', $noun, if (string($n) = '1') then '' else 's')"/>
  </xsl:function>
  <xsl:template match="/" mode="repositories">
    <xsl:if test="/fb/f[what='repo-details']">
      <div class="repositories">
        <h2>
          <xsl:text>Repositories where the work is happening</xsl:text>
        </h2>
        <ul>
          <xsl:for-each select="/fb/f[what='repo-details']">
            <xsl:sort select="repository_name"/>
            <li>
              <a href="https://github.com/{repository_name}">
                <xsl:value-of select="repository_name"/>
              </a>
              <xsl:if test="description != ''">
                <xsl:text> </xsl:text>
                <xsl:value-of select="description"/>
              </xsl:if>
              <xsl:text> [ </xsl:text>
              <xsl:value-of select="z:counted(stars, 'star')"/>
              <xsl:text> · </xsl:text>
              <xsl:value-of select="z:counted(forks, 'fork')"/>
              <xsl:if test="language != ''">
                <xsl:text> · </xsl:text>
                <xsl:value-of select="language"/>
              </xsl:if>
              <xsl:text> · </xsl:text>
              <xsl:value-of select="z:counted(open_issues, 'open issue')"/>
              <xsl:if test="updated_at != ''">
                <xsl:text> · updated </xsl:text>
                <time class="relative-time">
                  <xsl:attribute name="datetime">
                    <xsl:value-of select="updated_at"/>
                  </xsl:attribute>
                  <xsl:attribute name="title">
                    <xsl:value-of select="substring(updated_at, 1, 10)"/>
                  </xsl:attribute>
                  <xsl:value-of select="substring(updated_at, 1, 10)"/>
                </time>
              </xsl:if>
              <xsl:text> ]</xsl:text>
            </li>
          </xsl:for-each>
        </ul>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
