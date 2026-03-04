<?xml version="1.0" encoding="UTF-8"?>
<!--
 * SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
 * SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
  <xsl:template match="/" mode="repositories">
    <xsl:if test="/fb/f[what='repo-details']">
      <div class="repositories">
        <h2>
          <xsl:text>Repositories where the work is happening</xsl:text>
        </h2>
        <div class="repositories-grid">
          <xsl:for-each select="/fb/f[what='repo-details']">
            <xsl:sort select="repository_name"/>
            <div class="repo-row">
              <div class="repo-main">
                <a href="https://github.com/{repository_name}">
                  <xsl:value-of select="repository_name"/>
                </a>
              </div>
              <div class="repo-details">
                <xsl:if test="description != ''">
                  <span class="repo-desc">
                    <xsl:value-of select="description"/>
                  </span>
                </xsl:if>
                <span class="repo-stats">
                  <xsl:value-of select="stars"/>
                  <xsl:text> stars · </xsl:text>
                  <xsl:value-of select="forks"/>
                  <xsl:text> forks</xsl:text>
                  <xsl:if test="language != ''">
                    <xsl:text> · Language: </xsl:text>
                    <xsl:value-of select="language"/>
                  </xsl:if>
                  <xsl:text> · </xsl:text>
                  <xsl:value-of select="open_issues"/>
                  <xsl:text> open issues</xsl:text>
                  <xsl:if test="updated_at != ''">
                    <xsl:text> · Updated: </xsl:text>
                    <xsl:value-of select="substring(updated_at, 1, 10)"/>
                  </xsl:if>
                </span>
              </div>
            </div>
          </xsl:for-each>
        </div>
      </div>
    </xsl:if>
  </xsl:template>
</xsl:stylesheet>
