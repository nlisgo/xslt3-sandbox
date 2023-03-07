<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" exclude-result-prefixes="fn">

  <xsl:param name="exceptions" select="'LTPA'"/>

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="title[matches(.,'^[A-Z\s]+$') and not(matches(.,concat('^(', $exceptions, ')$')))]">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:value-of select="substring(.,1,1)"/>
      <xsl:value-of select="lower-case(substring(.,2))"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
