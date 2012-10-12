#!/bin/bash
#
## Configuration ##

dest_dir="/home/xwiki/XARs/"

excluded="Main.WebHome
Main.Welcome
XWiki.MessageStreamConfig
XWiki.RegistrationConfig
XWiki.WysiwygEditorConfig
XWiki.SearchSuggestConfig
AnnotationCode.AnnotationConfig
Invitation.InvitationConfig
XWiki.XWikiAllGroup
XWiki.XWikiAdminGroup
XWiki.Admin
XWiki.DefaultSkin
XWiki.XWikiSkins
Sandbox.WebHome
XWiki.XWikiPreferences
Panels.Quicklinks
Main.Search
Main.WebSearch
XWiki.XWikiSyntax
Blog.BlogIntroduction
XWiki.ForgotUsername
Blog.Other
Blog.Personal
XWiki.ResetPassword
XWiki.AdminSheet
Scheduler.WebPreferences
Blog.News
AppWithinMinutes.ClassEditSheet
Panels.DocumentInformation
XWiki.LuceneSearchAdmin
XWiki.WatchListMessage
Panels.Quicklinks
Panels.Welcome"

######################

exec 2> $0.err

### Version input
echo "What version of XE are you using?"
read xar_version

if [[ "`echo ${xar_version:0:1} | egrep [1-9]`" == "" ]]
then
	echo "This version is not a real version. (type for example: 4.1.4)"
	exit 1
fi
### Type input
echo "Choose a type between XE and XEM [default:XE]"
read package_type

if [[ $package_type != "XE" && $package_type != "XEM" && $package_type != "" ]]
then
	echo "This version of XWiki is not recognized (type XE or XEM)"
	exit 1
fi

### Downloading standard XAR
echo "Downloading XWiki $package_type for version $xar_version ..."
if [[ $package_type == "XE" && $package_type == "" ]]
then
	wget -O "$package_type-$xar_version.xar" http://maven.xwiki.org/releases/org/xwiki/enterprise/xwiki-enterprise-ui-all/$xar_version/xwiki-enterprise-ui-all-$xar_version.xar 1>/dev/null
else
	wget -O "$package_type-$xar_version.xar" http://maven.xwiki.org/releases/org/xwiki/manager/xwiki-manager-ui-all/$xar_version/xwiki-manager-ui-all-$xar_version.xar 1>/dev/null

	if [[ $? != '0' ]]
	then
		echo "Download have failed. Please check $0.err file for more details (Perhaps this version doesn't exist?)."
		exit 1
	fi
fi

### Unzip 

mkdir $package_type-$xar_version.tmp
cd $package_type-$xar_version.tmp
unzip ../$package_type-$xar_version.xar


