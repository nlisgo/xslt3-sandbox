<!-- Replace {\_} with _ in DOIs with incorrectly rendered underscores -->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all">
  
  <!-- Match DOIs with incorrectly rendered underscores -->
  <xsl:template match="text()[matches(., '10.\d{4,9}/[-._;()/:A-Z0-9\\\{\}]*[\\\{\}]+[-._;()/:A-Z0-9\\\{\}]*', 'i')]">
    <!-- Remove {, \, and } characters using the translate() function -->
    <xsl:value-of select="translate(., '{}\\', '')" />
  </xsl:template>
  
  <!-- Copy all other nodes as is -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
