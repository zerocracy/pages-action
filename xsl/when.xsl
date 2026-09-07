<?xml version="1.0" encoding="UTF-8"?>
<!--
* SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
* SPDX-License-Identifier: MIT
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:z="https://www.zerocracy.com" version="2.0" exclude-result-prefixes="xs z">
  <xsl:function name="z:when" as="xs:dateTime?">
    <!--
    Reads the moment of a fact out of its "when" property. A property of a
    fact is a set of values, so it may hold more than one, and the XML then
    carries them as "v" children instead of as text. The earliest of them is
    the answer, so that a fact written twice still lands in one place instead
    of taking the whole page down with a type error. A fact with no "when"
    at all answers with nothing, the way reading the property directly did.
    -->
    <xsl:param name="w" as="element()*"/>
    <xsl:sequence select="min(for $v in ($w/v, $w[not(v)]) return xs:dateTime($v))"/>
  </xsl:function>
</xsl:stylesheet>
