<?xml version="1.0" ?>

<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  version="1.0"
>

  <xsl:output
    method="html"
    indent="yes"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
    doctype-system="DTD/xhtml1-strict.dtd"
  />

  <xsl:variable name="admon.graphics" select="0"/>
  <xsl:variable name="admon.style" select="''"/>
  <xsl:variable name="admon.textlabel" select="0"/>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="xml:lang">en</xsl:attribute>
      <xsl:attribute name="lang">en</xsl:attribute>
      <xsl:apply-templates select="page|error"/>
    </html>
  </xsl:template>

  <xsl:template match="/page">
    <head>
      <xsl:call-template name="head"/>
      <xsl:call-template name="scripts"/>
    </head>
    <body onLoad="prepareForm()">
    <table><tbody id="waitingRoom" style="display: none"/></table>
<div class="title">
Title Banner
      </div>
      <xsl:choose>
        <xsl:when test="count(//container[@id and not(ancestor::container[@id] | ancestor::form)] | //form[not(ancestor::container[@id] | ancestor::form)]) > 1">
          <form>
            <xsl:attribute name="method">
              <xsl:choose>
                <xsl:when test="@method = 'POST'">POST</xsl:when>
                <xsl:when test=".//file">POST</xsl:when>   
                <xsl:when test=".//textbox">POST</xsl:when>
                <xsl:when test=".//editbox">POST</xsl:when>
                <xsl:otherwise>POST</xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>   
            <xsl:if test=".//file">
              <xsl:attribute name="type">application/x-multipart</xsl:attribute>
            </xsl:if>
            <xsl:call-template name="page-body"/>
          </form>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="page-body"/>
        </xsl:otherwise>
      </xsl:choose>
    </body>
  </xsl:template>

  <xsl:template name="page-body">
    <xsl:if test="navigation">
      <div class="navigation">
          <xsl:if test="navigation[@type='main']">
            <xsl:for-each select="navigation[@type='main']">
              <xsl:apply-templates/>
              <xsl:if test="last() > position()"><br/></xsl:if>
            </xsl:for-each>
          </xsl:if>
          <xsl:if test="navigation[@type!='main']">
            <xsl:for-each select="navigation[@type!='main']">
              <xsl:if test="title">
                <span class="navigation.title"><xsl:value-of select="title"/></span>          
              </xsl:if>
              <xsl:apply-templates/>
            </xsl:for-each>
          </xsl:if>
      </div>
    </xsl:if>

    <xsl:if test="head">
      <div class="head">
        <xsl:for-each select="head">
          <div>
            <xsl:attribute name="class">
              <xsl:choose>
                <xsl:when test="@class">
                  <xsl:text>head-</xsl:text><xsl:value-of select="@class"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text>head-default</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:attribute>
            <xsl:apply-templates/>
          </div>
        </xsl:for-each>
      </div>
    </xsl:if>
    <xsl:if test=".//tabs">
      <xsl:param name="selected-tab" select=".//tabs/@tab"/>
      <xsl:for-each select=".//tabs/tab">
        <xsl:choose>
          <xsl:when test="$selected-tab = @id">
            <span class="tab-selected"><xsl:value-of select="title"/></span>
          </xsl:when>
          <xsl:otherwise>
            <span class="tab"><a href="?tab={@id}" class="tab"><xsl:value-of select=".//title"/></a></span>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each><br/>
    </xsl:if>

    <div class="content">
      <xsl:if test="title | content//container[@id = '_embedded']/title">
        <h1>
          <xsl:for-each select="title | content//container[@id = '_embedded']/title">
            <xsl:apply-templates/>
            <xsl:if test="position() != last()">
              <xsl:text>: </xsl:text>
            </xsl:if>
          </xsl:for-each>
        </h1>
      </xsl:if>
      <xsl:apply-templates select="content|tabs"/>
    </div>

    <div class="foot">
      <xsl:for-each select="foot">
        <div>
          <xsl:attribute name="class">
            <xsl:choose>
              <xsl:when test="@class">
                <xsl:text>foot-</xsl:text><xsl:value-of select="@class"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>foot-default</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:apply-templates/>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>

  <xsl:template name="head">
    <xsl:choose>
      <xsl:when test="title | content//container[@id = '_embedded']/title">
        <title>
          <xsl:for-each select="title | content//container[@id = '_embedded']/title">
            <xsl:value-of select="."/>
             <xsl:if test="position() != last()">
               <xsl:text>: </xsl:text>
             </xsl:if>
          </xsl:for-each>
        </title>
      </xsl:when>
      <xsl:otherwise>
        <title>Untitled</title>
      </xsl:otherwise>
    </xsl:choose>
    <link rel="stylesheet" href="/stylesheets/style.css" type="text/css" title="Site Style" media="screen"/>
    <xsl:if test="meta/stylesheet">
        <link rel="stylesheet">
          <xsl:if test="meta/stylesheet/@url">
            <xsl:attribute name="href"><xsl:value-of select="meta/stylesheet/@url"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="type">
            <xsl:choose>
              <xsl:when test="meta/stylesheet/@type"><xsl:value-of select="meta/stylesheet/@type"/></xsl:when>
              <xsl:otherwise><xsl:text>text/css</xsl:text></xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:attribute name="media">
            <xsl:choose>
              <xsl:when test="meta/stylesheet/@media"><xsl:value-of select="meta/stylesheet/@media"/></xsl:when>
              <xsl:otherwise><xsl:text>screen</xsl:text></xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="meta/stylesheet/@title">
            <xsl:attribute name="title"><xsl:value-of select="meta/stylesheet/@title"/></xsl:attribute>
          </xsl:if>
        </link>
    </xsl:if>
    <xsl:if test="meta/description">
      <meta name="description">
        <xsl:attribute name="content"><xsl:value-of select="meta/description"/></xsl:attribute>
      </meta>
    </xsl:if>
    <xsl:if test="meta/keywords">
      <meta name="keywords">
        <xsl:attribute name="content"><xsl:value-of select="meta/keywords"/></xsl:attribute>
      </meta>
    </xsl:if>
    <xsl:if test="meta/author">
      <meta name="author">
        <xsl:attribute name="content"><xsl:value-of select="meta/author"/></xsl:attribute>
      </meta>
    </xsl:if>
    <xsl:if test="meta/classification">
      <meta name="classification">
        <xsl:attribute name="content"><xsl:value-of select="meta/classification"/></xsl:attribute>
      </meta>
    </xsl:if>
  </xsl:template>

  <xsl:template match="meta"/>  <!-- make <meta/> stuff disappear -->

  <xsl:template name="scripts">
    <script src="/stylesheets/usableforms.js"></script>
    <script>
function init()
{
	prepareForm();
}
    </script>
    <style>
#waitingRoom {
    display: none;
}
    </style>
    <!-- script language="JavaScript">
      <xsl:call-template name="view-scripts"/>
    </script -->
  </xsl:template>

  <xsl:template match="container">
    <xsl:choose>
      <xsl:when test="@id and count(//container[@id and not(ancestor::container[@id] | ancestor::form)] | //form[not(ancestor::container[@id] | ancestor::form)]) > 1">
        <xsl:call-template name="container"/>
      </xsl:when>
      <xsl:otherwise>
        <form>
          <xsl:if test="@id"><xsl:attribute name="name"><xsl:value-of select="@id"/></xsl:attribute></xsl:if>
          <xsl:attribute name="method">
            <xsl:choose>
              <xsl:when test="@method = 'POST'">POST</xsl:when>
              <xsl:when test=".//file">POST</xsl:when>   
              <xsl:when test=".//textbox">POST</xsl:when>
              <xsl:when test=".//editbox">POST</xsl:when>
              <xsl:otherwise>POST</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>   
          <xsl:if test=".//file">
            <xsl:attribute name="type">application/x-multipart</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="container"/>
        </form>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="container">
    <!-- allowed to have rows="" and cols="" -->
    <div class="container">
      <xsl:if test="not(@id = '_embedded')">
        <div class="container-title">
            <xsl:value-of select=".//title"/>
        </div>
      </xsl:if>
      <xsl:if test="navigation[@type='main']">
        <div class="container-main-navigation">
          <xsl:apply-templates select="navigation[@type='main']"/>
        </div>
      </xsl:if>
      <xsl:for-each select="navigation[@type='sub']">
        <div class="container-sub-navigation">
<!--
          <td width="95%" valign="top" bgcolor="#3f3f7f" colspan="2" class="container-sub-navigation">
-->
            <xsl:apply-templates/>
        </div>
      </xsl:for-each>
      <xsl:for-each select="head"> <!-- class="container-head"> -->
        <div class="container-head">
          <xsl:apply-templates/>
        </div>
      </xsl:for-each>
      <div class="container-content">
        <xsl:apply-templates select="content"/>
      </div>
      <xsl:for-each select="foot">
        <div class="container-foot">
            <xsl:apply-templates/>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>

<!--
  ** Misc. structure elements
  -->

  <xsl:template match="content">
    <xsl:if test="not(.//container)">
      <xsl:if test=".//section">
        <a name="toc">
        <xsl:apply-templates select=".//section" mode="toc"/>
        </a>
      </xsl:if>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:if test=".//footnote">
       <h2 class="section">Endnotes</h2>
       <xsl:apply-templates select=".//footnote" mode="endnotes"/>
    </xsl:if>
  </xsl:template>
  <xsl:template match="content//error//title"/>


  <xsl:template match="containers">
    <!-- need to figure out how to stream -->
    <!--   stream="horizontal|vertical"
           cols="number of columns" -->
    <xsl:choose>
      <xsl:when test="0 and @cols > 1">
        <xsl:variable name="cols_available"><xsl:value-of select="@cols"/></xsl:variable>
        <table>
          <tr>
            <xsl:choose>
              <xsl:when test="@stream = 'vertical'">
              </xsl:when>
              <xsl:otherwise> <!-- horizontal -->
                <xsl:for-each select="container">
                  <!-- need to have a tmp var holding current cols
                        when we are going to exceed it, emit </tr><tr>
                    -->
                  <xsl:variable name="cur_pos"><xsl:value-of select="position()"/></xsl:variable>
                  <xsl:variable name="prev_cols"><xsl:value-of select="../container[$cur_pos - 1]/@cols"/></xsl:variable>
                  <xsl:variable name="full_width"><xsl:value-of select="sum(../container[$cur_pos >= position()]/@cols)"/></xsl:variable>
                  <xsl:variable name="last_cols_width"><xsl:value-of select="sum(../container[$cur_pos >= position() and position() > $cur_pos - $cols_available]/@cols)"/></xsl:variable>
                  <xsl:if test="position() > 1">
                    <xsl:choose>
                      <xsl:when test="@cols + $prev_cols >= $cols_available and $cols_available > $prev_cols">
                        <![CDATA[</tr><tr>]]>
                      </xsl:when>
                      <!--
                      <xsl:when test="(($full_width - @cols) mod $cols_available) > ($full_width mod $cols_available)">
                        <![CDATA[</tr><tr>]]>
                      </xsl:when>
                       -->
                    </xsl:choose>
                  </xsl:if>
                  <td valign="top">
                    <xsl:attribute name="colspan"><xsl:value-of select="@cols"/></xsl:attribute>
                    <xsl:call-template name="container"/>
                  </td>
                  <!-- we need better logic than this... maybe -->
                  <xsl:if test="last() > position()">
                    <xsl:choose>
                      <xsl:when test="@cols >= $cols_available">
                        <![CDATA[</tr><tr>]]>
                      </xsl:when>
                      <!-- -->
                      <xsl:when test="(($full_width - @cols) mod $cols_available) > ($full_width mod $cols_available)">
                        <![CDATA[</tr><tr>]]>
                      </xsl:when>
                       <!-- -->
                    </xsl:choose>
                  </xsl:if>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </tr>
        </table>
      </xsl:when>

      <xsl:otherwise> <!-- simple stream them out without an enclosing table -->
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- doc elements -->

  <xsl:template match="abbrev">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="abstract">
    <div class="abstract">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="accel">
    <span style="text-decoration: underline"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="akno">
    <div class="akno">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="acronym">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="action">
    <span class="action">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="address">
    <div class="address">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="affiliation">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="authorblurb">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="blockquote">
    <blockquote><xsl:apply-templates/></blockquote>
  </xsl:template>

  <xsl:template match="city">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="contrib">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="country">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="email">
    <a><xsl:attribute name="href">mailto:<xsl:value-of select="."/></xsl:attribute>&lt;<xsl:value-of select="."/>&gt;</a>
  </xsl:template>

  <xsl:template match="emphasis">
    <em class="emphasis">
      <xsl:apply-templates/>
    </em>
  </xsl:template>

  <xsl:template match="emphasis/emphasis">
    <span style="font-style: normal">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="fax">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="figure">
    <xsl:variable name="place">
      <xsl:choose>
        <xsl:when test="count(preceding::figure) mod 2 = 0">left</xsl:when>
        <xsl:otherwise>right</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <div class="figure-{$place}">
      <xsl:apply-templates/>
      <xsl:apply-templates select="caption" mode="caption"/>
    </div>
  </xsl:template>

  <xsl:template match="figure/caption"/>

  <xsl:template match="figure/caption" mode="caption">
    <p class="figure-caption">
      <span style="font-weight: bolder">Figure <xsl:value-of select="1 + count(preceding::figure)"/>. </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="firstname">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="formalpara">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="formalpara/title">
      <span style="font-weight: bolder"><xsl:apply-templates/>.</span>
  </xsl:template>

  <xsl:template match="formalpara/para">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="graphic">
    <img border="0">
      <xsl:attribute name="src">
        <xsl:value-of select="@fileref"/>
      </xsl:attribute>
      <xsl:if test="caption">
        <xsl:attribute name="alt">
          <xsl:value-of select="caption"/>
        </xsl:attribute>
      </xsl:if>
    </img>
  </xsl:template>

  <xsl:template match="honorific">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template name="admon.graphic.width">
    <xsl:param name="node" select="."/>
    <xsl:text>25</xsl:text>
  </xsl:template>

  <xsl:template match="note|important|warning|caution|tip">
    <xsl:choose>
      <xsl:when test="$admon.graphics != 0">
        <xsl:call-template name="graphical.admonition"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="nongraphical.admonition"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="admon.graphic">
    <xsl:param name="node" select="."/>
    <xsl:value-of select="$admon.graphics.path"/>
    <xsl:choose>
      <xsl:when test="local-name($node)='note'">note</xsl:when>
      <xsl:when test="local-name($node)='warning'">warning</xsl:when>
      <xsl:when test="local-name($node)='caution'">caution</xsl:when>
      <xsl:when test="local-name($node)='tip'">tip</xsl:when>
      <xsl:when test="local-name($node)='important'">important</xsl:when>
      <xsl:otherwise>note</xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$admon.graphics.extension"/>
  </xsl:template>

  <xsl:template name="graphical.admonition">
  <xsl:variable name="admon.type">
    <xsl:choose>
      <xsl:when test="local-name(.)='note'">Note</xsl:when>
      <xsl:when test="local-name(.)='warning'">Warning</xsl:when>
      <xsl:when test="local-name(.)='caution'">Caution</xsl:when>
      <xsl:when test="local-name(.)='tip'">Tip</xsl:when>
      <xsl:when test="local-name(.)='important'">Important</xsl:when>
      <xsl:otherwise>Note</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div xmlns="http://www.w3.org/1999/xhtml" class="{name(.)}">
    <xsl:if test="$admon.style != ''">
      <xsl:attribute name="style">
        <xsl:value-of select="$admon.style"/>
      </xsl:attribute>
    </xsl:if>

    <table border="0">
      <xsl:attribute name="summary">
        <xsl:value-of select="$admon.type"/>
        <xsl:if test="title">
          <xsl:text>: </xsl:text>
          <xsl:value-of select="title"/>
        </xsl:if>
      </xsl:attribute>
      <tr>
        <td rowspan="2" align="center" valign="top">
          <xsl:attribute name="width">
            <xsl:call-template name="admon.graphic.width"/>
          </xsl:attribute>
          <img alt="[{$admon.type}]">
            <xsl:attribute name="src">
              <xsl:call-template name="admon.graphic"/>
            </xsl:attribute>
          </img>
        </td>
        <th align="left">
          <xsl:call-template name="anchor"/>
          <!-- xsl:if test="$admon.textlabel != 0 or title" -->
            <xsl:apply-templates select="title" mode="object.title.markup"/>
          <!-- /xsl:if -->
        </th>
      </tr>
      <tr>
        <td colspan="2" align="left" valign="top">
          <xsl:apply-templates/>
        </td>
      </tr>
    </table>
  </div>
</xsl:template>

<xsl:template name="nongraphical.admonition">
  <div xmlns="http://www.w3.org/1999/xhtml" class="{name(.)}">
    <xsl:if test="$admon.style">
      <xsl:attribute name="style">
        <xsl:value-of select="$admon.style"/>
      </xsl:attribute>
    </xsl:if>

    <h3 class="title">
      <!-- xsl:call-template name="anchor"/ -->
      <!-- xsl:if test="$admon.textlabel != 0 or title" -->
        <xsl:apply-templates select="title" mode="object.title.markup"/>
      <!-- /xsl:if -->
    </h3>

    <xsl:apply-templates/>
  </div>
</xsl:template>

<xsl:template match="note/title"/>
<xsl:template match="important/title"/>
<xsl:template match="warning/title"/>
<xsl:template match="caution/title"/>
<xsl:template match="tip/title"/>


  <xsl:template match="itemizedlist">
    <ul>
      <xsl:apply-templates select="listitem"/>
    </ul>
  </xsl:template>

  <xsl:template match="lineage">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="link">
    <a>
      <xsl:attribute name="href"><xsl:call-template name="format-url"><xsl:with-param name="url"><xsl:value-of select="@url"/></xsl:with-param></xsl:call-template></xsl:attribute>
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <xsl:template match="listitem">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <xsl:template match="newline">
    <br />
  </xsl:template>

  <xsl:template match="orderedlist">
    <ol>
      <xsl:apply-templates select="listitem"/>
    </ol>
  </xsl:template>

  <xsl:template match="otheraddr">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="othername">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="para">
    <p><xsl:apply-templates/></p>
  </xsl:template>

  <xsl:template match="phone">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="pob">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="postcode">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="quote">
    ``<xsl:apply-templates/>''
  </xsl:template>

  <xsl:template match="quote//quote">
    `<xsl:apply-templates/>'
  </xsl:template>

  <xsl:template match="quote//quote//quote">
    ``<xsl:apply-templates/>''
  </xsl:template>

  <xsl:template match="quote//quote//quote//quote">
    `<xsl:apply-templates/>'
  </xsl:template>

  <xsl:template match="screen">
    <pre style="white-space: pre; font-weight: bolder; font-family: monospace;">
<xsl:apply-templates/>
    </pre>
  </xsl:template>

  <xsl:template match="state">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="street">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="surname">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="table">
    <div class="table">
      <xsl:apply-templates/>
      <xsl:apply-templates select="title" mode="caption"/>
    </div>
  </xsl:template>

  <xsl:template match="table/title"/>

  <xsl:template match="table/title" mode="caption">
    <xsl:variable name="num">
      <xsl:value-of select="1 + count(preceding::table)"/> 
    </xsl:variable>
    <p class="table-caption">
      <span style="font-weight: bolder">Table <xsl:value-of select="$num"/>. </span>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="tgroup">
    <table cellpadding="1" cellspacing="1">
      <xsl:apply-templates select="thead"/>
      <xsl:apply-templates select="row"/>
    </table>
  </xsl:template>

  <xsl:template match="thead">
    <tr cellpadding="1" style="border: solid black 1px;">
      <xsl:apply-templates select="column"/>
    </tr>
  </xsl:template>

  <xsl:template match="row">
    <tr>
      <xsl:if test="@class">
        <xsl:attribute name="class"><xsl:text>row-</xsl:text><xsl:value-of select="@class"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="column"/>
    </tr>
  </xsl:template>

  <xsl:template match="column">
    <td>
      <xsl:if test="@class">
        <xsl:attribute name="class"><xsl:text>row-</xsl:text><xsl:value-of select="@class"/></xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </td>
  </xsl:template>

  <xsl:template match="variable">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="variablelist">
    <dl class="variablelist">
      <xsl:if test="@style = 'compact'">
        <xsl:attribute name="compact"/>
      </xsl:if>
      <xsl:apply-templates select="varlistentry"/>
    </dl>
  </xsl:template>

  <xsl:template match="varlistentry">
    <dt>
      <xsl:for-each select="term">
        <xsl:apply-templates select="."/>
        <xsl:if test="position() != last()">
          <xsl:text>, </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </dt>
    <xsl:apply-templates select="listitem"/>
  </xsl:template>

  <xsl:template match="varlistentry/listitem">
    <dd><xsl:apply-templates/></dd>
  </xsl:template>

  <xsl:template match="footnote">
    <xsl:variable name="num">
      <xsl:value-of select="1 + count(preceding::footnote)"/>
    </xsl:variable>
    <a name="fnref{$num}">
    <a href="#fn{$num}">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$num"/>
      <xsl:text>]</xsl:text>
    </a>
    </a>
  </xsl:template>

  <xsl:template match="footnote" mode="endnotes">
    <p class="endnote">
    <xsl:variable name="num">
      <xsl:value-of select="1 + count(preceding::footnote)"/>
    </xsl:variable>
    <a name="fn{$num}">
    <a href="#fnref{$num}">
      <xsl:text>[</xsl:text>
      <xsl:value-of select="$num"/>
      <xsl:text>]</xsl:text>
    </a>
    </a>
    <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="bibliography|section">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="bibliography/title|section/title">
      <xsl:variable name="myid">
        <xsl:value-of select="generate-id()"/>
      </xsl:variable>
      <a name="{$myid}">
      <a href="#toc">
      <xsl:variable name="level">
        <xsl:value-of select="concat('h', 1 + count(ancestor::section|ancestor::bibliography))"/>
      </xsl:variable>
      <xsl:element name="{$level}">
        <xsl:attribute name="class">section</xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
      </a>
      </a>
  </xsl:template>

  <xsl:template match="bibliography/title|section/title" mode="toc">
      <xsl:variable name="myid">
        <xsl:value-of select="generate-id()"/>
      </xsl:variable>
      <a href="#{$myid}">
      <xsl:variable name="level">
        <xsl:value-of select="concat('h', 1 + count(ancestor::section|ancestor::bibliography))"/>
      </xsl:variable>
      <xsl:element name="{$level}">
        <xsl:attribute name="class">toc</xsl:attribute>
        <xsl:apply-templates/>
      </xsl:element>
      </a>
  </xsl:template>

  <xsl:template match="bibliography|section" mode="toc">
    <a>
      <xsl:apply-templates select="title" mode="toc"/>
    </a>
  </xsl:template>

  <xsl:template match="biblioentry">
    <p class="biblioentry">
      <xsl:apply-templates/>
    </p>
  </xsl:template>


  <!-- forms in the content -->

  <xsl:template match="form" mode="body">
    <xsl:param name="form_level"/>
    <xsl:call-template name="form-body">
      <xsl:with-param name="form_level" select="$form_level"/>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="form-body">
    <xsl:param name="form_level"/>
    <xsl:choose>
      <xsl:when test="ancestor::option">
        <span>
          <xsl:attribute name="relation">
              <xsl:text>rel:</xsl:text><xsl:apply-templates select="ancestor::option[1]" mode="id"/>
          </xsl:attribute>
          <xsl:apply-templates select="text|textline|textbox|editbox|file|grid|password|selection|form|group|textreader">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
          <xsl:with-param name="form_level"><value-of select="$form_level"/></xsl:with-param>
          </xsl:apply-templates>
          <xsl:if test="submit|reset">
            <span class="form-buttons">
              <xsl:apply-templates select="submit|reset">
                <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
              </xsl:apply-templates>
            </span>
          </xsl:if>
          <xsl:apply-templates select="stored">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
          </xsl:apply-templates>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="text|textline|textbox|editbox|file|grid|password|selection|form|group|textreader">
          <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
        <xsl:with-param name="form_level"><value-of select="$form_level"/></xsl:with-param>
        </xsl:apply-templates>
        <xsl:if test="submit|reset">
          <span class="form-buttons">
            <xsl:apply-templates select="submit|reset">
              <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
            </xsl:apply-templates>
          </span>
        </xsl:if>
        <xsl:apply-templates select="stored">
          <!-- xsl:with-param name="form_id"><xsl:value-of select="@id"/></xsl:with-param -->
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form">
<!--    <div align="center"> -->
    <xsl:choose>
      <xsl:when test="count(//container[@id and not(ancestor::container[@id] | ancestor::form)] | //form[not(ancestor::container[@id] | ancestor::form)]) > 1">
          <xsl:if test="./caption">
            <h2 class="form-caption">
              <xsl:apply-templates select="caption"/>
            </h2>
          </xsl:if>
          <span class="form-body">
          <xsl:call-template name="form-body">
            <xsl:with-param name="form_level">3</xsl:with-param>
          </xsl:call-template>
          </span>
      </xsl:when>
      <xsl:otherwise>
        <form>
          <xsl:if test="@id"><xsl:attribute name="name"><xsl:value-of select="@id"/></xsl:attribute></xsl:if>
          <xsl:attribute name="method">
            <xsl:choose>
              <xsl:when test="@method = 'POST'">POST</xsl:when>
              <xsl:when test=".//file">POST</xsl:when>
              <xsl:when test=".//textbox">POST</xsl:when>
              <xsl:when test=".//editbox">POST</xsl:when>
              <xsl:otherwise>POST</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test=".//file">
            <xsl:attribute name="type">application/x-multipart</xsl:attribute>
          </xsl:if>
            <xsl:if test="./caption">
              <h2 class="form-caption">
                <xsl:apply-templates select="caption"/>
              </h2>
            </xsl:if>
            <span class="form-body">
            <xsl:call-template name="form-body"/>
            </span>
        </form>
      </xsl:otherwise>
    </xsl:choose>
 <!--   </div> -->
  </xsl:template>

  <xsl:template match="form//caption">
    <span class="form-element-label">
    <xsl:if test="../@required = 1">
      <span class="form-entry-required-marker">*</span>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="../@missing = 1">
        <span class="form-entry-missing"><xsl:apply-templates/></span>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates/>
      </xsl:otherwise>
    </xsl:choose>
    </span>
  </xsl:template>

  <xsl:template match="form/form | option/form | option/caption/form">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
      <xsl:choose>
      <xsl:when test="./caption|./help">
        <fieldset>
          <legend>
            <xsl:attribute name="class">
              <xsl:text>form-legend-</xsl:text>
              <xsl:value-of select="$form_level"/>
            </xsl:attribute>
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          </legend>
          <xsl:call-template name="form-body">
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
          </xsl:call-template>
        </fieldset>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="form-body">
          <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form/group">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <span class="form-group">
      <span class="form-group-caption">
        <xsl:apply-templates select="caption"/>
        <xsl:apply-templates select="help"/>
      </span>
      <span class="form-group-elements">
        <xsl:apply-templates>
          <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>
        </xsl:apply-templates>
      </span>
    </span>
  </xsl:template>

  <xsl:template match="form/text">
    <span class="form-text">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="form/password | form//group/password">
    <!-- xsl:param name="form_id"/ -->
    <span class="form-element">
      <!-- label class="form-element-label">
        <xsl:attribute name="for">
          <xsl:apply-templates select="." mode="id"/>
        </xsl:attribute -->
        <xsl:apply-templates select="caption"/>
        <xsl:apply-templates select="help"/>
      <!-- /label -->
      <xsl:call-template name="field-password"/>
    </span>
  </xsl:template>

  <xsl:template match="form/textline">
    <!-- xsl:param name="form_id"/ -->
    <span class="form-element">
      <!-- label class="form-element-label">
        <xsl:attribute name="for">
          <xsl:apply-templates select="." mode="id"/>
        </xsl:attribute -->
        <xsl:apply-templates select="caption"/>
        <xsl:apply-templates select="help"/>
      <!-- /label -->
      <xsl:call-template name="field-textline"/>
    </span>
  </xsl:template>

  <xsl:template match="form//group/textline">
    <!-- xsl:param name="form_id"/ -->
    <xsl:call-template name="field-textline">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
    </xsl:call-template>    
  </xsl:template>

  <xsl:template match="form/textbox|form/editbox">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption">
        <fieldset>
          <legend>
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          </legend>
          <xsl:call-template name="field-textbox">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
          </xsl:call-template>    
        </fieldset>
      </xsl:when>
      <xsl:otherwise>
        <span class="form-element">
          <xsl:call-template name="field-textbox">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
            <xsl:with-param name="size">2</xsl:with-param>
          </xsl:call-template>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form//group/textbox | form//group/editbox">
    <!-- xsl:param name="form_id"/ -->
    <xsl:call-template name="field-textbox">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
    </xsl:call-template>    
  </xsl:template>

  <xsl:template match="form/textreader">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption">
        <fieldset>
          <legend>
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          </legend>
          <xsl:call-template name="field-textreader">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
          </xsl:call-template>    
        </fieldset>
      </xsl:when>
      <xsl:otherwise>
        <span class="form-element">
          <xsl:call-template name="field-textreader">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
            <xsl:with-param name="size">2</xsl:with-param>
          </xsl:call-template>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
            
  <xsl:template match="form//group/textreader">
    <!-- xsl:param name="form_id"/ -->
    <xsl:call-template name="field-textreader">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="form/selection">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:choose>
      <xsl:when test="./option//form//selection">
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          <xsl:call-template name="field-selection">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>
          </xsl:call-template>
      </xsl:when>
      <xsl:when test="./option//help|./option//form">
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          <xsl:call-template name="field-selection">
            <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>
          </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <span class="form-element">
          <!-- label class="form-element-label">
            <xsl:attribute name="for">
              <xsl:apply-templates select="." mode="id"/>
            </xsl:attribute -->
            <xsl:apply-templates select="caption"/>
            <xsl:apply-templates select="help"/>
          <!-- /label -->
          <xsl:call-template name="field-selection">
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>
          </xsl:call-template>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form//group/selection">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <xsl:call-template name="field-selection">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
      <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>  
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="form//grid">
    <xsl:call-template name="field-grid"/>
  </xsl:template>

  <xsl:template match="form/selection/option|form//group/selection/option">
    <xsl:param name="style"/>
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:choose>
      <xsl:when test="$style = 'radio'">
        <span class="form-selection-option">
        <input>
          <xsl:attribute name="type"><xsl:value-of select="$style"/></xsl:attribute>
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="parent::selection[1]" mode="id"/></xsl:attribute>
          <xsl:attribute name="show">
            <xsl:choose>
              <xsl:when test=".//form">
                <xsl:text>rel:</xsl:text>
                <xsl:apply-templates select="." mode="id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>none</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="checked"/>
            </xsl:if>
          </xsl:for-each>
        </input>
        <xsl:choose>
          <xsl:when test="caption">
            <xsl:choose>
              <xsl:when test="caption"><xsl:apply-templates select="caption"/></xsl:when>
              <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
            </xsl:choose>
            <xsl:apply-templates select="help"/>
            <xsl:if test="./form">
                <xsl:apply-templates select="form" mode="body">
                  <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:with-param -->
                  <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
                  <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
                </xsl:apply-templates>
            </xsl:if>
          </xsl:when>
          <xsl:when test="form">
            <xsl:if test="form/caption">
              <xsl:apply-templates select="form/caption"/>
              <xsl:apply-templates select="form/help"/>
            </xsl:if>
            <xsl:apply-templates select="form" mode="body">
              <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:with-param -->
              <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
              <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>
        </span>
      </xsl:when>
      <xsl:when test="$style = 'checkbox'">
        <span class="form-selection-option">
        <input>
          <xsl:attribute name="type"><xsl:value-of select="$style"/></xsl:attribute>
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="parent::selection[1]" mode="id"/></xsl:attribute>
          <xsl:attribute name="show">
            <xsl:choose>
              <xsl:when test=".//form">
                <xsl:text>rel:</xsl:text>
                <xsl:apply-templates select="." mode="id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>none</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="checked"/>
            </xsl:if>
          </xsl:for-each>
        </input>
        <xsl:choose>
          <xsl:when test="caption">
                <xsl:choose>
                  <xsl:when test="caption"><xsl:apply-templates select="caption"/></xsl:when>
                  <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
                </xsl:choose>
                <xsl:apply-templates select="help"/>
                <xsl:if test="./form">
                  <xsl:apply-templates select="form" mode="body">
                    <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:with-param -->
                    <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
                    <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
                  </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
            <xsl:when test="form">
              <xsl:if test="form/caption">
                <xsl:apply-templates select="form/caption"/>
                <xsl:apply-templates select="form/help"/>
              </xsl:if>
              <xsl:apply-templates select="form" mode="body">
                <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:with-param -->
                <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
                <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
              </xsl:apply-templates>
            </xsl:when>
          </xsl:choose>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <option>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="selected"/>
            </xsl:if>
          </xsl:for-each>
          <xsl:choose>
            <xsl:when test="caption">
              <xsl:value-of select="caption"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$myid"/>
            </xsl:otherwise>
          </xsl:choose>
        </option>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form/text">
    <xsl:choose>
      <xsl:when test="caption">
            <xsl:value-of select="caption"/>
            <xsl:apply-templates />
      </xsl:when>
      <xsl:otherwise>
            <xsl:apply-templates />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text/caption"/>

  <xsl:template match="form/file">
    <!-- xsl:param name="form_id"/ -->
    <tr>
      <td align="right" valign="top"> <!-- width="50%"> -->
        <xsl:apply-templates select="caption"/>
        <xsl:apply-templates select="help"/>
      </td>
      <td valign="top"> <!-- width="50%"> -->
        <input type="file">
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:if test="@accept">
            <xsl:attribute name="accept"><xsl:value-of select="@accept"/></xsl:attribute>
          </xsl:if>
        </input>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="form//stored">
    <!-- xsl:param name="form_id"/ -->
    <input type="hidden">
      <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:attribute name="value"><xsl:apply-templates/></xsl:attribute>
    </input>
  </xsl:template>

  <xsl:template match="form//submit">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption/* or (default and caption)">
        <!-- input type="submit" -->
        <button type="submit">
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="value">
            <xsl:choose>
              <xsl:when test="default">
                <xsl:value-of select="default"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="caption"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="caption"/>
        </button>
        <!-- /input -->
      </xsl:when>
      <xsl:otherwise>
        <input type="submit">
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="value">
            <xsl:choose>
              <xsl:when test="default">
                <xsl:value-of select="default"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="caption"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="form//reset">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption/*">
        <button type="reset">
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:apply-templates select="caption"/>
        </button>
      </xsl:when>
      <xsl:otherwise>
        <input type="reset">
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/>.<xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- forms in head or foot elements -->

  <xsl:template match="head//form|foot//form">
    <xsl:choose>
      <xsl:when test="count(//container[@id and not(ancestor::container[@id] | ancestor::form)] | //form[not(ancestor::container[@id] | ancestor::form)]) > 1">
                    <xsl:if test="./caption">
                  <xsl:apply-templates select="caption"/>
                  <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="text|grid|textline|textbox|editbox|file|password|selection|form|group|textreader">
              <!-- xsl:with-param name="form_id">
                <xsl:if test="@id">
                  <xsl:value-of select="@id"/>
                </xsl:if>
              </xsl:with-param -->
              <xsl:with-param name="form_level">3</xsl:with-param>
            </xsl:apply-templates>
            <xsl:if test="submit|reset">
                  <xsl:apply-templates select="submit|reset">
                    <!-- xsl:with-param name="form_id">
                      <xsl:if test="@id">
                        <xsl:value-of select="@id"/>
                      </xsl:if>
                    </xsl:with-param -->
                  </xsl:apply-templates>
            </xsl:if>
          <xsl:apply-templates select="stored">
            <!-- xsl:with-param name="form_id">
              <xsl:if test="@id">
                <xsl:value-of select="@id"/>
              </xsl:if>
            </xsl:with-param -->
          </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <form>
          <xsl:if test="@id">
            <xsl:attribute name="name"><xsl:value-of select="@id"/></xsl:attribute>
          </xsl:if>
          <xsl:attribute name="method">
            <xsl:choose>
              <xsl:when test="@method = 'POST'">POST</xsl:when>
              <xsl:when test=".//file">POST</xsl:when>
              <xsl:when test=".//textbox">POST</xsl:when>
              <xsl:when test=".//editbox">POST</xsl:when>
              <xsl:otherwise>POST</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="@target">
            <xsl:attribute name="action"><xsl:value-of select="@target"/></xsl:attribute>
          </xsl:if>
          <xsl:if test=".//file">
            <xsl:attribute name="type">application/x-multipart</xsl:attribute>
          </xsl:if>
            <xsl:if test="./caption">
                  <xsl:apply-templates select="caption"/>
                  <xsl:text>: </xsl:text>
            </xsl:if>
            <xsl:apply-templates select="text|grid|textline|textbox|editbox|file|password|selection|form|group|textreader">
              <!-- xsl:with-param name="form_id">
                <xsl:if test="@id">
                  <xsl:value-of select="@id"/>
                </xsl:if>
              </xsl:with-param -->
              <xsl:with-param name="form_level">3</xsl:with-param>
            </xsl:apply-templates>
            <xsl:if test="submit|reset">
                  <xsl:apply-templates select="submit|reset">
                    <!-- xsl:with-param name="form_id">
                      <xsl:if test="@id">
                        <xsl:value-of select="@id"/>
                      </xsl:if>
                    </xsl:with-param -->
                  </xsl:apply-templates>
            </xsl:if>
          <xsl:apply-templates select="stored">
            <!-- xsl:with-param name="form_id">
              <xsl:if test="@id">
                <xsl:value-of select="@id"/>
              </xsl:if>
            </xsl:with-param -->
          </xsl:apply-templates>
        </form>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="head/form/text|foot/form/text">
        <xsl:apply-templates/>
  </xsl:template>

  <!-- input fields -->

  <xsl:template match="head/form/password|foot/form/password">
    <!-- xsl:param name="form_id"/ -->
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <xsl:call-template name="field-password">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="head/form/textline|foot/form/textline">
    <!-- xsl:param name="form_id"/ -->
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <xsl:call-template name="field-textline">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="head/form/textbox|foot/form/textbox|head/form/editbox|foot/form/editbox">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption">
        <xsl:apply-templates select="caption"/>
        <xsl:apply-templates select="help"/>
        <xsl:call-template name="field-textbox">
          <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
        </xsl:call-template>    
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="field-textbox">
          <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
          <xsl:with-param name="size">2</xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="head/form/textreader|foot/form/textreader">
    <!-- xsl:param name="form_id"/ -->
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <xsl:call-template name="field-textreader"/>
  </xsl:template>
            
  <xsl:template match="head/form/selection|foot/form/selection">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <xsl:call-template name="field-selection">
      <!-- xsl:with-param name="form_id"><xsl:value-of select="$form_id"/></xsl:with-param -->
      <xsl:with-param name="form_level"><xsl:value-of select="$form_level"/></xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="head/form/selection/option|foot/form/selection/option">
    <xsl:param name="style"/>
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:choose>
      <xsl:when test="$style = 'radio'">
        <input>
          <xsl:attribute name="type"><xsl:value-of select="$style"/></xsl:attribute>
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="show">
            <xsl:choose>
              <xsl:when test=".//form">
                <xsl:text>rel:</xsl:text>
                <xsl:apply-templates select="." mode="id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>none</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="checked"/>
            </xsl:if>
          </xsl:for-each>
        </input>
        <xsl:choose>
          <xsl:when test="caption"><xsl:apply-templates select="caption"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="help"/>
        <xsl:if test="./form">
          <xsl:apply-templates select="form">
            <!-- xsl:with-param name="form_id"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:with-param -->
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$style = 'checkbox'">
        <span class="form-element">
        <input>
          <xsl:attribute name="type"><xsl:value-of select="$style"/></xsl:attribute>
          <!-- xsl:attribute name="name"><xsl:value-of select="$form_id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="show">
            <xsl:choose>
              <xsl:when test=".//form">
                <xsl:text>rel:</xsl:text>
                <xsl:apply-templates select="." mode="id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:text>none</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="checked"/>
            </xsl:if>
          </xsl:for-each>
        </input>
        <xsl:choose>
          <xsl:when test="caption"><xsl:apply-templates select="caption"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="help"/>
        <xsl:if test="./form">
          <xsl:apply-templates select="form">
            <!-- xsl:with-param name="form_id"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:with-param -->
            <xsl:with-param name="form_level"><xsl:value-of select="$form_level+1"/></xsl:with-param>
          </xsl:apply-templates>
        </xsl:if>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <option>
          <xsl:variable name="myid">
            <xsl:choose>
              <xsl:when test="@id">
                <xsl:value-of select="@id"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="."/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:attribute name="value"><xsl:value-of select="$myid"/></xsl:attribute>
          <xsl:for-each select="../default">
            <xsl:if test=". = $myid">
              <xsl:attribute name="selected"/>
            </xsl:if>
          </xsl:for-each>
          <xsl:apply-templates/>
        </option>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="head/form/file|foot/form/file">
    <!-- xsl:param name="form_id"/ -->
    <xsl:apply-templates select="caption"/>
    <xsl:apply-templates select="help"/>
    <input type="file">
      <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:if test="@accept">
        <xsl:attribute name="accept"><xsl:value-of select="@accept"/></xsl:attribute>
      </xsl:if>
    </input>
  </xsl:template>

  <xsl:template match="head/form/stored|foot/form/stored">
    <!-- xsl:param name="form_id"/ -->
    <input type="hidden">
      <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:attribute name="value"><xsl:apply-templates/></xsl:attribute>
    </input>
  </xsl:template>

  <xsl:template match="head/form/submit|foot/form/submit">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption/*">
        <button type="submit">
          <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="value"><xsl:value-of select="caption"/></xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="caption"/>
        </button>
      </xsl:when>
      <xsl:otherwise>
        <input type="submit">
          <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:attribute name="value"><xsl:value-of select="caption"/></xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="head/form/reset|foot/form/reset">
    <!-- xsl:param name="form_id"/ -->
    <xsl:choose>
      <xsl:when test="caption/*">
        <button type="reset">
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="caption"/>
        </button>
      </xsl:when>
      <xsl:otherwise>
        <input type="reset">
          <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:if test="ancestor::head">
            <xsl:attribute name="class">head</xsl:attribute>
          </xsl:if>
        </input>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- generic methods for outputting actual input element -->

  <xsl:template name="field-password">
    <!-- xsl:param name="form_id"/ -->
    <input type="password">
      <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:attribute name="value"><xsl:value-of select="default"/></xsl:attribute>
      <xsl:attribute name="size">
        <xsl:choose>
          <xsl:when test="@length > 40">40</xsl:when>
          <xsl:when test="@length"><xsl:value-of select="@length"/></xsl:when>
          <xsl:otherwise>12</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="ancestor::head">
        <xsl:attribute name="class">head</xsl:attribute>
      </xsl:if>
    </input>
  </xsl:template>

  <xsl:template name="field-textline">
    <!-- xsl:param name="form_id"/ -->
    <input type="text">
      <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:attribute name="value"><xsl:value-of select="default"/></xsl:attribute>
      <xsl:attribute name="size">
        <xsl:choose>
          <xsl:when test="@length > 40">40</xsl:when>
          <xsl:when test="@length"><xsl:value-of select="@length"/></xsl:when>
          <xsl:otherwise>12</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="ancestor::head">
        <xsl:attribute name="class">head</xsl:attribute>
      </xsl:if>
    </input>
  </xsl:template>

  <xsl:template name="field-textbox">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="size"/>
    <textarea wrap="">
      <xsl:choose>
        <xsl:when test="name(.) = 'editbox'">
          <xsl:attribute name="cols">80</xsl:attribute>
          <xsl:attribute name="rows">30</xsl:attribute>
        </xsl:when>
        <xsl:when test="$size=2">
          <xsl:attribute name="cols">40</xsl:attribute>
          <xsl:attribute name="rows">10</xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="cols">40</xsl:attribute>
          <xsl:attribute name="rows">10</xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
      <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
      <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
      <xsl:value-of select="default"/>
    </textarea>
  </xsl:template>

  <xsl:template name="field-textreader">
    <!-- xsl:param name="form_id"/ -->
    <textarea rows="20" cols="80" wrap="" readonly="">
      <xsl:value-of select="."/>
    </textarea>
  </xsl:template>
      
  <xsl:template name="field-selection">
    <!-- xsl:param name="form_id"/ -->
    <xsl:param name="form_level"/>
    <xsl:param name="style">
      <xsl:if test="option//form">
        <xsl:choose>
          <xsl:when test="@count = 'multiple'">checkbox</xsl:when>
          <xsl:otherwise>radio</xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:param>
    <xsl:choose>
      <xsl:when test="not($style) or $style = ''">
        <select>
          <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
          <xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute>
          <xsl:if test="@count = 'multiple'">
            <xsl:attribute name="multiple"><xsl:text>1</xsl:text></xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="option">
          </xsl:apply-templates>
        </select>
      </xsl:when>
      <xsl:otherwise>
        <!-- select -->
          <!-- xsl:attribute name="name"><xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/>.</xsl:if><xsl:value-of select="@id"/></xsl:attribute -->
          <!-- xsl:attribute name="name"><xsl:apply-templates select="." mode="id"/></xsl:attribute -->
          <!-- xsl:if test="@count = 'multiple'">
            <xsl:attribute name="multiple"/>
          </xsl:if -->
          <xsl:apply-templates select="option">
            <xsl:with-param name="style" select="$style"/>
            <xsl:with-param name="form_level" select="$form_level"/>
            <!-- xsl:with-param name="form_id">
              <xsl:if test="$form_id != ''"><xsl:value-of select="$form_id"/><xsl:text>.</xsl:text></xsl:if>
              <xsl:value-of select="@id"/>
            </xsl:with-param -->
          </xsl:apply-templates>
        <!-- /select -->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="field-grid">
    <!-- have <column/>s and <row/>s -->
    <xsl:variable name="inputtype">
      <xsl:choose>
        <xsl:when test="starts-with(@count, 'multiple-') or @count = 'multiple'">
          <xsl:text>checkbox</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>radio</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- naming determines which direction choices are constrained -->
    <xsl:variable name="nametype">
      <xsl:choose>
        <xsl:when test="substring-before(@count, '-by-row')">
          <xsl:text>row</xsl:text>
        </xsl:when>
        <xsl:when test="substring-before(@count, '-by-column')">
          <xsl:text>col</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>neither</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="grid-id">
      <xsl:apply-templates select="." mode="id"/>
    </xsl:variable>
    
    <table class="grid">
      <tr>
        <td/>
        <xsl:for-each select="column">
          <td class="grid-column-caption">
            <xsl:choose>
              <xsl:when test="caption">
                <xsl:apply-templates select="caption"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@id"/>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </xsl:for-each>
      </tr>
      <xsl:for-each select="row">
        <xsl:variable name="row-id" select="@id"/>
        <tr>
          <td class="grid-row-caption">
            <xsl:choose>
              <xsl:when test="caption">
                <xsl:apply-templates select="caption"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@id"/>
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <xsl:for-each select="../column">
            <td class="grid-cell"><input>
              <xsl:attribute name="type"><xsl:value-of select="$inputtype"/></xsl:attribute>
              <xsl:attribute name="name">
                <xsl:value-of select="$grid-id"/>
                <xsl:if test="$nametype = 'row'">
                  <xsl:text>.</xsl:text><xsl:value-of select="$row-id"/>
                </xsl:if>
                <xsl:if test="$nametype = 'col'">
                  <xsl:text>.</xsl:text><xsl:value-of select="@id"/>
                </xsl:if>
              </xsl:attribute>
              <xsl:attribute name="value">
                <xsl:choose>
                  <xsl:when test="$nametype = 'row'">
                    <xsl:value-of select="@id"/>
                  </xsl:when>
                  <xsl:when test="$nametype = 'col'">
                    <xsl:value-of select="$row-id"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$row-id"/><xsl:text>.</xsl:text><xsl:value-of select="@id"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:attribute>
              <!-- need to handle defaults now -->
              <xsl:if test="
                ../row[@id = $row-id]/default/text() = @id 
                or ./default/text() = $row-id 
                or ../default/text() = concat($row-id, '.', @id)
               ">
                <xsl:attribute name="checked"/>
              </xsl:if>
            </input></td>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

<!-- id generation templates -->

  <xsl:template match="container" mode="id">
    <xsl:value-of select="@id"/>
  </xsl:template>

  <!-- xsl:template match="form" mode="id">
    <xsl:choose>
      <xsl:when test="ancestor::form[@id]">
        <xsl:apply-templates select="ancestor::form[@id]"/>
        <xsl:if test="@id">
          <xsl:text>.</xsl:text><xsl:value-of select="@id"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="ancestor::container[@id]">
        <xsl:apply-templates select="ancestor::container[@id]"/>
        <xsl:if test="@id">
          <xsl:text>.</xsl:text><xsl:value-of select="@id"/>
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="@id">
          <xsl:value-of select="@id"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template -->

  <xsl:template match="submit|grid|stored|text|textline|textbox|editbox|file|password|selection|group|textreader|option" mode="id">
<!--
        ancestor::text
      | ancestor::textline
      | ancestor::textbox
      | ancestor::file
      | ancestor::password
      | ancestor::textreader
      | ancestor::submit
      | ancestor::stored
      | ancestor::grid
-->
    <xsl:for-each select="
        ancestor::option[@id != '']
      | ancestor::selection[@id != '']
      | ancestor::group[@id != '']
      | ancestor::form[@id != '']
      | ancestor::container[@id != '']
      " 
    >
      <xsl:value-of select="@id"/>
      <xsl:if test="position() != last()">
        <xsl:text>.</xsl:text>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="@id">
      <xsl:if test="
        ancestor::option[@id != '']
      | ancestor::selection[@id != '']
      | ancestor::group[@id != '']
      | ancestor::form[@id != '']
      | ancestor::container[@id != '']
      "
      >
        <xsl:text>.</xsl:text>
      </xsl:if>
      <xsl:value-of select="@id"/>
    </xsl:if>
    <xsl:if test="self::selection[@id != '']/option/form">
      <xsl:text>.value</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="format-url">
    <xsl:param name="url"/>

    <xsl:choose>
      <xsl:when test="/page/@redirect-url and contains($url, '://')">
        <xsl:value-of select="/page/@redirect-url"/>
        <xsl:text>?</xsl:text>
        <xsl:value-of select="$url"/>
      </xsl:when>
      <xsl:when test="/page/@redirect-url and /page/@session-id and starts-with($url, '/')">
        <xsl:text>/</xsl:text>
        <xsl:value-of select="/page/@session-id"/>
        <xsl:value-of select="$url"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$url"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- some useful entities -->

  <xsl:template match="nbsp">
    <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
